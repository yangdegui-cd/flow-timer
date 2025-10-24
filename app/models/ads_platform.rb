class AdsPlatform < ApplicationRecord
  # 关联关系
  has_many :ads_accounts, dependent: :destroy

  # 验证
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :auth_method, inclusion: { in: %w[oauth2 api_key jwt] }

  # 作用域
  scope :active, -> { where(active: true) }

  # JSON字段处理
  serialize :scopes, type: Array, coder: JSON

  # 常量定义
  SUPPORTED_PLATFORMS = {
    'facebook' => 'Facebook',
    'google' => 'Google Ads',
    'twitter' => 'Twitter Ads',
    'tiktok' => 'TikTok for Business'
  }.freeze

  # 实例方法
  def display_name
    name.presence || slug.humanize
  end

  def oauth_enabled?
    auth_method == 'oauth2' && oauth_url.present?
  end

  def to_s
    display_name
  end
end
