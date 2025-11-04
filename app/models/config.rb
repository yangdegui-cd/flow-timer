class Config < ApplicationRecord

  def facebook_auth_callback_url
    (api_use_ssl ? 'https' : 'http') + "://#{api_domain}/config/facebook_callback"
  end

  def google_auth_callback_url
    (api_use_ssl ? 'https' : 'http') + "://#{api_domain}/config/google_callback"
  end
end
