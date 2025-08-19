Rails.application.config.middleware.use OmniAuth::Builder do
  # GitHub OAuth - 使用环境变量或credentials
  github_key = ENV['GITHUB_CLIENT_ID'] || Rails.application.credentials.dig(:github, :key)
  github_secret = ENV['GITHUB_CLIENT_SECRET'] || Rails.application.credentials.dig(:github, :secret)
  
  if github_key && github_secret
    provider :github,
             github_key,
             github_secret,
             scope: 'user:email'
  end

  # 微信OAuth - 使用环境变量或credentials
  wechat_app_id = ENV['WECHAT_APP_ID'] || Rails.application.credentials.dig(:wechat, :app_id)
  wechat_app_secret = ENV['WECHAT_APP_SECRET'] || Rails.application.credentials.dig(:wechat, :app_secret)
  
  if wechat_app_id && wechat_app_secret
    provider :wechat,
             wechat_app_id,
             wechat_app_secret,
             scope: 'snsapi_userinfo'
  end
end

# 配置OAuth失败处理
OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# 允许的请求方法
OmniAuth.config.allowed_request_methods = [:post, :get]

# CSRF保护
OmniAuth.config.request_validation_phase = OmniAuth::RailsCsrfProtection::TokenVerifier.new