class AdState < ApplicationRecord
  # 关联关系
  belongs_to :ads_account

  # 验证
  validates :platform, presence: true, inclusion: { in: %w[facebook google tiktok twitter] }
  validates :unique_key, presence: true, uniqueness: true
  validates :campaign_id, :adset_id, :ad_id, presence: true

  # 作用域
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_campaign, ->(campaign_id) { where(campaign_id: campaign_id) }
  scope :by_adset, ->(adset_id) { where(adset_id: adset_id) }
  scope :by_ad, ->(ad_id) { where(ad_id: ad_id) }
  scope :active, -> { where(is_active: true) }
  scope :recent_synced, -> { where.not(synced_at: nil).order(synced_at: :desc) }
  scope :need_sync, -> { where('synced_at IS NULL OR synced_at < ?', 1.hour.ago) }

  # 平台特定作用域
  scope :facebook, -> { by_platform('facebook') }
  scope :google, -> { by_platform('google') }
  scope :tiktok, -> { by_platform('tiktok') }

  # 回调
  before_validation :generate_unique_key
  before_save :update_active_status

  # 实例方法

  # 是否正在投放
  def active?
    is_active
  end

  # 获取预算类型
  def budget_type
    if daily_budget.present?
      'daily'
    elsif lifetime_budget.present?
      'lifetime'
    else
      'none'
    end
  end

  # 获取预算金额
  def budget_amount
    daily_budget || lifetime_budget || 0
  end

  # 获取层级
  def level
    'ad'  # 固定为 ad 级别
  end

  # 获取定向摘要
  def targeting_summary
    return '无定向信息' unless targeting.present?

    summary = []

    # 年龄
    if targeting['age_min'] || targeting['age_max']
      age_min = targeting['age_min'] || 18
      age_max = targeting['age_max'] || 65
      summary << "年龄: #{age_min}-#{age_max}岁"
    end

    # 性别
    if targeting['genders']
      genders = targeting['genders']
      gender_str = genders.map { |g| g == 1 ? '男' : '女' }.join('/')
      summary << "性别: #{gender_str}"
    end

    # 地域
    if targeting['geo_locations']
      geo = targeting['geo_locations']
      countries = geo['countries']&.join(', ')
      summary << "国家: #{countries}" if countries.present?
    end

    summary.any? ? summary.join(' | ') : '无定向信息'
  end

  # 获取素材类型
  def creative_type
    if video_id.present? || video_url.present?
      'video'
    elsif image_url.present?
      'image'
    else
      'unknown'
    end
  end

  # 获取素材URL
  def creative_url
    video_url || image_url || thumbnail_url
  end

  # 获取完整摘要
  def summary
    {
      platform: platform,
      campaign: "#{campaign_name} (#{campaign_id})",
      adset: "#{adset_name} (#{adset_id})",
      ad: "#{ad_name} (#{ad_id})",
      creative_type: creative_type,
      creative_url: creative_url,
      budget_type: budget_type,
      budget_amount: budget_amount,
      is_active: is_active,
      synced_at: synced_at
    }
  end

  # 类方法

  # 同步所有需要更新的广告
  def self.sync_all_needed(ads_account)
    AdsFetchAdStateService.for(ads_account).sync_all
  end

  # 按平台统计活跃广告数
  def self.active_count_by_platform
    active.group(:platform).count
  end

  # 按广告系列统计
  def self.count_by_campaign
    group(:platform, :campaign_id, :campaign_name).count
  end

  # 按广告组统计
  def self.count_by_adset
    group(:platform, :adset_id, :adset_name).count
  end

  # 获取有素材的广告
  def self.with_creative
    where.not(creative_id: nil)
  end

  # 获取视频广告
  def self.video_ads
    where.not(video_id: nil).or(where.not(video_url: nil))
  end

  # 获取图片广告
  def self.image_ads
    where.not(image_url: nil).where(video_id: nil)
  end

  private

  def generate_unique_key
    # 生成唯一键：platform + ads_account_id + campaign_id + adset_id + ad_id
    return if unique_key.present?

    key_parts = [
      platform,
      ads_account_id,
      campaign_id,
      adset_id,
      ad_id
    ].compact.join('|')

    self.unique_key = Digest::MD5.hexdigest(key_parts)
  end

  def update_active_status
    # 根据各层级状态判断是否正在投放
    # Facebook: ACTIVE 表示投放中
    self.is_active = case platform
                     when 'facebook'
                       campaign_effective_status == 'ACTIVE' &&
                       adset_effective_status == 'ACTIVE' &&
                       ad_effective_status == 'ACTIVE'
                     else
                       false
                     end
  end
end
