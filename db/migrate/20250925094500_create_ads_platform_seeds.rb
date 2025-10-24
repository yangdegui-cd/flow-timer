class CreateAdsPlatformSeeds < ActiveRecord::Migration[7.1]
  def up
    # 创建Facebook广告平台
    AdsPlatform.find_or_create_by(slug: 'facebook') do |platform|
      platform.name = 'Facebook'
      platform.api_version = 'v18.0'
      platform.base_url = 'https://graph.facebook.com'
      platform.oauth_url = 'https://www.facebook.com/v18.0/dialog/oauth'
      platform.scopes = ['ads_management', 'ads_read', 'business_management', 'read_insights']
      platform.auth_method = 'oauth2'
      platform.description = 'Facebook Marketing API - 管理Facebook和Instagram广告'
      platform.active = true
    end

    # 创建Google Ads平台
    AdsPlatform.find_or_create_by(slug: 'google') do |platform|
      platform.name = 'Google Ads'
      platform.api_version = 'v14'
      platform.base_url = 'https://googleads.googleapis.com'
      platform.oauth_url = 'https://accounts.google.com/oauth2/v2/auth'
      platform.scopes = ['https://www.googleapis.com/auth/adwords']
      platform.auth_method = 'oauth2'
      platform.description = 'Google Ads API - 管理Google搜索和展示广告'
      platform.active = true
    end

    # 创建Twitter广告平台
    AdsPlatform.find_or_create_by(slug: 'twitter') do |platform|
      platform.name = 'Twitter Ads'
      platform.api_version = '12'
      platform.base_url = 'https://ads-api.twitter.com'
      platform.oauth_url = 'https://api.twitter.com/oauth2/authorize'
      platform.scopes = ['TWEET_READ', 'TWEET_WRITE', 'USERS_READ', 'OFFLINE_ACCESS']
      platform.auth_method = 'oauth2'
      platform.description = 'Twitter Ads API - 管理Twitter推广和广告'
      platform.active = true
    end

    # 创建TikTok广告平台
    AdsPlatform.find_or_create_by(slug: 'tiktok') do |platform|
      platform.name = 'TikTok for Business'
      platform.api_version = 'v1.3'
      platform.base_url = 'https://business-api.tiktok.com'
      platform.oauth_url = 'https://ads.tiktok.com/marketing_api/auth'
      platform.scopes = ['user_info', 'video_list', 'campaign_management', 'reporting']
      platform.auth_method = 'oauth2'
      platform.description = 'TikTok for Business API - 管理TikTok广告和推广'
      platform.active = true
    end
  end

  def down
    AdsPlatform.where(slug: ['facebook', 'google', 'twitter', 'tiktok']).destroy_all
  end
end
