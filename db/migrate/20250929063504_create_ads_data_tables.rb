class CreateAdsDataTables < ActiveRecord::Migration[7.1]
  def change
    # 广告活动表 (Campaign)
    create_table :ads_campaigns do |t|
      # 基本信息
      t.string :campaign_id, null: false # 平台活动ID
      t.string :name, null: false
      t.text :description
      t.references :ads_account, null: false, foreign_key: true
      t.string :platform, null: false # facebook, google, twitter, tiktok

      # 状态和配置
      t.string :status # ACTIVE, PAUSED, DELETED
      t.string :objective # 广告目标，不同平台会有不同值
      t.string :buying_type # AUCTION, RESERVATION
      t.decimal :daily_budget, precision: 15, scale: 2
      t.decimal :lifetime_budget, precision: 15, scale: 2
      t.decimal :bid_amount, precision: 15, scale: 2

      # 时间相关
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :platform_created_time
      t.datetime :platform_updated_time

      # 平台特有数据 (JSON格式)
      t.text :platform_data

      # 同步信息
      t.datetime :last_sync_at
      t.string :sync_status, default: 'pending'
      t.text :sync_error

      t.timestamps
    end

    # 广告组表 (Ad Set)
    create_table :ads_ad_sets do |t|
      # 基本信息
      t.string :adset_id, null: false # 平台广告组ID
      t.string :name, null: false
      t.references :ads_campaign, null: false, foreign_key: true
      t.references :ads_account, null: false, foreign_key: true
      t.string :platform, null: false

      # 状态和配置
      t.string :status # ACTIVE, PAUSED, DELETED
      t.string :optimization_goal # 优化目标
      t.string :billing_event # 计费事件
      t.decimal :bid_amount, precision: 15, scale: 2
      t.decimal :daily_budget, precision: 15, scale: 2

      # 受众定位信息 (JSON格式)
      t.text :targeting
      t.text :placement_data # 版位信息

      # 时间相关
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :platform_created_time
      t.datetime :platform_updated_time

      # 平台特有数据
      t.text :platform_data

      # 同步信息
      t.datetime :last_sync_at
      t.string :sync_status, default: 'pending'
      t.text :sync_error

      t.timestamps
    end

    # 广告表 (Ad)
    create_table :ads_ads do |t|
      # 基本信息
      t.string :ad_id, null: false # 平台广告ID
      t.string :name, null: false
      t.references :ads_ad_set, null: false, foreign_key: true
      t.references :ads_campaign, null: false, foreign_key: true
      t.references :ads_account, null: false, foreign_key: true
      t.string :platform, null: false

      # 状态
      t.string :status # ACTIVE, PAUSED, DELETED
      t.string :configured_status # 配置状态
      t.string :effective_status # 实际状态

      # 广告创意信息
      t.text :creative_data # 创意数据 (JSON格式)
      t.string :ad_format # 广告格式

      # 时间相关
      t.datetime :platform_created_time
      t.datetime :platform_updated_time

      # 平台特有数据
      t.text :platform_data

      # 同步信息
      t.datetime :last_sync_at
      t.string :sync_status, default: 'pending'
      t.text :sync_error

      t.timestamps
    end

    # 广告洞察数据表 (Insights)
    create_table :ads_insights do |t|
      # 关联信息
      t.references :ads_account, null: false, foreign_key: true
      t.references :ads_campaign, null: true, foreign_key: true
      t.references :ads_ad_set, null: true, foreign_key: true
      t.references :ads_ad, null: true, foreign_key: true
      t.string :platform, null: false

      # 时间维度
      t.date :date_start
      t.date :date_stop
      t.string :time_increment # day, week, month

      # 核心指标 (所有平台通用)
      t.bigint :impressions, default: 0
      t.bigint :clicks, default: 0
      t.decimal :spend, precision: 15, scale: 2, default: 0
      t.bigint :reach, default: 0
      t.bigint :frequency, default: 0
      t.decimal :cpm, precision: 15, scale: 4, default: 0 # 千次展示成本
      t.decimal :cpc, precision: 15, scale: 4, default: 0 # 每次点击成本
      t.decimal :ctr, precision: 10, scale: 6, default: 0 # 点击率

      # 转化相关指标
      t.bigint :conversions, default: 0
      t.decimal :conversion_rate, precision: 10, scale: 6, default: 0
      t.decimal :cost_per_conversion, precision: 15, scale: 4, default: 0
      t.decimal :conversion_value, precision: 15, scale: 2, default: 0
      t.decimal :roas, precision: 10, scale: 4, default: 0 # 广告支出回报率

      # 视频相关指标
      t.bigint :video_views, default: 0
      t.bigint :video_views_25_percent, default: 0
      t.bigint :video_views_50_percent, default: 0
      t.bigint :video_views_75_percent, default: 0
      t.bigint :video_views_100_percent, default: 0

      # 互动指标
      t.bigint :likes, default: 0
      t.bigint :comments, default: 0
      t.bigint :shares, default: 0
      t.bigint :saves, default: 0

      # 平台特有指标 (JSON格式存储)
      t.text :platform_metrics

      # 原始数据备份
      t.text :raw_data

      # 同步信息
      t.datetime :synced_at

      t.timestamps
    end

    # 添加索引
    add_index :ads_campaigns, [:ads_account_id, :platform, :campaign_id], unique: true, name: 'index_campaigns_on_account_platform_id'
    add_index :ads_campaigns, [:platform, :status]
    add_index :ads_campaigns, :last_sync_at

    add_index :ads_ad_sets, [:ads_account_id, :platform, :adset_id], unique: true, name: 'index_adsets_on_account_platform_id'
    add_index :ads_ad_sets, [:ads_campaign_id, :status]
    add_index :ads_ad_sets, :last_sync_at

    add_index :ads_ads, [:ads_account_id, :platform, :ad_id], unique: true, name: 'index_ads_on_account_platform_id'
    add_index :ads_ads, [:ads_ad_set_id, :status]
    add_index :ads_ads, :last_sync_at

    add_index :ads_insights, [:ads_account_id, :platform, :date_start, :date_stop], name: 'index_insights_on_account_platform_dates'
    add_index :ads_insights, [:ads_campaign_id, :date_start]
    add_index :ads_insights, [:ads_ad_set_id, :date_start]
    add_index :ads_insights, [:ads_ad_id, :date_start]
    add_index :ads_insights, :synced_at
  end
end
