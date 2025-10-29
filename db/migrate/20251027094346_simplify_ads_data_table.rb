class SimplifyAdsDataTable < ActiveRecord::Migration[7.1]
  def up
    # 添加新的 os_name 列
    add_column :ads_data, :os_name, :string unless column_exists?(:ads_data, :os_name)

    # 添加 installs 和 revenue 列(如果不存在)
    add_column :ads_data, :installs, :bigint, default: 0 unless column_exists?(:ads_data, :installs)
    add_column :ads_data, :revenue, :decimal, precision: 15, scale: 2, default: 0 unless column_exists?(:ads_data, :revenue)

    # 添加 datetime 和 day_of_week 列
    add_column :ads_data, :datetime, :datetime unless column_exists?(:ads_data, :datetime)
    add_column :ads_data, :day_of_week, :string unless column_exists?(:ads_data, :day_of_week)

    # 添加索引
    add_index :ads_data, :os_name unless index_exists?(:ads_data, :os_name)

    # 删除不需要的列
    remove_columns_if_exist(:ads_data, [
      # 活动详细信息
      :campaign_status, :campaign_objective, :buying_type,
      :campaign_daily_budget, :campaign_lifetime_budget,
      :campaign_start_time, :campaign_end_time,

      # 广告组详细信息
      :adset_status, :optimization_goal, :billing_event,
      :adset_daily_budget, :bid_amount,
      :adset_start_time, :adset_end_time,

      # 广告详细信息
      :ad_status, :ad_format, :ad_creative_data,

      # 定向信息
      :targeting_data, :age_min, :age_max, :gender,
      :countries, :regions, :cities, :interests, :behaviors, :demographics,

      # 版位信息
      :placements, :device_platform, :publisher_platform, :placement_type,
      :ad_position,

      # 不需要的指标
      :reach, :frequency, :cpm, :cpc, :ctr,
      :purchases, :conversion_value, :purchase_value,
      :roas, :cost_per_conversion, :cost_per_purchase,

      # 视频相关
      :video_views, :video_views_3s, :video_views_10s, :video_views_15s,
      :video_views_25_percent, :video_views_50_percent,
      :video_views_75_percent, :video_views_100_percent,
      :video_avg_play_time,

      # 互动指标
      :likes, :comments, :shares, :saves, :follows,
      :link_clicks, :post_engagements,

      # 应用指标(保留 installs,删除其他)
      :app_launches, :registrations, :add_to_carts, :checkouts,

      # 归因信息
      :attribution_window, :conversion_device, :conversion_action_type,

      # 受众信息
      :audience_type, :audience_name, :audience_size,

      # 地理位置(不需要)
      :country_code, :country_name, :region_code, :region_name, :city_name,

      # 设备和平台(用 os_name 替代)
      :device_type, :os_type, :browser_type, :operating_system,

      # 竞价信息
      :bid_strategy_amount, :bid_strategy_type,

      # 预算信息
      :budget_remaining, :budget_used_percent,

      # 质量分数
      :quality_score, :relevance_score,

      # 平台特有指标
      :platform_metrics,

      # 其他
      :custom_fields, :tags, :last_updated_at,

      # 创意相关
      :creative_id, :creative_name
    ])

    # 删除不需要的索引
    remove_index_if_exists(:ads_data, name: 'idx_ads_data_country_region')
    remove_index_if_exists(:ads_data, :country_code)
    remove_index_if_exists(:ads_data, :device_platform)
    remove_index_if_exists(:ads_data, :publisher_platform)
    remove_index_if_exists(:ads_data, :placement_type)
    remove_index_if_exists(:ads_data, :campaign_status)
    remove_index_if_exists(:ads_data, :adset_status)
    remove_index_if_exists(:ads_data, :ad_status)
  end

  def down
    # 回滚操作
    remove_column :ads_data, :os_name if column_exists?(:ads_data, :os_name)
    remove_column :ads_data, :installs if column_exists?(:ads_data, :installs)
    remove_column :ads_data, :revenue if column_exists?(:ads_data, :revenue)
    remove_column :ads_data, :datetime if column_exists?(:ads_data, :datetime)
    remove_column :ads_data, :day_of_week if column_exists?(:ads_data, :day_of_week)
  end

  private

  def remove_columns_if_exist(table, columns)
    columns.each do |column|
      remove_column table, column if column_exists?(table, column)
    end
  end

  def remove_index_if_exists(table, options)
    remove_index table, options if index_exists?(table, options)
  end
end
