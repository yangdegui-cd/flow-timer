class FacebookAuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:callback]
  skip_before_action :validate_permission!, only: [:callback]

  # 开始授权流程
  def authorize
    project_id = params[:project_id]
    return render json: error('项目ID不能为空'), status: :bad_request if project_id.blank?

    project = Project.find_by(id: project_id)
    return render json: error('项目不存在'), status: :not_found unless project

    # 构建Facebook授权URL
    facebook_platform = AdsPlatform.find_by(slug: 'facebook')
    return render json: error('Facebook平台未配置'), status: :not_found unless facebook_platform

    state = generate_state_token(project_id, current_user.id)

    auth_url = build_facebook_auth_url(facebook_platform, state)

    render json: ok({ auth_url: auth_url })
  end

  # 处理授权回调
  def callback
    code = params[:code]
    state = params[:state]
    error_code = params[:error]

    # 处理用户拒绝授权的情况
    if error_code == 'access_denied'
      return redirect_to frontend_url_with_error('用户取消了授权')
    end

    # 验证state参数
    unless verify_state_token(state)
      return redirect_to frontend_url_with_error('授权状态验证失败')
    end

    begin
      # 用授权码换取访问令牌
      token_response = exchange_code_for_token(code)

      # 获取用户信息和广告账户
      user_info = get_facebook_user_info(token_response['access_token'])
      ad_accounts = get_facebook_ad_accounts(token_response['access_token'])

      # 解析state获取项目和用户信息
      project_id, user_id = parse_state_token(state)
      project = Project.find(project_id)
      user = SysUser.find(user_id)

      # 创建或更新广告账户记录
      facebook_platform = AdsPlatform.find_by(slug: 'facebook')

      ad_accounts['data']&.each do |account|
        ads_account = AdsAccount.find_or_initialize_by(
          ads_platform: facebook_platform,
          account_id: account['id'],
          project: project
        )

        ads_account.assign_attributes(
          name: account['name'],
          sys_user: user,
          access_token: token_response['access_token'],
          token_expires_at: token_response['expires_in']&.seconds&.from_now,
          currency: account['currency'],
          timezone: account['timezone_name'],
          account_status: account['account_status'] == 1 ? 'active' : 'suspended'
        )

        ads_account.save!

        # 将短期令牌交换为长期令牌
        token_service = FacebookTokenService.new(ads_account)
        token_service.exchange_for_long_lived_token
      end

      # 成功后重定向到前端
      redirect_to frontend_url_with_success('Facebook账户授权成功')

    rescue StandardError => e
      Rails.logger.error "Facebook授权回调失败: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to frontend_url_with_error('授权处理失败，请重试')
    end
  end

  private

  def generate_state_token(project_id, user_id)
    data = { project_id: project_id, user_id: user_id, timestamp: Time.current.to_i }
    Base64.strict_encode64(data.to_json)
  end

  def verify_state_token(state)
    return false if state.blank?

    begin
      data = JSON.parse(Base64.strict_decode64(state))
      # 验证时间戳（10分钟内有效）
      timestamp = data['timestamp'].to_i
      Time.current.to_i - timestamp < 600
    rescue
      false
    end
  end

  def parse_state_token(state)
    data = JSON.parse(Base64.strict_decode64(state))
    [data['project_id'], data['user_id']]
  end

  def build_facebook_auth_url(platform, state)
    app_id = ENV['FACEBOOK_APP_ID']
    redirect_uri = callback_url
    scopes = platform.scopes.join(',')

    params = {
      client_id: app_id,
      redirect_uri: redirect_uri,
      state: state,
      scope: scopes,
      response_type: 'code'
    }

    "#{platform.oauth_url}?#{params.to_query}"
  end

  def exchange_code_for_token(code)
    app_id = ENV['FACEBOOK_APP_ID']
    app_secret = ENV['FACEBOOK_APP_SECRET']
    redirect_uri = callback_url

    response = HTTParty.post('https://graph.facebook.com/v18.0/oauth/access_token', {
      body: {
        client_id: app_id,
        client_secret: app_secret,
        redirect_uri: redirect_uri,
        code: code
      }
    })

    if response.success?
      response.parsed_response
    else
      raise "令牌交换失败: #{response.body}"
    end
  end

  def get_facebook_user_info(access_token)
    response = HTTParty.get('https://graph.facebook.com/me', {
      query: {
        access_token: access_token,
        fields: 'id,name,email'
      }
    })

    if response.success?
      response.parsed_response
    else
      raise "获取用户信息失败: #{response.body}"
    end
  end

  def get_facebook_ad_accounts(access_token)
    response = HTTParty.get('https://graph.facebook.com/me/adaccounts', {
      query: {
        access_token: access_token,
        fields: 'id,name,currency,timezone_name,account_status'
      }
    })

    if response.success?
      response.parsed_response
    else
      raise "获取广告账户失败: #{response.body}"
    end
  end

  def callback_url
    "#{request.base_url}/facebook_auth/callback"
  end

  def frontend_url_with_success(message)
    "#{ENV['FRONTEND_URL'] || 'http://localhost:5173'}/projects?auth_success=#{CGI.escape(message)}"
  end

  def frontend_url_with_error(message)
    "#{ENV['FRONTEND_URL'] || 'http://localhost:5173'}/projects?auth_error=#{CGI.escape(message)}"
  end
end
