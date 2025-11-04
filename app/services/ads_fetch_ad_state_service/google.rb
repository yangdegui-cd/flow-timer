class AdsFetchAdStateService::Google < AdsFetchAdStateService
  GOOGLE_ADS_API_VERSION = 'v18'
  GOOGLE_ADS_API_BASE_URL = 'https://googleads.googleapis.com'

  def initialize(ads_account)
    super(ads_account)
    @config = Config.first
    @developer_token = @config&.google_ads_developer_token
    @client_id = @config&.google_ads_client_id
    @client_secret = @config&.google_ads_client_secret
    @refresh_token = @config&.google_ads_refresh_token
    @customer_id = ads_account.account_id&.gsub('-', '') # 移除连字符
  end

  # 主同步方法
  def sync_all
    return false unless validate_account
    return false unless validate_google_credentials

    begin
      Rails.logger.info "开始同步 Google Ads 广告状态: #{@ads_account.account_id}"

      # 获取访问令牌
      access_token = get_access_token
      return false unless access_token

      # 使用 Google Ads Query Language 查询广告数据
      sync_ads_data(access_token)

      Rails.logger.info "Google Ads 广告状态同步完成: #{@ads_account.account_id}"
      true

    rescue StandardError => e
      handle_sync_error(e)
      false
    end
  end

  private

  def validate_google_credentials
    unless @developer_token.present? && @refresh_token.present?
      @errors << '缺少 Google Ads API 凭证（开发者令牌或刷新令牌）'
      return false
    end

    unless @customer_id.present?
      @errors << '缺少 Google Ads 客户账户ID'
      return false
    end

    true
  end

  # 获取访问令牌
  def get_access_token
    url = 'https://oauth2.googleapis.com/token'

    response = HTTParty.post(url, {
      body: {
        client_id: @client_id,
        client_secret: @client_secret,
        refresh_token: @refresh_token,
        grant_type: 'refresh_token'
      },
      timeout: 30
    })

    unless response.success?
      @errors << "获取 Google Ads 访问令牌失败: #{response.body}"
      Rails.logger.error "Google Ads OAuth 失败: #{response.body}"
      return nil
    end

    response.parsed_response['access_token']
  rescue StandardError => e
    @errors << "获取 Google Ads 访问令牌异常: #{e.message}"
    Rails.logger.error "获取访问令牌异常: #{e.message}"
    nil
  end

  # 同步广告数据
  def sync_ads_data(access_token)
    # 使用 Google Ads Query Language (GAQL) 查询
    query = build_gaql_query

    url = "#{GOOGLE_ADS_API_BASE_URL}/#{GOOGLE_ADS_API_VERSION}/customers/#{@customer_id}/googleAds:searchStream"

    headers = {
      'Authorization' => "Bearer #{access_token}",
      'developer-token' => @developer_token,
      'Content-Type' => 'application/json'
    }

    body = {
      query: query
    }

    Rails.logger.info "Google Ads API 请求URL: #{url}"
    Rails.logger.info "查询语句: #{query}"

    response = HTTParty.post(url, {
      headers: headers,
      body: body.to_json,
      timeout: 120
    })

    unless response.success?
      Rails.logger.error "Google Ads API 请求失败: #{response.code} - #{response.body}"
      raise "Google Ads API 请求失败: #{response.body}"
    end

    # 处理响应数据
    process_google_ads_response(response.parsed_response)
  end

  # 构建 GAQL 查询语句
  def build_gaql_query
    # 查询活跃的广告及其关联的广告组、广告系列和创意信息
    <<~GAQL
      SELECT
        campaign.id,
        campaign.name,
        campaign.status,
        campaign.advertising_channel_type,
        campaign.bidding_strategy_type,
        ad_group.id,
        ad_group.name,
        ad_group.status,
        ad_group.type,
        ad_group.effective_target_cpa_micros,
        ad_group.target_cpa_micros,
        ad_group.cpc_bid_micros,
        ad_group_ad.ad.id,
        ad_group_ad.ad.name,
        ad_group_ad.ad.type,
        ad_group_ad.status,
        ad_group_ad.ad.final_urls,
        ad_group_ad.ad.responsive_display_ad.headlines,
        ad_group_ad.ad.responsive_display_ad.descriptions,
        ad_group_ad.ad.responsive_display_ad.marketing_images,
        ad_group_ad.ad.app_ad.headlines,
        ad_group_ad.ad.app_ad.descriptions,
        ad_group_ad.ad.app_ad.images
      FROM ad_group_ad
      WHERE campaign.status != 'REMOVED'
        AND ad_group.status != 'REMOVED'
        AND ad_group_ad.status != 'REMOVED'
      LIMIT 10000
    GAQL
  end

  # 处理 Google Ads API 响应
  def process_google_ads_response(response_data)
    total_records = 0

    # Google Ads API 返回的是流式响应，包含多个结果批次
    results = response_data.is_a?(Array) ? response_data : [response_data]

    results.each do |batch|
      next unless batch['results']

      batch['results'].each do |result|
        ad_state_data = build_ad_state_from_google_result(result)
        save_ad_state(ad_state_data)
        total_records += 1
      end
    end

    Rails.logger.info "总共生成 #{total_records} 条 Google Ads 广告状态记录"
  end

  # 从 Google Ads 结果构建广告状态数据
  def build_ad_state_from_google_result(result)
    campaign = result['campaign'] || {}
    ad_group = result['adGroup'] || {}
    ad_group_ad = result['adGroupAd'] || {}
    ad = ad_group_ad['ad'] || {}

    # 解析预算和出价（Google Ads 使用 micros 单位，需要除以 1,000,000）
    target_cpa = parse_micros(ad_group['effectiveTargetCpaMicros'] || ad_group['targetCpaMicros'])
    cpc_bid = parse_micros(ad_group['cpcBidMicros'])

    # 提取创意信息
    creative_data = extract_google_creative_data(ad)

    {
      platform: 'google',
      ads_account_id: @ads_account.id,

      # Campaign 信息
      campaign_id: campaign['id'],
      campaign_name: campaign['name'],
      campaign_status: campaign['status'],
      campaign_objective: campaign['advertisingChannelType'],
      campaign_buying_type: campaign['biddingStrategyType'],

      # AdGroup 信息
      adset_id: ad_group['id'],
      adset_name: ad_group['name'],
      adset_status: ad_group['status'],
      adset_effective_status: ad_group['status'],

      # Ad 信息
      ad_id: ad['id'],
      ad_name: ad['name'] || "Ad #{ad['id']}",
      ad_status: ad_group_ad['status'],
      ad_effective_status: ad_group_ad['status'],

      # 预算和出价信息
      bid_amount: cpc_bid || target_cpa,
      bid_strategy: campaign['biddingStrategyType'],
      optimization_goal: ad_group['type'],

      # 创意信息
      creative_id: ad['id'],
      ad_title: creative_data[:title],
      ad_body: creative_data[:body],
      ad_description: creative_data[:description],
      image_url: creative_data[:image_url],
      link_url: creative_data[:link_url],

      # 同步状态
      synced_at: Time.current,
      sync_status: 'synced',
      sync_error: nil,

      # 原始数据
      campaign_raw_data: campaign,
      adset_raw_data: ad_group,
      ad_raw_data: ad,
      creative_raw_data: ad
    }
  end

  # 提取 Google Ads 创意数据
  def extract_google_creative_data(ad)
    ad_type = ad['type']

    case ad_type
    when 'RESPONSIVE_DISPLAY_AD'
      extract_responsive_display_ad_data(ad)
    when 'APP_AD'
      extract_app_ad_data(ad)
    when 'RESPONSIVE_SEARCH_AD'
      extract_responsive_search_ad_data(ad)
    else
      extract_generic_ad_data(ad)
    end
  end

  # 提取响应式展示广告数据
  def extract_responsive_display_ad_data(ad)
    responsive_ad = ad['responsiveDisplayAd'] || {}

    headlines = responsive_ad['headlines']&.map { |h| h['text'] }&.join(' | ') || ''
    descriptions = responsive_ad['descriptions']&.map { |d| d['text'] }&.join(' | ') || ''
    image_url = responsive_ad['marketingImages']&.first&.dig('asset', 'imageAsset', 'fullSize', 'url')

    {
      title: headlines,
      body: descriptions,
      description: descriptions,
      image_url: image_url,
      link_url: ad['finalUrls']&.first
    }
  end

  # 提取应用广告数据
  def extract_app_ad_data(ad)
    app_ad = ad['appAd'] || {}

    headlines = app_ad['headlines']&.map { |h| h['text'] }&.join(' | ') || ''
    descriptions = app_ad['descriptions']&.map { |d| d['text'] }&.join(' | ') || ''
    image_url = app_ad['images']&.first&.dig('asset', 'imageAsset', 'fullSize', 'url')

    {
      title: headlines,
      body: descriptions,
      description: descriptions,
      image_url: image_url,
      link_url: ad['finalUrls']&.first
    }
  end

  # 提取响应式搜索广告数据
  def extract_responsive_search_ad_data(ad)
    responsive_ad = ad['responsiveSearchAd'] || {}

    headlines = responsive_ad['headlines']&.map { |h| h['text'] }&.join(' | ') || ''
    descriptions = responsive_ad['descriptions']&.map { |d| d['text'] }&.join(' | ') || ''

    {
      title: headlines,
      body: '',
      description: descriptions,
      image_url: nil,
      link_url: ad['finalUrls']&.first
    }
  end

  # 提取通用广告数据
  def extract_generic_ad_data(ad)
    {
      title: ad['name'] || "Ad #{ad['id']}",
      body: '',
      description: '',
      image_url: nil,
      link_url: ad['finalUrls']&.first
    }
  end

  # 解析 micros 单位（Google Ads 使用微单位）
  def parse_micros(micros_value)
    return nil if micros_value.blank? || micros_value.to_i == 0
    micros_value.to_f / 1_000_000.0
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
      Rails.logger.debug "  ✓ 保存 Google 广告: #{ad_state.ad_name}"
      true
    else
      Rails.logger.error "  ✗ 保存 Google 广告失败: #{ad_state.errors.full_messages.join(', ')}"
      false
    end
  end
end
