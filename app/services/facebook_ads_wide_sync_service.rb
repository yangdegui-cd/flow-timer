class FacebookAdsWideSyncService
  attr_reader :ads_account, :access_token, :errors

  def initialize(ads_account)
    @ads_account = ads_account
    @access_token = ads_account.access_token
    @errors = []
  end

  # 主同步方法 - 同步到宽表
  def sync_to_wide_table(options = {})
    return false unless validate_account

    begin
      Rails.logger.info "开始同步Facebook广告数据到宽表: #{@ads_account.account_id}"

      # 获取同步日期范围
      date_range = options[:date_range] || default_date_range
      level = options[:level] || 'ad' # campaign, adset, ad

      # 先清理该账户的历史数据
      if options[:clear_existing] != false
        clear_existing_data(date_range)
      end

      # 同步洞察数据到宽表
      sync_insights_to_wide_table(date_range, level, options)

      @ads_account.update!(
        sync_status: 'success',
        last_sync_at: Time.current,
        last_error: nil
      )

      Rails.logger.info "Facebook广告数据同步到宽表完成: #{@ads_account.account_id}"
      true

    rescue StandardError => e
      handle_sync_error(e)
      false
    end
  end

  # 同步洞察数据到宽表
  def sync_insights_to_wide_table(date_range, level = 'ad', options = {})
    case level
    when 'campaign'
      sync_campaign_insights_to_wide_table(date_range, options)
    when 'adset'
      sync_adset_insights_to_wide_table(date_range, options)
    when 'ad'
      sync_ad_insights_to_wide_table(date_range, options)
    end
  end

  private

  def clear_existing_data(date_range)
    start_date = Date.parse(date_range[:since])
    end_date = Date.parse(date_range[:until])

    deleted_count = AdsData.where(ads_account: @ads_account)
                          .where(date: start_date..end_date)
                          .delete_all

    Rails.logger.info "清理了 #{deleted_count} 条历史数据"
  end

  def validate_account
    unless @ads_account.ads_platform.slug == 'facebook'
      @errors << '不是Facebook广告账户'
      return false
    end

    unless @access_token.present?
      @errors << '缺少访问令牌'
      return false
    end

    # 验证令牌是否有效
    token_service = FacebookTokenService.new(@ads_account)
    unless token_service.validate_token
      @errors << '访问令牌无效或已过期'
      return false
    end

    true
  end

  def sync_campaign_insights_to_wide_table(date_range, options = {})
    # 获取活动列表
    campaigns = fetch_facebook_campaigns
    return unless campaigns&.any?

    campaigns.each do |campaign|
      sync_campaign_insights_data(campaign, date_range, options)
    end
  end

  def sync_adset_insights_to_wide_table(date_range, options = {})
    # 获取广告组列表
    adsets = fetch_facebook_adsets
    return unless adsets&.any?

    adsets.each do |adset|
      sync_adset_insights_data(adset, date_range, options)
    end
  end

  def sync_ad_insights_to_wide_table(date_range, options = {})
    # 获取广告列表
    ads = fetch_facebook_ads
    return unless ads&.any?

    ads.each do |ad|
      sync_ad_insights_data(ad, date_range, options)
    end
  end

  def sync_campaign_insights_data(campaign, date_range, options = {})
    fields = campaign_insights_fields
    breakdowns = options[:breakdowns] || []

    params = {
      time_range: date_range,
      time_increment: '1',
      level: 'campaign'
    }

    # 只在有breakdown时才添加
    if breakdowns.any?
      params[:breakdowns] = breakdowns.join(',')
    end

    params = params.reject { |_, v| v.blank? }

    insights_data = fetch_facebook_data("#{campaign['id']}/insights", fields, params)
    return unless insights_data&.dig('data')

    insights_data['data'].each do |insight|
      create_wide_table_record(insight, campaign, nil, nil, 'campaign', breakdowns)
    end

    Rails.logger.info "同步活动 #{campaign['name']} 的洞察数据: #{insights_data['data'].size} 条记录"
  end

  def sync_adset_insights_data(adset, date_range, options = {})
    # 获取对应的活动信息
    campaign = fetch_campaign_info(adset['campaign']['id'])
    return unless campaign

    fields = adset_insights_fields
    breakdowns = options[:breakdowns] || []

    params = {
      time_range: date_range,
      time_increment: 'all_days',
      level: 'adset'
    }

    # 只在有breakdown时才添加
    if breakdowns.any?
      params[:breakdowns] = breakdowns.join(',')
    end

    params = params.reject { |_, v| v.blank? }

    insights_data = fetch_facebook_data("#{adset['id']}/insights", fields, params)
    return unless insights_data&.dig('data')

    insights_data['data'].each do |insight|
      create_wide_table_record(insight, campaign, adset, nil, 'adset', breakdowns)
    end

    Rails.logger.info "同步广告组 #{adset['name']} 的洞察数据: #{insights_data['data'].size} 条记录"
  end

  def sync_ad_insights_data(ad, date_range, options = {})
    # 获取对应的广告组和活动信息
    adset = fetch_adset_info(ad['adset']['id'])
    return unless adset

    campaign = fetch_campaign_info(adset['campaign']['id'])
    return unless campaign

    fields = ad_insights_fields
    # 使用基础breakdown配置
    breakdowns = options[:breakdowns] || enhanced_breakdowns

    # 支持小时级别数据拉取
    time_increment = options[:time_increment] || '1'

    # 如果需要小时级别数据，添加到breakdowns中
    if options[:hourly] == true
      breakdowns = breakdowns.dup
      breakdowns << 'hourly_stats_aggregated_by_advertiser_time_zone'
    end

    params = {
      time_range: date_range,
      time_increment: time_increment,
      level: 'ad'
    }

    # 只在有breakdown时才添加
    if breakdowns.any?
      params[:breakdowns] = breakdowns.join(',')
    end

    params = params.reject { |_, v| v.blank? }

    insights_data = fetch_facebook_data("#{ad['id']}/insights", fields, params)
    return unless insights_data&.dig('data')

    insights_data['data'].each do |insight|
      create_wide_table_record(insight, campaign, adset, ad, 'ad', breakdowns, time_increment == '1')
    end

    Rails.logger.info "同步广告 #{ad['name']} 的洞察数据: #{insights_data['data'].size} 条记录"
  end

  def create_wide_table_record(insight, campaign, adset, ad, level, breakdowns, is_hourly = false)
    # 解析日期和时间
    date_start = insight['date_start']
    date = date_start.to_date
    day_of_week = I18n.l(date, format: '%A')
    # 小时级别数据
    if is_hourly && insight['hourly_stats_aggregated_by_advertiser_time_zone']
      # Facebook返回格式如 "12:00:00 - 12:59:59"，提取小时部分
      hour_str = insight['hourly_stats_aggregated_by_advertiser_time_zone']
      hour_of_day = hour_str[0..1].to_i
    else
      hour_of_day = nil
    end

    # 构建唯一键的组成部分 - 包含小时信息
    unique_parts = [
      'facebook',
      @ads_account.id,
      date.to_s,
      hour_of_day.to_s,
      campaign['id'],
      adset&.dig('id'),
      ad&.dig('id'),
      insight['publisher_platform'],
      insight['platform_position'],
      insight['device_platform'],
      extract_breakdown_values(insight, breakdowns.reject { |b| b == 'hourly_stats_aggregated_by_advertiser_time_zone' }).join('|')
    ].compact
    puts unique_parts.join('|')
    unique_key = Digest::MD5.hexdigest(unique_parts.join('|'))

    # 查找或创建记录
    ads_data = AdsData.find_or_initialize_by(unique_key: unique_key)

    # 基础信息
    ads_data.assign_attributes(
      ads_account: @ads_account,
      project: @ads_account.project,
      platform: 'facebook',
      date: date,
      datetime: date.beginning_of_day + (hour_of_day || 0).hours,
      hour: hour_of_day.to_s,
      day_of_week: day_of_week,

      # 活动信息
      campaign_id: campaign['id'],
      campaign_name: campaign['name'],
      campaign_status: campaign['status'],
      campaign_objective: campaign['objective'],
      buying_type: campaign['buying_type'],
      campaign_daily_budget: parse_currency(campaign['daily_budget']),
      campaign_lifetime_budget: parse_currency(campaign['lifetime_budget']),
      campaign_start_time: parse_datetime(campaign['start_time']),
      campaign_end_time: parse_datetime(campaign['stop_time']),

      # 广告组信息
      adset_id: adset&.dig('id'),
      adset_name: adset&.dig('name'),
      adset_status: adset&.dig('status'),
      optimization_goal: adset&.dig('optimization_goal'),
      billing_event: adset&.dig('billing_event'),
      adset_daily_budget: parse_currency(adset&.dig('daily_budget')),
      bid_amount: parse_currency(adset&.dig('bid_amount')),
      adset_start_time: parse_datetime(adset&.dig('start_time')),
      adset_end_time: parse_datetime(adset&.dig('end_time')),

      # 广告信息
      ad_id: ad&.dig('id'),
      ad_name: ad&.dig('name'),
      ad_status: ad&.dig('status'),
      ad_format: extract_ad_format(ad),
      ad_creative_data: extract_creative_data(ad),

      # 定向信息
      targeting_data: adset&.dig('targeting'),
      **extract_targeting_details(adset&.dig('targeting')),

      # 版位信息
      publisher_platform: insight['publisher_platform'],
      device_platform: insight['device_platform'],
      placement_type: insight['platform_position'],

      # 设备维度详细信息 (从breakdown中提取)
      impression_device: insight['device_platform'],
      device_model: extract_device_model(insight),
      operating_system: extract_operating_system(insight),
      browser_name: extract_browser_name(insight),
      carrier: extract_carrier_info(insight),

      # 地理维度详细信息 (从breakdown中提取)
      dma_code: insight['dma'],
      postal_code: extract_postal_code(insight),

      # 行为和用户维度 (从breakdown中提取)
      user_bucket: extract_user_bucket(insight),
      click_device: insight['device_platform'],
      age_range: extract_age_range(insight),
      gender: extract_gender(insight),
      country_code: insight['country'],
      region_code: insight['region'],

      # 内容和创意维度
      call_to_action: extract_call_to_action(ad),
      link_click_destination: extract_link_destination(insight),
      creative_type: extract_creative_type(ad),

      # 核心指标
      impressions: insight['impressions']&.to_i || 0,
      clicks: insight['clicks']&.to_i || 0,
      spend: insight['spend']&.to_f || 0,
      reach: insight['reach']&.to_i || 0,
      frequency: insight['frequency']&.to_f || 0,

      # 转化相关
      conversions: extract_action_count(insight, 'offsite_conversion'),
      purchases: extract_action_count(insight, 'purchase'),
      conversion_value: extract_action_value(insight, 'offsite_conversion'),
      purchase_value: extract_action_value(insight, 'purchase'),

      # 更多转化类型
      purchase_conversions: extract_action_count(insight, 'purchase'),
      add_to_cart_conversions: extract_action_count(insight, 'add_to_cart'),
      lead_conversions: extract_action_count(insight, 'lead'),
      app_install_conversions: extract_action_count(insight, 'mobile_app_install'),

      # 视频相关
      video_views: extract_action_count(insight, 'video_view'),
      video_views_3s: extract_video_metric(insight, '3_second_video_views'),
      video_views_10s: extract_video_metric(insight, '10_second_video_views'),
      video_views_25_percent: extract_video_metric(insight, 'video_25_percent_complete_views'),
      video_views_50_percent: extract_video_metric(insight, 'video_50_percent_complete_views'),
      video_views_75_percent: extract_video_metric(insight, 'video_75_percent_complete_views'),
      video_views_100_percent: extract_video_metric(insight, 'video_100_percent_complete_views'),

      # 互动指标
      likes: extract_action_count(insight, 'like'),
      comments: extract_action_count(insight, 'comment'),
      shares: extract_action_count(insight, 'share'),
      saves: extract_action_count(insight, 'save'),
      link_clicks: extract_action_count(insight, 'link_click'),
      post_engagements: extract_action_count(insight, 'post_engagement'),

      # 额外互动指标
      page_likes: extract_action_count(insight, 'page_like'),
      post_shares: extract_action_count(insight, 'post_share'),
      video_play_actions: extract_action_count(insight, 'video_play'),

      # 应用相关
      app_installs: extract_action_count(insight, 'mobile_app_install'),
      registrations: extract_action_count(insight, 'complete_registration'),
      add_to_carts: extract_action_count(insight, 'add_to_cart'),

      # 移除不存在的字段，保持简单

      # 平台特有指标
      platform_metrics: extract_platform_metrics(insight),

      # 原始数据
      raw_data: insight,

      # 数据状态
      data_status: 'active',
      data_source: 'api',
      data_fetched_at: Time.current
    )

    ads_data.save!
    ads_data
  end

  # 获取数据的辅助方法
  def fetch_facebook_campaigns
    fields = %w[id name status objective buying_type daily_budget lifetime_budget start_time stop_time]
    data = fetch_facebook_data("act_#{@ads_account.account_id}/campaigns", fields)
    data&.dig('data')
  end

  def fetch_facebook_adsets
    fields = %w[id name campaign status optimization_goal billing_event daily_budget bid_amount start_time end_time targeting]
    data = fetch_facebook_data("act_#{@ads_account.account_id}/adsets", fields)
    data&.dig('data')
  end

  def fetch_facebook_ads
    fields = %w[id name adset status configured_status effective_status creative]
    data = fetch_facebook_data("act_#{@ads_account.account_id}/ads", fields)
    data&.dig('data')
  end

  def fetch_campaign_info(campaign_id)
    fields = %w[id name status objective buying_type daily_budget lifetime_budget start_time stop_time]
    fetch_facebook_data(campaign_id, fields)
  end

  def fetch_adset_info(adset_id)
    fields = %w[id name campaign status optimization_goal billing_event daily_budget bid_amount start_time end_time targeting]
    fetch_facebook_data(adset_id, fields)
  end

  def fetch_facebook_data(endpoint, fields, params = {})
    url = "https://graph.facebook.com/v18.0/#{endpoint}"
    query_params = {
      access_token: @access_token,
      fields: fields.join(',')
    }.merge(params)

    response = HTTParty.get(url, query: query_params)

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Facebook API请求失败: #{response.body}"
      raise "Facebook API请求失败: #{response.body}"
    end
  end

  # 字段定义
  def campaign_insights_fields
    %w[
      date_start date_stop impressions clicks spend reach frequency
      cpm cpc ctr actions
    ]
  end

  def adset_insights_fields
    campaign_insights_fields + %w[cost_per_conversion cost_per_action_type]
  end

  def ad_insights_fields
    %w[
      date_start date_stop impressions clicks spend reach frequency
      cpm cpc ctr actions
    ]
  end

  # 增强的breakdown参数支持 - 逐步添加有效的breakdown
  def enhanced_breakdowns
    %w[]
  end

  # 基础breakdown配置（稳定可用）
  def basic_breakdowns
    %w[]
  end

  # 地理breakdown配置
  def geo_breakdowns
    %w[]
  end

  # 设备breakdown配置
  def device_breakdowns
    %w[]
  end

  # 数据解析辅助方法
  def parse_currency(value)
    return nil if value.blank?
    (value.to_f / 100).round(2)
  end

  def parse_datetime(value)
    return nil if value.blank?
    Time.parse(value)
  rescue StandardError
    nil
  end

  def extract_ad_format(ad)
    return nil unless ad&.dig('creative')
    ad['creative']['object_story_spec']&.keys&.first || 'unknown'
  end

  def extract_creative_data(ad)
    return {} unless ad&.dig('creative')

    creative = ad['creative']
    {
      creative_id: creative['id'],
      creative_name: creative['name'],
      title: creative['title'],
      body: creative['body'],
      call_to_action: creative['call_to_action'],
      image_url: creative['image_url'],
      video_id: creative['video_id']
    }
  end

  def extract_targeting_details(targeting)
    return {} unless targeting.is_a?(Hash)

    {
      age_min: targeting['age_min']&.to_s,
      age_max: targeting['age_max']&.to_s,
      gender: extract_gender_targeting(targeting['genders']),
      countries: targeting.dig('geo_locations', 'countries'),
      regions: targeting.dig('geo_locations', 'regions')&.map { |r| r['name'] },
      cities: targeting.dig('geo_locations', 'cities')&.map { |c| c['name'] },
      interests: targeting['interests']&.map { |i| i['name'] },
      behaviors: targeting['behaviors']&.map { |b| b['name'] },
      demographics: targeting['demographics']&.map { |d| d['name'] }
    }
  end

  def extract_gender_targeting(genders)
    return 'ALL' if genders.blank?
    return 'ALL' if genders.include?(1) && genders.include?(2)
    return 'M' if genders.include?(1)
    return 'F' if genders.include?(2)
    'ALL'
  end

  def extract_action_count(insight, action_type)
    actions = insight['actions']
    return 0 unless actions.is_a?(Array)

    action = actions.find { |a| a['action_type'] == action_type }
    action&.dig('value')&.to_i || 0
  end

  def extract_action_value(insight, action_type)
    conversion_values = insight['conversion_values']
    return 0 unless conversion_values.is_a?(Array)

    conversion = conversion_values.find { |cv| cv['action_type'] == action_type }
    conversion&.dig('value')&.to_f || 0
  end

  def extract_video_metric(insight, metric_name)
    video_plays = insight['video_plays']
    return 0 unless video_plays.is_a?(Array)

    metric = video_plays.find { |vp| vp['action_type'] == metric_name }
    metric&.dig('value')&.to_i || 0
  end

  def extract_breakdown_values(insight, breakdowns)
    breakdowns.map { |breakdown| insight[breakdown] }.compact
  end

  def extract_platform_metrics(insight)
    # 排除标准字段，保留平台特有指标
    excluded_fields = %w[
      date_start date_stop impressions clicks spend reach frequency
      cpm cpc ctr actions video_plays conversions conversion_values
      publisher_platform platform_position device_platform
    ]

    insight.except(*excluded_fields)
  end

  # 新字段提取方法
  def extract_device_model(insight)
    # Facebook API 可能不直接提供设备型号，可以从breakdown数据提取
    insight['device_model'] || insight['device_platform']
  end

  def extract_operating_system(insight)
    # 从breakdown或直接字段提取操作系统信息
    insight['operating_system'] || insight['os']
  end

  def extract_browser_name(insight)
    insight['browser_name'] || insight['browser']
  end

  def extract_call_to_action(ad)
    return nil unless ad&.dig('creative')
    ad.dig('creative', 'call_to_action_type') ||
    ad.dig('creative', 'object_story_spec', 'link_data', 'call_to_action', 'type')
  end

  def extract_link_destination(insight)
    insight['link_url'] || insight['destination_url']
  end

  def extract_creative_type(ad)
    return nil unless ad&.dig('creative')
    creative = ad['creative']

    # 判断创意类型
    if creative['video_id']
      'video'
    elsif creative['image_url'] || creative['image_hash']
      'image'
    elsif creative['object_story_spec']&.dig('video_data')
      'video'
    elsif creative['object_story_spec']&.dig('photo_data')
      'image'
    elsif creative['object_story_spec']&.dig('link_data')
      'link'
    else
      'unknown'
    end
  end

  def extract_carrier_info(insight)
    # 运营商信息可能在某些breakdown中提供
    insight['carrier'] || nil
  end

  def extract_postal_code(insight)
    # 邮政编码信息可能在地理breakdown中提供
    insight['postal_code'] || nil
  end

  def extract_user_bucket(insight)
    # 用户分桶信息可能在某些breakdown中提供
    insight['user_bucket'] || nil
  end

  def extract_age_range(insight)
    # 提取年龄段信息
    age = insight['age']
    return nil if age.blank?

    # Facebook API返回的年龄格式可能是 "25-34", "35-44" 等
    age.to_s
  end

  def extract_gender(insight)
    # 提取性别信息
    gender = insight['gender']
    return nil if gender.blank?

    # Facebook API返回的性别格式：male, female, unknown
    case gender.to_s.downcase
    when 'male'
      'male'
    when 'female'
      'female'
    else
      'unknown'
    end
  end

  def default_date_range
    {
      since: 7.days.ago.strftime('%Y-%m-%d'),
      until: Date.current.strftime('%Y-%m-%d')
    }
  end

  def handle_sync_error(error)
    error_message = "宽表同步失败: #{error.message}"
    @errors << error_message

    @ads_account.update!(
      sync_status: 'error',
      last_error: error_message,
      last_sync_at: Time.current
    )

    Rails.logger.error "Facebook广告宽表数据同步失败: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end
end


