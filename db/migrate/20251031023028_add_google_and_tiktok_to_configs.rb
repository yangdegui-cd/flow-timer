class AddGoogleAndTiktokToConfigs < ActiveRecord::Migration[7.1]
  def change
    add_column :configs, :google_ads_developer_token, :text, comment: 'Google Ads 开发者令牌'
    add_column :configs, :google_ads_client_id, :string, comment: 'Google Ads OAuth 客户端ID'
    add_column :configs, :google_ads_client_secret, :string, comment: 'Google Ads OAuth 客户端密钥'
    add_column :configs, :google_ads_refresh_token, :text, comment: 'Google Ads 刷新令牌'
    add_column :configs, :google_ads_customer_id, :string, comment: 'Google Ads 客户账户ID'

    add_column :configs, :tiktok_app_id, :string, comment: 'TikTok 应用ID'
    add_column :configs, :tiktok_app_secret, :string, comment: 'TikTok 应用密钥'
    add_column :configs, :tiktok_access_token, :text, comment: 'TikTok 访问令牌'
    add_column :configs, :tiktok_token_expired_at, :datetime, comment: 'TikTok 令牌过期时间'
  end
end
