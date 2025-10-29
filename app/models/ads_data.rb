class AdsData < ApplicationRecord
  # 关联关系
  belongs_to :ads_account
  belongs_to :project

  # 验证
  validates :platform, presence: true, inclusion: { in: %w[facebook google twitter tiktok] }
  validates :date, presence: true

  # 作用域
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_campaign, ->(campaign_id) { where(campaign_id: campaign_id) }
  scope :by_adset, ->(adset_id) { where(adset_id: adset_id) }
  scope :by_ad, ->(ad_id) { where(ad_id: ad_id) }
  scope :active_data, -> { where(data_status: 'active') }
  scope :recent, -> { order(date: :desc) }

  # 时间维度作用域
  scope :by_year, ->(year) { where(year: year.to_s) }
  scope :by_month, ->(year, month) { where(year: year.to_s, month: sprintf('%04d-%02d', year, month)) }
  scope :by_quarter, ->(year, quarter) { where(year: year.to_s, quarter: "#{year}-Q#{quarter}") }
  scope :by_week, ->(year, week) { where(year: year.to_s, week: sprintf('%04d-%02d', year, week)) }

  # 层级作用域
  scope :campaign_level, -> { where.not(campaign_id: nil).where(adset_id: nil, ad_id: nil) }
  scope :adset_level, -> { where.not(adset_id: nil).where(ad_id: nil) }
  scope :ad_level, -> { where.not(ad_id: nil) }

  # 回调
  before_validation :set_time_dimensions
  before_save :calculate_derived_metrics

  # 实例方法
  def level
    return 'ad' if ad_id.present?
    return 'adset' if adset_id.present?
    return 'campaign' if campaign_id.present?
    'account'
  end

  def level_name
    case level
    when 'ad'
      ad_name || "广告 ##{ad_id}"
    when 'adset'
      adset_name || "广告组 ##{adset_id}"
    when 'campaign'
      campaign_name || "活动 ##{campaign_id}"
    else
      ads_account&.name || "账户"
    end
  end

  def level_id
    case level
    when 'ad'
      ad_id
    when 'adset'
      adset_id
    when 'campaign'
      campaign_id
    else
      ads_account_id
    end
  end

  def calculated_ctr
    return 0 if impressions.zero?
    (clicks.to_f / impressions * 100).round(6)
  end

  def calculated_cpm
    return 0 if impressions.zero?
    (spend / impressions * 1000).round(4)
  end

  def calculated_cpc
    return 0 if clicks.zero?
    (spend / clicks).round(4)
  end

  def calculated_conversion_rate
    return 0 if clicks.zero?
    (conversions.to_f / clicks * 100).round(6)
  end

  def calculated_cost_per_conversion
    return 0 if conversions.zero?
    (spend / conversions).round(4)
  end

  def calculated_roas
    return 0 if spend.zero?
    (conversion_value / spend).round(4)
  end

  def targeting_summary
    summary = []

    if age_min.present? || age_max.present?
      age_range = "#{age_min || 18}-#{age_max || 65}岁"
      summary << "年龄: #{age_range}"
    end

    if gender.present? && gender != 'ALL'
      gender_map = { 'M' => '男性', 'F' => '女性' }
      summary << "性别: #{gender_map[gender] || gender}"
    end

    if countries.present? && countries.any?
      summary << "国家: #{countries.join(', ')}"
    end

    summary.any? ? summary.join(' | ') : '无特定定向'
  end

  def placement_summary
    return '无版位信息' if placements.blank?
    placements.join(', ')
  end

  def performance_summary
    {
      level: level,
      level_name: level_name,
      date: date,
      platform: platform.humanize,
      impressions: impressions,
      clicks: clicks,
      spend: spend,
      ctr: calculated_ctr,
      cpm: calculated_cpm,
      cpc: calculated_cpc,
      conversions: conversions,
      conversion_value: conversion_value,
      roas: calculated_roas
    }
  end

  # 聚合方法
  def self.aggregate_by_date(start_date, end_date, group_by = 'date')
    date_range = start_date..end_date

    case group_by
    when 'date'
      by_date_range(start_date, end_date)
        .group(:date)
        .sum_metrics
    when 'week'
      by_date_range(start_date, end_date)
        .group(:week)
        .sum_metrics
    when 'month'
      by_date_range(start_date, end_date)
        .group(:month)
        .sum_metrics
    when 'quarter'
      by_date_range(start_date, end_date)
        .group(:quarter)
        .sum_metrics
    end
  end

  def self.aggregate_by_campaign(start_date, end_date)
    by_date_range(start_date, end_date)
      .group(:campaign_id, :campaign_name)
      .sum_metrics
  end

  def self.aggregate_by_platform(start_date, end_date)
    by_date_range(start_date, end_date)
      .group(:platform)
      .sum_metrics
  end

  def self.aggregate_by_country(start_date, end_date)
    by_date_range(start_date, end_date)
      .group(:country_code, :country_name)
      .sum_metrics
  end

  def self.sum_metrics
    {
      impressions: sum(:impressions),
      clicks: sum(:clicks),
      spend: sum(:spend),
      reach: sum(:reach),
      conversions: sum(:conversions),
      conversion_value: sum(:conversion_value),
      video_views: sum(:video_views),
      likes: sum(:likes),
      comments: sum(:comments),
      shares: sum(:shares),
      saves: sum(:saves)
    }
  end

  def self.calculate_averages(records)
    return {} if records.empty?

    total_impressions = records.sum(&:impressions)
    total_clicks = records.sum(&:clicks)
    total_spend = records.sum(&:spend)
    total_conversions = records.sum(&:conversions)
    total_conversion_value = records.sum(&:conversion_value)

    {
      avg_ctr: total_impressions.zero? ? 0 : (total_clicks.to_f / total_impressions * 100).round(6),
      avg_cpm: total_impressions.zero? ? 0 : (total_spend / total_impressions * 1000).round(4),
      avg_cpc: total_clicks.zero? ? 0 : (total_spend / total_clicks).round(4),
      avg_conversion_rate: total_clicks.zero? ? 0 : (total_conversions.to_f / total_clicks * 100).round(6),
      avg_cost_per_conversion: total_conversions.zero? ? 0 : (total_spend / total_conversions).round(4),
      avg_roas: total_spend.zero? ? 0 : (total_conversion_value / total_spend).round(4)
    }
  end

  # 平台特定方法
  def self.facebook_data
    by_platform('facebook')
  end

  def self.google_data
    by_platform('google')
  end

  def self.twitter_data
    by_platform('twitter')
  end

  def self.tiktok_data
    by_platform('tiktok')
  end

  private

  def set_time_dimensions
    return unless date.present?

    self.year = date.year.to_s
    self.month = date.strftime('%Y-%m')
    self.quarter = "#{date.year}-Q#{(date.month - 1) / 3 + 1}"
    self.week = date.strftime('%Y-%W')
    self.hour = hour if hour.present?
  end


  def calculate_derived_metrics
  end
end
