class AdsAccount < ApplicationRecord
  # 关联关系
  belongs_to :ads_platform
  belongs_to :project, optional: true
  belongs_to :sys_user
  has_many :ads_campaigns, dependent: :destroy
  has_many :ads_ad_sets, dependent: :destroy
  has_many :ads_ads, dependent: :destroy
  has_many :ads_insights, dependent: :destroy
  has_many :ads_data, class_name: 'AdsData', dependent: :destroy

  # 验证
  validates :name, presence: true, length: { maximum: 200 }
  validates :account_id, presence: true, uniqueness: { scope: :ads_platform_id }
  validates :account_status, inclusion: { in: %w[active suspended closed] }
  validates :sync_status, inclusion: { in: %w[success error pending] }
  validates :sync_frequency, presence: true, numericality: { greater_than: 0 }

  # JSON字段处理
  serialize :config, coder: JSON

  # 作用域
  scope :active, -> { where(active: true) }
  scope :by_platform, ->(platform) { joins(:ads_platform).where(ads_platforms: { slug: platform }) }
  scope :sync_ready, -> { where(active: true, account_status: 'active') }

  # 回调
  before_validation :set_defaults
  after_create :schedule_initial_sync

  # 实例方法
  def display_name
    "#{name} (#{ads_platform.name})"
  end

  def sync_overdue?
    return false unless active? && last_sync_at.present?
    last_sync_at < sync_frequency.minutes.ago
  end

  def platform_config(key = nil)
    return config if key.nil?
    config&.dig(key.to_s)
  end

  def set_platform_config(key, value)
    self.config ||= {}
    self.config[key.to_s] = value
    save!
  end

  def mask_token(token)
    return nil if token.blank?
    "#{token[0..3]}...#{token[-4..-1]}"
  end

  def masked_access_token
    mask_token(access_token)
  end

  def last_sync_status
    return '从未同步' if last_sync_at.blank?
    case sync_status
    when 'success'
      "成功 (#{last_sync_at.strftime('%Y-%m-%d %H:%M')})"
    when 'error'
      "失败 (#{last_error&.truncate(50)})"
    when 'pending'
      '同步中...'
    end
  end

  # 类方法
  def self.facebook_accounts
    by_platform('facebook')
  end

  def self.google_accounts
    by_platform('google')
  end

  def self.twitter_accounts
    by_platform('twitter')
  end

  def self.tiktok_accounts
    by_platform('tiktok')
  end

  # JSON序列化
  def as_json_with_associations
    as_json(
      include: {
        ads_platform: { only: [:id, :name, :slug, :api_version] },
        project: { only: [:id, :name] },
        sys_user: { only: [:id, :username, :email] }
      },
      except: [:access_token, :refresh_token, :app_secret],
      methods: [:display_name,  :sync_overdue?, :last_sync_status]
    )
  end

  private

  def set_defaults
    self.account_status ||= 'active'
    self.sync_status ||= 'pending'
    self.sync_frequency ||= 60
    self.active = true if active.nil?
  end

  def schedule_initial_sync
    # TODO: 这里可以添加异步作业来进行首次数据同步
    # AdsAccountSyncJob.perform_later(self.id)
  end
end
