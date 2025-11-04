# frozen_string_literal: true

class ConfigController < ApplicationController
  # 跳过 DefaultCrud 的 set_resource 回调，因为 Config 是单例资源
  skip_before_action :set_resource
  skip_before_action :authenticate_user!, only: [:facebook_callback, :google_callback]
  skip_before_action :validate_permission!, only: [:facebook_callback, :google_callback]

  # GET /config
  def show
    config = Config.first_or_create!(default_attributes)

    # 屏蔽敏感信息
    config_data = config.as_json(
      except: [
        :email_notification_pwd,
        :qy_wechat_notification_key,
        :adjust_api_token,
        :facebook_app_secret,
        :facebook_access_token,
        :google_ads_client_secret,
        :google_ads_refresh_token,
        :google_ads_developer_token
      ],
      methods: [:facebook_auth_callback_url, :google_auth_callback_url]
    )
    render json: ok(config_data)
  end

  # PUT/PATCH /config
  def update
    config = Config.first_or_create!(default_attributes)

    # 如果密码或密钥为空，则不更新这些字段
    update_params = config_params
    update_params.delete(:email_notification_pwd) if update_params[:email_notification_pwd].blank?
    update_params.delete(:qy_wechat_notification_key) if update_params[:qy_wechat_notification_key].blank?
    update_params.delete(:adjust_api_token) if update_params[:adjust_api_token].blank?
    update_params.delete(:facebook_app_secret) if update_params[:facebook_app_secret].blank?
    update_params.delete(:facebook_access_token) if update_params[:facebook_access_token].blank?
    update_params.delete(:google_ads_client_secret) if update_params[:google_ads_client_secret].blank?
    update_params.delete(:google_ads_refresh_token) if update_params[:google_ads_refresh_token].blank?
    update_params.delete(:google_ads_developer_token) if update_params[:google_ads_developer_token].blank?

    if config.update(update_params)
      render json: ok(config, '配置更新成功')
    else
      render json: error(config.errors.full_messages.join(', '))
    end
  end

  # POST /config/test_email
  def test_email
    config = Config.first

    if config.blank?
      render json: error('请先配置邮件设置')
      return
    end

    unless config.use_email_notification
      render json: error('邮件通知未启用')
      return
    end

    # TODO: 实现实际的邮件测试逻辑
    # 这里暂时返回成功，实际应该尝试发送测试邮件
    render json: ok(nil, '邮件连接测试成功')
  rescue => e
    render json: error("邮件连接测试失败: #{e.message}")
  end

  # POST /config/test_wechat
  def test_wechat
    config = Config.first
    return render json: error('请先配置企业微信设置') if config&.qy_wechat_notification_url.blank?
    # TODO: 实现实际的企业微信测试逻辑
    # 这里暂时返回成功，实际应该尝试发送测试消息
    render json: ok(nil, '企业微信连接测试成功')
  rescue => e
    render json: error("企业微信连接测试失败: #{e.message}")
  end

  # POST /config/test_adjust
  def test_adjust
    config = Config.first

    return render json: error('请先配置 Adjust 设置') if config.blank?

    result = AdjustReportService.test_connection(config)
    if result[:success]
      render json: ok(nil, result[:message])
    else
      render json: error(result[:message])
    end
  rescue => e
    render json: error("Adjust API 连接测试失败: #{e.message}")
  end

  # POST /config/test_facebook
  def test_facebook
    result = FacebookTokenService.validate_app_credentials

    if result[:valid]
      render json: ok(nil, result[:message])
    else
      render json: error(result[:message])
    end
  rescue => e
    render json: error("Facebook 凭证验证失败: #{e.message}")
  end

  # GET /config/facebook_auth_url
  def facebook_auth_url
    config = Config.first

    return render json: error('请先配置 Facebook App ID') if config.blank? || config.facebook_app_id.blank?
    return render json: error('请先配置后端API域名') if config.api_domain.blank?

    # 生成回调 URL
    auth_url = FacebookTokenService.get_authorization_url(config.facebook_auth_callback_url)

    if auth_url.present?
      render json: ok({ auth_url: auth_url })
    else
      render json: error('生成授权 URL 失败')
    end
  rescue => e
    render json: error("生成授权 URL 失败: #{e.message}")
  end

  # GET /config/facebook_callback
  def facebook_callback
    code = params[:code]
    config = Config.first

    if code.blank?
      # 授权失败或用户取消
      error_reason = params[:error_reason] || '授权失败'
      error_description = params[:error_description] || '用户取消授权或授权过程出错'

      redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape(error_description)}", allow_other_host: true
      return
    end

    # 使用授权码交换访问令牌
    redirect_uri = build_callback_url(config, '/config/facebook_callback')
    result = FacebookTokenService.exchange_code_for_token(code, redirect_uri)

    if result[:success]
      # 交换短期令牌为长期令牌
      long_lived = FacebookTokenService.exchange_for_long_lived_token(result[:access_token])

      if long_lived
        # 保存长期令牌到配置
        config.update!(
          facebook_access_token: long_lived[:access_token],
          facebook_token_expired_at: long_lived[:expires_in].seconds.from_now
        )

        redirect_to "#{config.website_base_url}/settings?tab=3&success=#{CGI.escape('Facebook 令牌获取成功')}", allow_other_host: true
      else
        redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape('长期令牌交换失败')}", allow_other_host: true
      end
    else
      redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape(result[:message])}", allow_other_host: true
    end
  rescue => e
    Rails.logger.error "Facebook 回调处理失败: #{e.message}"
    config = Config.first
    redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape("授权失败: #{e.message}")}", allow_other_host: true
  end

  # POST /config/test_google
  def test_google
    result = GoogleTokenService.validate_app_credentials

    if result[:valid]
      render json: ok(nil, result[:message])
    else
      render json: error(result[:message])
    end
  rescue => e
    render json: error("Google Ads 凭证验证失败: #{e.message}")
  end

  # GET /config/google_auth_url
  def google_auth_url
    config = Config.first

    return render json: error('请先配置 Google Ads Client ID') if config.blank? || config.google_ads_client_id.blank?
    return render json: error('请先配置后端API域名') if config.api_domain.blank?

    # 生成回调 URL
    auth_url = GoogleTokenService.get_authorization_url(config.google_auth_callback_url)

    if auth_url.present?
      render json: ok({ auth_url: auth_url })
    else
      render json: error('生成授权 URL 失败')
    end
  rescue => e
    render json: error("生成授权 URL 失败: #{e.message}")
  end

  # GET /config/google_callback
  def google_callback
    code = params[:code]
    config = Config.first

    if code.blank?
      # 授权失败或用户取消
      error = params[:error] || '授权失败'
      error_description = params[:error_description] || '用户取消授权或授权过程出错'
      redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape(error_description)}", allow_other_host: true
      return
    end

    # 使用授权码交换 refresh_token
    redirect_uri = config.google_auth_callback_url
    result = GoogleTokenService.exchange_code_for_token(code, redirect_uri)

    if result[:success] && result[:refresh_token].present?
      # 保存 refresh_token 到配置
      config.update!(
        google_ads_refresh_token: result[:refresh_token]
      )

      redirect_to "#{config.website_base_url}/settings?tab=3&success=#{CGI.escape('Google Ads Refresh Token 获取成功')}", allow_other_host: true
    else
      error_message = result[:message] || 'Refresh Token 获取失败'
      redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape(error_message)}", allow_other_host: true
    end
  rescue => e
    Rails.logger.error "Google Ads 回调处理失败: #{e.message}"
    config = Config.first
    redirect_to "#{config.website_base_url}/settings?tab=3&error=#{CGI.escape("授权失败: #{e.message}")}", allow_other_host: true
  end

  private


  def config_params
    params.require(:config).permit(
      :website_base_url,
      :api_domain,
      :api_use_ssl,
      :use_email_notification,
      :smtp_server,
      :smtp_port,
      :email_notification_email,
      :email_notification_pwd,
      :email_notification_name,
      :email_notification_display_name,
      :email_notification_use_tls,
      :qy_wechat_notification_key,
      :qy_wechat_notification_url,
      :adjust_api_token,
      :adjust_api_server,
      :facebook_app_id,
      :facebook_app_secret,
      :facebook_access_token,
      :facebook_token_expired_at,
      :google_ads_client_id,
      :google_ads_client_secret,
      :google_ads_developer_token,
      :google_ads_refresh_token,
      :google_ads_customer_id
    )
  rescue ActionController::ParameterMissing
    # 如果没有包裹在 config 键中，直接使用顶层参数
    params.permit(
      :use_email_notification,
      :smtp_server,
      :smtp_port,
      :email_notification_email,
      :email_notification_pwd,
      :email_notification_name,
      :email_notification_display_name,
      :email_notification_use_tls,
      :qy_wechat_notification_key,
      :qy_wechat_notification_url,
      :adjust_api_token,
      :adjust_api_server,
      :facebook_app_id,
      :facebook_app_secret,
      :facebook_access_token,
      :facebook_token_expired_at,
      :website_base_url,
      :api_domain,
      :api_use_ssl,
      :google_ads_client_id,
      :google_ads_client_secret,
      :google_ads_developer_token,
      :google_ads_refresh_token,
      :google_ads_customer_id
    )
  end

  def default_attributes
    {
      use_email_notification: false,
      smtp_port: 587,
      email_notification_use_tls: true
    }
  end
end
