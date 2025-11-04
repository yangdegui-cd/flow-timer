class AdsFetchAdStateService::Facebook < AdsFetchAdStateService
  def initialize(ads_account)
    super(ads_account)
    @config = Config.first
    @access_token = @config&.facebook_access_token
  end

  # 主同步方法 - 使用字段展开一次性获取所有数据
  def sync_all
    return false unless validate_account
    return false unless validate_facebook_token

    begin
      Rails.logger.info "开始同步 Facebook 广告状态: #{@ads_account.account_id}"

      # 一次性获取所有层级的数据
      sync_all_data_with_field_expansion

      Rails.logger.info "Facebook 广告状态同步完成: #{@ads_account.account_id}"
      true

    rescue StandardError => e
      handle_sync_error(e)
      false
    end
  end

  private

  def validate_facebook_token
    unless @access_token.present?
      @errors << '缺少 Facebook 访问令牌'
      return false
    end

    unless FacebookTokenService.validate_token
      @errors << 'Facebook 访问令牌无效或已过期'
      return false
    end

    true
  end

  # 使用字段展开一次性获取所有数据
  def sync_all_data_with_field_expansion
    Rails.logger.info "使用字段展开方式获取广告状态数据..."

    # 构建嵌套字段查询：campaigns -> adsets -> ads -> creative
    fields = build_nested_fields

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
      campaigns = data['data'] || []
      all_campaigns.concat(campaigns)

      Rails.logger.info "获取到 #{campaigns.size} 个 campaigns (累计: #{all_campaigns.size})"

      # 获取下一页
      next_url = data.dig('paging', 'next')
    end

    Rails.logger.info "总共获取到 #{all_campaigns.size} 个 campaigns"

    # 处理获取到的数据
    total_records = 0
    all_campaigns.each do |campaign|
      records = process_campaign_data(campaign)
      total_records += records
    end

    Rails.logger.info "总共生成 #{total_records} 条广告状态记录"
  end

  # 构建嵌套字段查询
  def build_nested_fields
    # Campaign 字段
    campaign_fields = %w[
      id
      name
      effective_status
      objective
      buying_type
    ].join(',')

    # Adset 字段
    adset_fields = %w[
      id
      name
      effective_status
      daily_budget
      lifetime_budget
      budget_remaining
      bid_amount
      bid_strategy
      optimization_goal
      billing_event
      targeting
      start_time
      end_time
    ].join(',')

    # Ad 字段
    ad_fields = %w[
      id
      name
      effective_status
    ].join(',')

    # Creative 字段
    creative_fields = %w[
      id
      name
      image_url
      image_hash
      video_id
      thumbnail_url
      title
      body
      link_url
      call_to_action_type
      object_story_spec
    ].join(',')

    # 构建完整的嵌套字段查询
    "#{campaign_fields},adsets.limit(100){#{adset_fields},ads.limit(100){#{ad_fields},creative{#{creative_fields}}}}"
  end

  # 处理单个 campaign 的数据
  def process_campaign_data(campaign)
    campaign_info = {
      'id' => campaign['id'],
      'name' => campaign['name'],
      'effective_status' => campaign['effective_status'],
      'objective' => campaign['objective'],
      'buying_type' => campaign['buying_type']
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
      'effective_status' => adset['effective_status'],
      'daily_budget' => adset['daily_budget'],
      'lifetime_budget' => adset['lifetime_budget'],
      'budget_remaining' => adset['budget_remaining'],
      'bid_amount' => adset['bid_amount'],
      'bid_strategy' => adset['bid_strategy'],
      'optimization_goal' => adset['optimization_goal'],
      'billing_event' => adset['billing_event'],
      'targeting' => adset['targeting'],
      'start_time' => adset['start_time'],
      'end_time' => adset['end_time']
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
      'effective_status' => ad['effective_status']
    }

    creative = ad['creative'] || {}

    Rails.logger.info "    Ad #{ad['name']}: creative_id = #{creative['id']}"

    # 生成广告状态记录
    ad_state_data = generate_ad_state_data(campaign_info, adset_info, ad_info, creative)

    # 保存到数据库
    save_ad_state(ad_state_data)

    1  # 返回处理的记录数
  end

  # 生成广告状态数据记录
  def generate_ad_state_data(campaign, adset, ad, creative)
    # 解析预算（Facebook 返回的是分）
    daily_budget = parse_budget(adset['daily_budget'])
    lifetime_budget = parse_budget(adset['lifetime_budget'])
    bid_amount = parse_budget(adset['bid_amount'])

    # 解析时间
    start_time = parse_time(adset['start_time'])
    stop_time = parse_time(adset['end_time'])

    # 提取创意信息
    creative_data = extract_creative_data(creative)

    {
      platform: 'facebook',
      ads_account_id: @ads_account.id,

      # Campaign 信息
      campaign_id: campaign['id'],
      campaign_name: campaign['name'],
      campaign_effective_status: campaign['effective_status'],
      campaign_objective: campaign['objective'],
      campaign_buying_type: campaign['buying_type'],

      # Adset 信息
      adset_id: adset['id'],
      adset_name: adset['name'],
      adset_effective_status: adset['effective_status'],

      # Ad 信息
      ad_id: ad['id'],
      ad_name: ad['name'],
      ad_effective_status: ad['effective_status'],

      # 预算信息
      daily_budget: daily_budget,
      lifetime_budget: lifetime_budget,
      bid_amount: bid_amount,
      budget_remaining: adset['budget_remaining'],

      # 出价信息
      bid_strategy: adset['bid_strategy'],
      optimization_goal: adset['optimization_goal'],
      billing_event: adset['billing_event'],

      # 定向信息
      targeting: adset['targeting'],

      # 时间信息
      start_time: start_time,
      stop_time: stop_time,

      # 创意信息
      creative_id: creative_data[:creative_id],
      creative_name: creative_data[:creative_name],
      image_url: creative_data[:image_url],
      image_hash: creative_data[:image_hash],
      video_id: creative_data[:video_id],
      video_url: creative_data[:video_url],
      thumbnail_url: creative_data[:thumbnail_url],
      ad_title: creative_data[:title],
      ad_body: creative_data[:body],
      ad_description: creative_data[:description],
      call_to_action: creative_data[:call_to_action],
      link_url: creative_data[:link_url],

      # 同步状态
      synced_at: Time.current,
      sync_status: 'synced',
      sync_error: nil
    }
  end

  # 提取创意数据
  def extract_creative_data(creative)
    return {} if creative.blank?

    # 提取视频 URL（如果有）
    video_url = nil
    if creative['video_id'].present?
      # 可以构建视频 URL 或者通过 API 获取
      video_url = "https://www.facebook.com/video.php?v=#{creative['video_id']}"
    end

    # 提取文案信息
    object_story_spec = creative['object_story_spec'] || {}
    link_data = object_story_spec.dig('link_data') || {}

    {
      creative_id: creative['id'],
      creative_name: creative['name'],
      image_url: creative['image_url'],
      image_hash: creative['image_hash'],
      video_id: creative['video_id'],
      video_url: video_url,
      thumbnail_url: creative['thumbnail_url'],
      title: creative['title'] || link_data['name'],
      body: creative['body'] || link_data['message'],
      description: link_data['description'],
      call_to_action: creative['call_to_action_type'],
      link_url: creative['link_url'] || link_data['link']
    }
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
      Rails.logger.debug "      ✓ 保存广告: #{ad_state.ad_name}"
      true
    else
      Rails.logger.error "      ✗ 保存广告失败: #{ad_state.errors.full_messages.join(', ')}"
      false
    end
  end

  # 解析预算金额（Facebook API 返回的是分）
  def parse_budget(budget_str)
    return nil if budget_str.blank?
    budget_str.to_f / 100.0  # 转换为元
  end
end
