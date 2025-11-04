class GoogleTokenService
  OAUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
  TOKEN_URL = 'https://oauth2.googleapis.com/token'
  GOOGLE_ADS_API_URL = 'https://googleads.googleapis.com/v16/customers'

  def initialize
    @config = Config.first
  end

  # 生成 Google Ads OAuth 授权 URL
  def self.get_authorization_url(redirect_uri)
    config = Config.first
    return nil unless config&.google_ads_client_id.present?

    # Google Ads API 需要的权限范围
    scope = 'https://www.googleapis.com/auth/adwords'

    params = {
      client_id: config.google_ads_client_id,
      redirect_uri: redirect_uri,
      scope: scope,
      response_type: 'code',
      access_type: 'offline',  # 获取 refresh_token
      prompt: 'consent',       # 强制显示同意屏幕以获取 refresh_token
      state: SecureRandom.hex(16) # CSRF 保护
    }

    "#{OAUTH_URL}?#{params.to_query}"
  end

  # 验证 client_id, client_secret 和 developer_token 是否已配置
  def self.validate_app_credentials
    config = Config.first
    return { valid: false, message: '配置未找到' } unless config
    return { valid: false, message: 'Google Ads Client ID 未配置' } if config.google_ads_client_id.blank?
    return { valid: false, message: 'Google Ads Client Secret 未配置' } if config.google_ads_client_secret.blank?
    return { valid: false, message: 'Google Ads Developer Token 未配置' } if config.google_ads_developer_token.blank?

    { valid: true, message: 'Google Ads 应用凭证已配置' }
  end

  # 检查 refresh_token 是否存在
  def self.config_token_expired?
    config = Config.first
    return true if config.blank?
    return true if config.google_ads_refresh_token.blank?

    false
  end

  # 检查并维护配置中的 refresh_token
  def self.maintain_config_token
    if config_token_expired?
      Rails.logger.warn "配置中的 Google Ads Refresh Token 不存在，需要重新授权"
      false
    else
      Rails.logger.info "配置中的 Google Ads Refresh Token 存在"
      true
    end
  end

  # 使用 refresh_token 获取新的 access_token
  def self.get_access_token
    config = Config.first
    return nil unless config&.google_ads_refresh_token.present?
    return nil unless config&.google_ads_client_id.present?
    return nil unless config&.google_ads_client_secret.present?

    begin
      response = HTTParty.post(TOKEN_URL, {
        body: {
          client_id: config.google_ads_client_id,
          client_secret: config.google_ads_client_secret,
          refresh_token: config.google_ads_refresh_token,
          grant_type: 'refresh_token'
        }
      })

      if response.success?
        token_data = response.parsed_response
        Rails.logger.info "Google Ads Access Token 获取成功"
        token_data['access_token']
      else
        Rails.logger.error "Google Ads Access Token 获取失败: #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Google Ads Access Token 获取异常: #{e.message}"
      nil
    end
  end

  # 验证 refresh_token 是否有效（通过尝试获取 access_token）
  def self.validate_token
    access_token = get_access_token
    access_token.present?
  end

  # 使用授权码获取 refresh_token（用于 OAuth 流程）
  def self.exchange_code_for_token(code, redirect_uri)
    config = Config.first
    return { success: false, message: 'Google Ads 配置未找到' } unless config
    return { success: false, message: 'Google Ads Client ID 未配置' } if config.google_ads_client_id.blank?
    return { success: false, message: 'Google Ads Client Secret 未配置' } if config.google_ads_client_secret.blank?

    begin
      response = HTTParty.post(TOKEN_URL, {
        body: {
          client_id: config.google_ads_client_id,
          client_secret: config.google_ads_client_secret,
          redirect_uri: redirect_uri,
          code: code,
          grant_type: 'authorization_code'
        }
      })

      if response.success?
        token_data = response.parsed_response
        {
          success: true,
          refresh_token: token_data['refresh_token'],
          access_token: token_data['access_token'],
          expires_in: token_data['expires_in'],
          token_type: token_data['token_type']
        }
      else
        error_message = response.parsed_response['error_description'] || response.body
        Rails.logger.error "Google Ads 授权码交换令牌失败: #{error_message}"
        { success: false, message: "授权失败: #{error_message}" }
      end
    rescue StandardError => e
      Rails.logger.error "Google Ads 授权码交换令牌异常: #{e.message}"
      { success: false, message: "授权异常: #{e.message}" }
    end
  end

  # 测试 Google Ads API 连接（使用 developer_token 和 refresh_token）
  def self.test_api_connection
    config = Config.first
    return { success: false, message: 'Google Ads 配置未找到' } unless config
    return { success: false, message: 'Google Ads Developer Token 未配置' } if config.google_ads_developer_token.blank?
    return { success: false, message: 'Google Ads Refresh Token 未配置' } if config.google_ads_refresh_token.blank?
    return { success: false, message: 'Google Ads Customer ID 未配置' } if config.google_ads_customer_id.blank?

    access_token = get_access_token
    return { success: false, message: '无法获取 Access Token，请重新授权' } if access_token.blank?

    begin
      # 尝试获取客户信息来验证连接
      customer_id = config.google_ads_customer_id.gsub('-', '')
      url = "#{GOOGLE_ADS_API_URL}/#{customer_id}/googleAdsFields:search"

      response = HTTParty.post(url, {
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'developer-token' => config.google_ads_developer_token,
          'Content-Type' => 'application/json'
        },
        body: {
          query: 'SELECT customer.id, customer.descriptive_name FROM customer LIMIT 1'
        }.to_json
      })

      if response.success?
        { success: true, message: 'Google Ads API 连接成功' }
      else
        error_message = response.parsed_response['error']&.dig('message') || response.body
        Rails.logger.error "Google Ads API 测试失败: #{error_message}"
        { success: false, message: "API 测试失败: #{error_message}" }
      end
    rescue StandardError => e
      Rails.logger.error "Google Ads API 测试异常: #{e.message}"
      { success: false, message: "API 测试异常: #{e.message}" }
    end
  end

  # 获取当前有效的访问令牌
  def self.get_valid_access_token
    maintain_config_token
    get_access_token
  end
end
