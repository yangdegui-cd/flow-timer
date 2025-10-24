class CreateAdsDataWideTable < ActiveRecord::Migration[7.1]
  def change
    # 广告数据宽表 - 类似Adjust设计
    create_table :ads_data do |t|
      # 基础关联信息
      t.references :ads_account, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :platform, null: false # facebook, google, twitter, tiktok, etc.

      # 时间维度
      t.date :date, null: false
      t.string :hour # 00-23, 支持小时级别数据
      t.string :week # YYYY-WW
      t.string :month # YYYY-MM
      t.string :quarter # YYYY-Q1, YYYY-Q2, etc.
      t.string :year # YYYY

      # 平台层级结构信息
      t.string :campaign_id # 活动ID
      t.string :campaign_name
      t.string :adset_id # 广告组ID
      t.string :adset_name
      t.string :ad_id # 广告ID
      t.string :ad_name
      t.string :creative_id # 创意ID
      t.string :creative_name

      # 活动级别信息
      t.string :campaign_status # ACTIVE, PAUSED, DELETED
      t.string :campaign_objective # 活动目标
      t.string :buying_type # AUCTION, RESERVATION
      t.decimal :campaign_daily_budget, precision: 15, scale: 2
      t.decimal :campaign_lifetime_budget, precision: 15, scale: 2

      # 广告组级别信息
      t.string :adset_status
      t.string :optimization_goal # 优化目标
      t.string :billing_event # 计费事件
      t.decimal :adset_daily_budget, precision: 15, scale: 2
      t.decimal :bid_amount, precision: 15, scale: 2

      # 广告级别信息
      t.string :ad_status
      t.string :ad_format # SINGLE_IMAGE, VIDEO, CAROUSEL, etc.
      t.text :ad_creative_data # JSON: 创意详细信息

      # 定向信息 (JSON格式)
      t.text :targeting_data
      t.string :age_min
      t.string :age_max
      t.string :gender # M, F, ALL
      t.text :countries # JSON数组
      t.text :regions # JSON数组
      t.text :cities # JSON数组
      t.text :interests # JSON数组
      t.text :behaviors # JSON数组
      t.text :demographics # JSON数组

      # 版位信息
      t.text :placements # JSON数组: feed, story, reels, etc.
      t.string :device_platform # mobile, desktop, all
      t.string :publisher_platform # facebook, instagram, audience_network

      # 核心指标
      t.bigint :impressions, default: 0
      t.bigint :clicks, default: 0
      t.decimal :spend, precision: 15, scale: 2, default: 0
      t.bigint :reach, default: 0
      t.decimal :frequency, precision: 8, scale: 4, default: 0

      # 计算指标
      t.decimal :cpm, precision: 15, scale: 4, default: 0 # 千次展示成本
      t.decimal :cpc, precision: 15, scale: 4, default: 0 # 每次点击成本
      t.decimal :ctr, precision: 10, scale: 6, default: 0 # 点击率 %

      # 转化相关指标
      t.bigint :conversions, default: 0
      t.bigint :purchases, default: 0
      t.decimal :conversion_value, precision: 15, scale: 2, default: 0
      t.decimal :purchase_value, precision: 15, scale: 2, default: 0
      t.decimal :roas, precision: 10, scale: 4, default: 0 # 广告支出回报率
      t.decimal :cost_per_conversion, precision: 15, scale: 4, default: 0
      t.decimal :cost_per_purchase, precision: 15, scale: 4, default: 0

      # 视频相关指标
      t.bigint :video_views, default: 0
      t.bigint :video_views_3s, default: 0 # 3秒视频观看
      t.bigint :video_views_10s, default: 0 # 10秒视频观看
      t.bigint :video_views_15s, default: 0 # 15秒视频观看
      t.bigint :video_views_25_percent, default: 0
      t.bigint :video_views_50_percent, default: 0
      t.bigint :video_views_75_percent, default: 0
      t.bigint :video_views_100_percent, default: 0
      t.decimal :video_avg_play_time, precision: 10, scale: 2, default: 0

      # 互动指标
      t.bigint :likes, default: 0
      t.bigint :comments, default: 0
      t.bigint :shares, default: 0
      t.bigint :saves, default: 0
      t.bigint :follows, default: 0
      t.bigint :link_clicks, default: 0
      t.bigint :post_engagements, default: 0

      # 应用安装/事件指标
      t.bigint :app_installs, default: 0
      t.bigint :app_launches, default: 0
      t.bigint :registrations, default: 0
      t.bigint :add_to_carts, default: 0
      t.bigint :checkouts, default: 0

      # 归因信息
      t.string :attribution_window # 1d_view, 7d_click, 28d_click, etc.
      t.string :conversion_device # mobile, desktop
      t.string :conversion_action_type # purchase, install, registration, etc.

      # 受众信息
      t.string :audience_type # LOOKALIKE, CUSTOM, SAVED_AUDIENCE
      t.string :audience_name
      t.bigint :audience_size

      # 地理位置信息
      t.string :country_code # US, CN, etc.
      t.string :country_name
      t.string :region_code
      t.string :region_name
      t.string :city_name

      # 设备和平台信息
      t.string :device_type # mobile, desktop, tablet
      t.string :os_type # ios, android, windows, etc.
      t.string :browser_type

      # 广告位置和展示信息
      t.string :placement_type # feed, story, reels, etc.
      t.string :ad_position # top, side, etc.

      # 竞价信息
      t.decimal :bid_strategy_amount, precision: 15, scale: 4
      t.string :bid_strategy_type # LOWEST_COST, TARGET_COST, etc.

      # 预算信息
      t.decimal :budget_remaining, precision: 15, scale: 2
      t.decimal :budget_used_percent, precision: 5, scale: 2

      # 质量分数
      t.decimal :quality_score, precision: 5, scale: 2
      t.decimal :relevance_score, precision: 5, scale: 2

      # 时间信息
      t.datetime :campaign_start_time
      t.datetime :campaign_end_time
      t.datetime :adset_start_time
      t.datetime :adset_end_time

      # 平台特有指标 (JSON格式)
      t.text :platform_metrics

      # 原始数据和扩展字段
      t.text :raw_data # 完整的原始API响应
      t.text :custom_fields # 自定义字段
      t.text :tags # 标签数组

      # 数据质量和状态
      t.string :data_status, default: 'active' # active, deleted, invalid
      t.string :data_source # api, manual, import
      t.datetime :data_fetched_at
      t.datetime :last_updated_at

      # 去重和唯一性
      t.string :unique_key # 平台+日期+各级ID的组合哈希

      t.timestamps
    end

    # 添加索引
    # 主要查询索引
    add_index :ads_data, [:ads_account_id, :platform, :date], name: 'idx_ads_data_account_platform_date'
    add_index :ads_data, [:project_id, :platform, :date], name: 'idx_ads_data_project_platform_date'
    add_index :ads_data, [:platform, :date], name: 'idx_ads_data_platform_date'

    # 层级查询索引
    add_index :ads_data, [:campaign_id, :date], name: 'idx_ads_data_campaign_date'
    add_index :ads_data, [:adset_id, :date], name: 'idx_ads_data_adset_date'
    add_index :ads_data, [:ad_id, :date], name: 'idx_ads_data_ad_date'

    # 唯一性索引
    add_index :ads_data, :unique_key, unique: true, name: 'idx_ads_data_unique_key'

    # 时间维度索引
    add_index :ads_data, [:year, :month], name: 'idx_ads_data_year_month'
    add_index :ads_data, [:year, :quarter], name: 'idx_ads_data_year_quarter'
    add_index :ads_data, [:year, :week], name: 'idx_ads_data_year_week'

    # 状态和质量索引
    add_index :ads_data, :data_status
    add_index :ads_data, :data_fetched_at
    add_index :ads_data, :campaign_status
    add_index :ads_data, :adset_status
    add_index :ads_data, :ad_status

    # 地理位置索引
    add_index :ads_data, :country_code
    add_index :ads_data, [:country_code, :region_code], name: 'idx_ads_data_country_region'

    # 设备平台索引
    add_index :ads_data, :device_platform
    add_index :ads_data, :publisher_platform
    add_index :ads_data, :placement_type
  end
end
