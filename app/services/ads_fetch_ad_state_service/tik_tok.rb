class AdsFetchAdStateService::TikTok < AdsFetchAdStateService
  TIKTOK_ADS_API_VERSION = 'v1.3'
  TIKTOK_ADS_API_BASE_URL = 'https://business-api.tiktok.com/open_api'

  def initialize(ads_account)
    super(ads_account)
    @config = Config.first
    @access_token = @config&.tiktok_access_token
    @advertiser_id = ads_account.account_id
  end

  # 主同步方法
  def sync_all
    return false unless validate_account
    return false unless validate_tiktok_token

    begin
      Rails.logger.info "开始同步 TikTok Ads 广告状态: #{@ads_account.account_id}"

      # 获取广告数据
      sync_tiktok_ads_data

      Rails.logger.info "TikTok Ads 广告状态同步完成: #{@ads_account.account_id}"
      true

    rescue StandardError => e
      handle_sync_error(e)
      false
    end
  end

  private

  def validate_tiktok_token
    unless @access_token.present?
      @errors << '缺少 TikTok Ads 访问令牌'
      return false
    end

    unless @advertiser_id.present?
      @errors << '缺少 TikTok 广告主账户ID'
      return false
    end

    true
  end

  # 同步 TikTok 广告数据
  def sync_tiktok_ads_data
    # TikTok Ads API 需要分层获取：Campaigns -> AdGroups -> Ads
    campaigns = fetch_campaigns
    return if campaigns.empty?

    total_records = 0

    campaigns.each do |campaign|
      adgroups = fetch_adgroups(campaign['campaign_id'])

      adgroups.each do |adgroup|
        ads = fetch_ads(adgroup['adgroup_id'])

        ads.each do |ad|
          # 获取创意信息
          creative = fetch_creative(ad['creative_id']) if ad['creative_id']

          ad_state_data = build_ad_state_from_tiktok_data(campaign, adgroup, ad, creative)
          save_ad_state(ad_state_data)
          total_records += 1
        end
      end
    end

    Rails.logger.info "总共生成 #{total_records} 条 TikTok Ads 广告状态记录"
  end

  # 获取广告系列列表
  def fetch_campaigns
    url = "#{TIKTOK_ADS_API_BASE_URL}/#{TIKTOK_ADS_API_VERSION}/campaign/get/"

    params = {
      advertiser_id: @advertiser_id,
      page_size: 100
    }

    response = make_tiktok_api_request(url, params)
    return [] unless response

    campaigns = response.dig('data', 'list') || []
    Rails.logger.info "获取到 #{campaigns.size} 个 TikTok campaigns"
    campaigns
  end

  # 获取广告组列表
  def fetch_adgroups(campaign_id)
    url = "#{TIKTOK_ADS_API_BASE_URL}/#{TIKTOK_ADS_API_VERSION}/adgroup/get/"

    params = {
      advertiser_id: @advertiser_id,
      campaign_ids: [campaign_id].to_json,
      page_size: 100
    }

    response = make_tiktok_api_request(url, params)
    return [] unless response

    response.dig('data', 'list') || []
  end

  # 获取广告列表
  def fetch_ads(adgroup_id)
    url = "#{TIKTOK_ADS_API_BASE_URL}/#{TIKTOK_ADS_API_VERSION}/ad/get/"

    params = {
      advertiser_id: @advertiser_id,
      adgroup_ids: [adgroup_id].to_json,
      page_size: 100
    }

    response = make_tiktok_api_request(url, params)
    return [] unless response

    response.dig('data', 'list') || []
  end

  # 获取创意信息
  def fetch_creative(creative_id)
    url = "#{TIKTOK_ADS_API_BASE_URL}/#{TIKTOK_ADS_API_VERSION}/creative/get/"

    params = {
      advertiser_id: @advertiser_id,
      creative_ids: [creative_id].to_json
    }

    response = make_tiktok_api_request(url, params)
    return nil unless response

    creatives = response.dig('data', 'list') || []
    creatives.first
  end

  # 发起 TikTok API 请求
  def make_tiktok_api_request(url, params)
    headers = {
      'Access-Token' => @access_token,
      'Content-Type' => 'application/json'
    }

    response = HTTParty.get(url, {
      headers: headers,
      query: params,
      timeout: 60
    })

    unless response.success?
      Rails.logger.error "TikTok API 请求失败: #{response.code} - #{response.body}"
      return nil
    end

    parsed_response = response.parsed_response

    # TikTok API 返回格式: { code: 0, message: 'OK', data: {...} }
    if parsed_response['code'] != 0
      Rails.logger.error "TikTok API 返回错误: #{parsed_response['message']}"
      return nil
    end

    parsed_response
  rescue StandardError => e
    Rails.logger.error "TikTok API 请求异常: #{e.message}"
    nil
  end

  # 从 TikTok 数据构建广告状态
  def build_ad_state_from_tiktok_data(campaign, adgroup, ad, creative)
    # 解析预算（TikTok 可能返回分或元，需要确认）
    daily_budget = parse_budget(adgroup['budget'])
    bid_amount = parse_budget(adgroup['bid_price'])

    # 提取创意信息
    creative_data = extract_tiktok_creative_data(creative, ad)

    {
      platform: 'tiktok',
      ads_account_id: @ads_account.id,

      # Campaign 信息
      campaign_id: campaign['campaign_id'].to_s,
      campaign_name: campaign['campaign_name'],
      campaign_status: campaign['operation_status'],
      campaign_objective: campaign['objective_type'],
      campaign_buying_type: campaign['budget_mode'],

      # AdGroup 信息
      adset_id: adgroup['adgroup_id'].to_s,
      adset_name: adgroup['adgroup_name'],
      adset_status: adgroup['operation_status'],
      adset_effective_status: adgroup['operation_status'],

      # Ad 信息
      ad_id: ad['ad_id'].to_s,
      ad_name: ad['ad_name'],
      ad_status: ad['operation_status'],
      ad_effective_status: ad['operation_status'],

      # 预算和出价信息
      daily_budget: daily_budget,
      bid_amount: bid_amount,
      bid_strategy: adgroup['bid_type'],
      optimization_goal: adgroup['optimization_goal'],
      billing_event: adgroup['billing_event'],

      # 时间信息
      start_time: parse_time(adgroup['schedule_start_time']),
      stop_time: parse_time(adgroup['schedule_end_time']),

      # 创意信息
      creative_id: creative_data[:creative_id],
      creative_name: creative_data[:creative_name],
      ad_title: creative_data[:title],
      ad_body: creative_data[:body],
      ad_description: creative_data[:description],
      image_url: creative_data[:image_url],
      video_id: creative_data[:video_id],
      video_url: creative_data[:video_url],
      thumbnail_url: creative_data[:thumbnail_url],
      call_to_action: creative_data[:call_to_action],
      link_url: creative_data[:link_url],

      # 同步状态
      synced_at: Time.current,
      sync_status: 'synced',
      sync_error: nil,

      # 原始数据
      campaign_raw_data: campaign,
      adset_raw_data: adgroup,
      ad_raw_data: ad,
      creative_raw_data: creative
    }
  end

  # 提取 TikTok 创意数据
  def extract_tiktok_creative_data(creative, ad)
    return default_creative_data(ad) unless creative

    # TikTok 创意数据结构
    {
      creative_id: creative['creative_id'],
      creative_name: creative['creative_name'],
      title: creative['ad_text'],
      body: creative['ad_text'],
      description: creative['call_to_action'],
      image_url: creative['image_ids']&.first, # 图片ID，可能需要进一步转换为URL
      video_id: creative['video_id'],
      video_url: creative['video_url'],
      thumbnail_url: creative['thumbnail_url'],
      call_to_action: creative['call_to_action'],
      link_url: creative['landing_page_url'] || ad['landing_page_url']
    }
  end

  # 默认创意数据（当无法获取创意时）
  def default_creative_data(ad)
    {
      creative_id: ad['creative_id'],
      creative_name: nil,
      title: ad['ad_name'],
      body: nil,
      description: nil,
      image_url: nil,
      video_id: nil,
      video_url: nil,
      thumbnail_url: nil,
      call_to_action: nil,
      link_url: ad['landing_page_url']
    }
  end

  # 解析预算（根据 TikTok API 文档调整）
  def parse_budget(budget_str)
    return nil if budget_str.blank?
    # TikTok 可能使用不同的货币单位，这里假设返回的是实际金额
    budget_str.to_f
  end

  # 保存广告状态
  def save_ad_state(data)
    ad_state = AdState.find_or_initialize_by(
      platform: data[:platform],
      ads_account_id: data[:ads_account_id],
      campaign_id: data[:campaign_id],
      adset_id: data[:adset_id],
      ad_id: data[:ad_id]
    )

    ad_state.assign_attributes(data)

    if ad_state.save
      Rails.logger.debug "  ✓ 保存 TikTok 广告: #{ad_state.ad_name}"
      true
    else
      Rails.logger.error "  ✗ 保存 TikTok 广告失败: #{ad_state.errors.full_messages.join(', ')}"
      false
    end
  end
end
