class FacebookTokenService
  def initialize
    @config = Config.first
  end

  # 生成 Facebook 登录授权 URL
  def self.get_authorization_url(redirect_uri)
    config = Config.first
    return nil unless config&.facebook_app_id.present?

    # 需要的权限范围:读取广告洞察和管理广告
    scopes = [
      'ads_read',           # 读取广告数据
      'ads_management',     # 管理广告
      'business_management' # 管理商务
    ].join(',')

    params = {
      client_id: config.facebook_app_id,
      redirect_uri: redirect_uri,
      scope: scopes,
      response_type: 'code',
      state: SecureRandom.hex(16) # CSRF 保护
    }

    "https://www.facebook.com/v18.0/dialog/oauth?#{params.to_query}"
  end

  # 验证 app_id 和 app_secret 是否有效(简单验证配置是否存在)
  def self.validate_app_credentials
    config = Config.first
    return { valid: false, message: '配置未找到' } unless config
    return { valid: false, message: 'Facebook App ID 未配置' } if config.facebook_app_id.blank?
    return { valid: false, message: 'Facebook App Secret 未配置' } if config.facebook_app_secret.blank?

    { valid: true, message: 'Facebook 应用凭证已配置' }
  end

  # 检查配置中的令牌是否过期
  def self.config_token_expired?
    config = Config.first
    return true if config.blank?
    return true if config.facebook_access_token.blank?
    return true if config.facebook_token_expired_at.blank?

    config.facebook_token_expired_at < Time.current
  end

  # 检查并维护配置中的令牌
  def self.maintain_config_token
    if config_token_expired?
      Rails.logger.warn "配置中的Facebook令牌已过期或不存在，需要重新授权"
      false
    else
      Rails.logger.info "配置中的Facebook令牌仍然有效"
      true
    end
  end

  # 验证配置中的令牌是否有效
  def self.validate_token
    config = Config.first
    return false unless config&.facebook_access_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/me', {
        query: {
          access_token: config.facebook_access_token
        }
      })

      response.success?
    rescue StandardError => e
      Rails.logger.error "Facebook令牌验证失败: #{e.message}"
      false
    end
  end

  # 使用授权码获取用户访问令牌(用于 OAuth 流程)
  def self.exchange_code_for_token(code, redirect_uri)
    config = Config.first
    return { success: false, message: 'Facebook 配置未找到' } unless config
    return { success: false, message: 'Facebook App ID 未配置' } if config.facebook_app_id.blank?
    return { success: false, message: 'Facebook App Secret 未配置' } if config.facebook_app_secret.blank?

    begin
      response = HTTParty.get('https://graph.facebook.com/v18.0/oauth/access_token', {
        query: {
          client_id: config.facebook_app_id,
          client_secret: config.facebook_app_secret,
          redirect_uri: redirect_uri,
          code: code
        }
      })

      if response.success?
        token_data = response.parsed_response
        {
          success: true,
          access_token: token_data['access_token'],
          expires_in: token_data['expires_in'],
          token_type: token_data['token_type']
        }
      else
        error_message = response.parsed_response['error']&.dig('message') || response.body
        Rails.logger.error "Facebook 授权码交换令牌失败: #{error_message}"
        { success: false, message: "授权失败: #{error_message}" }
      end
    rescue StandardError => e
      Rails.logger.error "Facebook 授权码交换令牌异常: #{e.message}"
      { success: false, message: "授权异常: #{e.message}" }
    end
  end

  # 将短期用户令牌交换为长期令牌
  def self.exchange_for_long_lived_token(short_lived_token)
    config = Config.first
    return nil unless config&.facebook_app_id.present? && config&.facebook_app_secret.present?
    return nil unless short_lived_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/oauth/access_token', {
        query: {
          grant_type: 'fb_exchange_token',
          client_id: config.facebook_app_id,
          client_secret: config.facebook_app_secret,
          fb_exchange_token: short_lived_token
        }
      })

      if response.success?
        token_data = response.parsed_response
        Rails.logger.info "Facebook长期令牌获取成功"
        {
          access_token: token_data['access_token'],
          expires_in: token_data['expires_in']
        }
      else
        Rails.logger.error "Facebook长期令牌获取失败: #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Facebook长期令牌交换异常: #{e.message}"
      nil
    end
  end

  # 获取令牌信息
  def self.token_info
    config = Config.first
    return nil unless config&.facebook_access_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/oauth/access_token_info', {
        query: {
          access_token: config.facebook_access_token
        }
      })

      if response.success?
        response.parsed_response
      else
        Rails.logger.error "获取令牌信息失败: #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "获取令牌信息异常: #{e.message}"
      nil
    end
  end

  # 获取当前有效的访问令牌(自动刷新)
  def self.get_valid_access_token
    maintain_config_token
    Config.first&.facebook_access_token
  end
end
