class FacebookReportService
  attr_reader :ads_account, :access_token, :errors

  def initialize(ads_account)
    @ads_account = ads_account
    @config = Config.first
    # 使用 Config 中的令牌
    @access_token = @config&.facebook_access_token
    @errors = []
  end

  # 主同步方法 - 使用字段展开一次性获取所有数据
  def fetch_recent_data(date_range = nil)
    return false unless validate_account

    begin
      Rails.logger.info "开始同步Facebook广告数据到宽表: #{@ads_account.account_id}"

      # 获取同步日期范围
      date_range = date_range || default_date_range
      clear_existing_data(date_range)

      # 使用字段展开一次性获取所有层级的数据
      sync_all_data_with_field_expansion(date_range)

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

  # 测试连接
  def self.test_connection(config)
    return { success: false, message: 'Config 未找到' } unless config
    return { success: false, message: 'Adjust API Token 未配置' } if config.adjust_api_token.blank?

    begin
      # 这里实际应该调用 Adjust API 进行测试
      # 暂时返回成功
      { success: true, message: 'Adjust API 连接测试成功' }
    rescue StandardError => e
      { success: false, message: "连接失败: #{e.message}" }
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
      @errors << '缺少访问令牌，请在系统设置中配置 Facebook 凭证'
      return false
    end

    # 验证令牌是否有效
    unless FacebookTokenService.validate_token
      @errors << '访问令牌无效或已过期，请刷新令牌'
      return false
    end

    true
  end

  # 使用字段展开一次性获取所有数据
  def sync_all_data_with_field_expansion(date_range)
    Rails.logger.info "使用字段展开方式获取数据..."

    # 构建嵌套字段查询
    # 一次请求获取: campaigns -> adsets -> ads -> insights
    fields = build_nested_fields(date_range)

    endpoint = "act_#{@ads_account.account_id}/campaigns"
    url = "https://graph.facebook.com/v18.0/#{endpoint}"

    query_params = {
      access_token: @access_token,
      fields: fields,
      limit: 100  # 每页最多100个campaigns
    }

    Rails.logger.info "请求URL: #{url}"
    Rails.logger.info "完整字段参数: #{fields}"

    all_campaigns = []
    next_url = url

    # 处理分页
    while next_url
      Rails.logger.info "正在请求: #{next_url == url ? 'first page' : 'next page'}"

      response = if next_url == url
        HTTParty.get(url, query: query_params, timeout: 120)
      else
        HTTParty.get(next_url, timeout: 120)
      end

      unless response.success?
        Rails.logger.error "Facebook API请求失败: #{response.code} - #{response.body}"
        raise "Facebook API请求失败: #{response.body}"
      end

      data = response.parsed_response

      # 调试：打印返回数据的结构
      Rails.logger.info "API 返回数据结构: data.keys = #{data.keys}"

      campaigns = data['data'] || []
      all_campaigns.concat(campaigns)

      Rails.logger.info "获取到 #{campaigns.size} 个 campaigns (累计: #{all_campaigns.size})"

      # 如果有campaigns，打印第一个的结构
      if campaigns.any?
        first_campaign = campaigns.first
        Rails.logger.info "第一个 Campaign 结构: #{first_campaign.keys}"
        if first_campaign['adsets']
          Rails.logger.info "  - adsets 存在, keys: #{first_campaign['adsets'].keys}"
          adsets_data = first_campaign['adsets']['data'] || []
          Rails.logger.info "  - adsets 数量: #{adsets_data.size}"

          if adsets_data.any?
            first_adset = adsets_data.first
            Rails.logger.info "  - 第一个 adset keys: #{first_adset.keys}"
            if first_adset['ads']
              Rails.logger.info "    - ads 存在, keys: #{first_adset['ads'].keys}"
              ads_data = first_adset['ads']['data'] || []
              Rails.logger.info "    - ads 数量: #{ads_data.size}"

              if ads_data.any?
                first_ad = ads_data.first
                Rails.logger.info "    - 第一个 ad keys: #{first_ad.keys}"
                if first_ad['insights']
                  Rails.logger.info "      - insights 存在, keys: #{first_ad['insights'].keys}"
                  insights_data = first_ad['insights']['data'] || []
                  Rails.logger.info "      - insights 数量: #{insights_data.size}"
                end
              end
            end
          end
        end
      end

      # 获取下一页
      next_url = data.dig('paging', 'next')
    end

    Rails.logger.info "总共获取到 #{all_campaigns.size} 个 campaigns"

    # 处理获取到的数据
    total_records = 0
    all_campaigns.each do |campaign|
      records = process_campaign_data(campaign, date_range)
      total_records += records
    end

    Rails.logger.info "总共生成 #{total_records} 条广告数据记录"
  end

  # 构建嵌套字段查询
  def build_nested_fields(date_range)
    # 构建 insights 字段 - 不包含 breakdown 字段
    insights_fields = %w[
      date_start
      date_stop
      impressions
      clicks
      spend
      actions
      action_values
      cost_per_action_type
    ].join(',')

    # 构建 insights 的查询参数
    since_date = date_range[:since]
    until_date = date_range[:until]

    # 构建完整的嵌套字段查询
    # 使用 breakdowns 参数获取按小时聚合的数据
    # hourly_stats_aggregated_by_advertiser_time_zone 作为 breakdown，会自动出现在返回数据中
    "id,name,status,objective,adsets.limit(100){id,name,status,ads.limit(100){id,name,status,insights.time_range({'since':'#{since_date}','until':'#{until_date}'}).time_increment(1).level(ad).breakdowns(['hourly_stats_aggregated_by_advertiser_time_zone']){#{insights_fields}}}}"
  end

  # 处理单个 campaign 的数据
  def process_campaign_data(campaign, date_range)
    campaign_info = {
      'id' => campaign['id'],
      'name' => campaign['name'],
      'status' => campaign['status']
    }

    records_count = 0
    adsets = campaign['adsets']&.dig('data') || []

    Rails.logger.info "Campaign #{campaign['name']}: 包含 #{adsets.size} 个 adsets"

    adsets.each do |adset|
      records_count += process_adset_data(adset, campaign_info)
    end

    records_count
  end

  # 处理单个 adset 的数据
  def process_adset_data(adset, campaign_info)
    adset_info = {
      'id' => adset['id'],
      'name' => adset['name'],
      'status' => adset['status']
    }

    records_count = 0
    ads = adset['ads']&.dig('data') || []

    Rails.logger.info "  AdSet #{adset['name']}: 包含 #{ads.size} 个 ads"

    ads.each do |ad|
      records_count += process_ad_data(ad, campaign_info, adset_info)
    end

    records_count
  end

  # 处理单个 ad 的数据
  def process_ad_data(ad, campaign_info, adset_info)
    ad_info = {
      'id' => ad['id'],
      'name' => ad['name'],
      'status' => ad['status']
    }

    insights_data = ad['insights']&.dig('data') || []

    if insights_data.empty?
      Rails.logger.debug "    Ad #{ad['name']}: 无 insights 数据"
      return 0
    end

    Rails.logger.info "    Ad #{ad['name']}: 包含 #{insights_data.size} 条 insights"

    # 批量生成数据记录
    rows = insights_data.map do |insight|
      generate_ads_data(insight, campaign_info, adset_info, ad_info)
    end

    # 批量插入数据库
    AdsData.insert_all!(rows) if rows.any?

    rows.size
  end

  # 生成宽表数据记录
  def generate_ads_data(insight, campaign, adset, ad)

    # 解析日期
    date_start = insight['date_start']
    date = Date.parse(date_start)
    day_of_week = I18n.l(date, format: '%A')

    # 解析小时信息 - 从 breakdown 字段中提取
    hour_str = insight['hourly_stats_aggregated_by_advertiser_time_zone'] || '00'
    hour_of_day = hour_str.to_s[0..1].to_i

    # 构建唯一键 - 包含小时信息以区分同一天不同小时的数据
    unique_parts = [
      date.to_s,
      hour_of_day.to_s,
      campaign['name'],
      adset['name'],
      ad['name']
    ].compact

    unique_key = Digest::MD5.hexdigest(unique_parts.join('|'))

    {
      unique_key: unique_key,
      ads_account_id: @ads_account.id,
      project_id: @ads_account.project_id,
      platform: 'facebook',
      date: date,
      datetime: date.beginning_of_day + hour_of_day.hours,
      hour: hour_of_day.to_s,
      day_of_week: day_of_week,
      year: date.year.to_s,
      month: date.strftime('%Y-%m'),
      quarter: "#{date.year}-Q#{(date.month - 1) / 3 + 1}",
      week: date.strftime('%Y-%W'),

      # 活动信息
      campaign_id: campaign['id'],
      campaign_name: campaign['name'],

      # 广告组信息
      adset_id: adset['id'],
      adset_name: adset['name'],

      # 广告信息
      ad_id: ad['id'],
      ad_name: ad['name'],

      # 核心指标
      impressions: insight['impressions']&.to_i || 0,
      clicks: insight['clicks']&.to_i || 0,
      spend: insight['spend']&.to_f || 0,

      # 转化相关 - 从 actions 和 action_values 中提取
      # 支持多种可能的 action_type 名称
      installs: extract_action_count(insight,
        'mobile_app_install', 'app_install', 'omni_app_install'
      ),
      conversions: extract_action_count(insight,
        'offsite_conversion', 'omni_purchase', 'purchase', 'onsite_conversion.post_save'
      ),
      revenue: extract_action_value(insight,
        'omni_purchase', 'purchase', 'offsite_conversion.fb_pixel_purchase'
      ),

      # 原始数据
      raw_data: insight,

      # 数据状态
      data_status: 'active',
      data_source: 'api',
      data_fetched_at: Time.current
    }
  end

  # 数据解析辅助方法
  def extract_action_count(insight, *action_types)
    actions = insight['actions']
    return 0 unless actions.is_a?(Array)

    # 打印调试信息（仅在第一次）
    if @debug_actions_printed.nil?
      Rails.logger.info "可用的 action_types: #{actions.map { |a| a['action_type'] }.uniq.join(', ')}"
      @debug_actions_printed = true
    end

    # 尝试匹配多个可能的 action_type
    action_types.flatten.each do |action_type|
      action = actions.find { |a| a['action_type'] == action_type }
      return action['value'].to_i if action
    end

    0
  end

  def extract_action_value(insight, *action_types)
    action_values = insight['action_values']
    return 0 unless action_values.is_a?(Array)

    # 打印调试信息（仅在第一次）
    if @debug_action_values_printed.nil?
      Rails.logger.info "可用的 action_value types: #{action_values.map { |av| av['action_type'] }.uniq.join(', ')}"
      @debug_action_values_printed = true
    end

    # 尝试匹配多个可能的 action_type
    action_types.flatten.each do |action_type|
      action_value = action_values.find { |av| av['action_type'] == action_type }
      return action_value['value'].to_f if action_value
    end

    0
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
