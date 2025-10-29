class CreateAdsAdjustData < ActiveRecord::Migration[7.1]
  def change
    create_table :ads_adjust_data do |t|
      # 基础关联信息
      t.references :project, null: false, foreign_key: true, comment: '项目ID'
      t.string :platform, default: 'adjust', null: false, comment: '平台标识'

      # 时间维度 - 与 ads_data 保持一致
      t.date :date, null: false, comment: '日期'
      t.string :hour, comment: '小时 00-23'
      t.datetime :datetime, comment: '精确到小时的时间'

      # Adjust 层级结构 - 对应 ads_data 的 campaign/adset/ad
      t.string :campaign_network, comment: '推广活动网络（对应 campaign_name）'
      t.string :campaign_network_id, comment: '推广活动网络ID（对应 campaign_id）'
      t.string :adgroup_network, comment: '广告组网络（对应 adset_name）'
      t.string :adgroup_network_id, comment: '广告组网络ID（对应 adset_id）'
      t.string :creative_network, comment: '创意网络（对应 ad_name/creative_name）'
      t.string :creative_network_id, comment: '创意网络ID（对应 ad_id/creative_id）'

      # 设备和平台信息 - 与 ads_data 保持一致
      t.string :os_name, comment: '操作系统名称（对应 operating_system）'

      # Adjust 核心指标
      t.bigint :installs, default: 0, comment: '安装数'
      t.bigint :network_clicks, default: 0, comment: '网络点击数（对应 clicks）'
      t.bigint :network_impressions, default: 0, comment: '网络展示数（对应 impressions）'
      t.decimal :cost, precision: 15, scale: 2, default: 0, comment: '成本（对应 spend）'

      # 群组收入
      t.decimal :cohort_all_revenue, precision: 15, scale: 2, default: 0, comment: '群组总收入'

      # 分天收入指标 D0-D6
      t.decimal :all_revenue_total_d0, precision: 15, scale: 2, default: 0, comment: 'D0 总收入'
      t.decimal :all_revenue_total_d1, precision: 15, scale: 2, default: 0, comment: 'D1 总收入'
      t.decimal :all_revenue_total_d2, precision: 15, scale: 2, default: 0, comment: 'D2 总收入'
      t.decimal :all_revenue_total_d3, precision: 15, scale: 2, default: 0, comment: 'D3 总收入'
      t.decimal :all_revenue_total_d4, precision: 15, scale: 2, default: 0, comment: 'D4 总收入'
      t.decimal :all_revenue_total_d5, precision: 15, scale: 2, default: 0, comment: 'D5 总收入'
      t.decimal :all_revenue_total_d6, precision: 15, scale: 2, default: 0, comment: 'D6 总收入'

      # 分天留存用户数 D0-D6
      t.bigint :retained_users_d0, default: 0, comment: 'D0 留存用户数'
      t.bigint :retained_users_d1, default: 0, comment: 'D1 留存用户数'
      t.bigint :retained_users_d2, default: 0, comment: 'D2 留存用户数'
      t.bigint :retained_users_d3, default: 0, comment: 'D3 留存用户数'
      t.bigint :retained_users_d4, default: 0, comment: 'D4 留存用户数'
      t.bigint :retained_users_d5, default: 0, comment: 'D5 留存用户数'
      t.bigint :retained_users_d6, default: 0, comment: 'D6 留存用户数'

      # 分天付费用户数 D0-D6
      t.bigint :paying_users_d0, default: 0, comment: 'D0 付费用户数'
      t.bigint :paying_users_d1, default: 0, comment: 'D1 付费用户数'
      t.bigint :paying_users_d2, default: 0, comment: 'D2 付费用户数'
      t.bigint :paying_users_d3, default: 0, comment: 'D3 付费用户数'
      t.bigint :paying_users_d4, default: 0, comment: 'D4 付费用户数'
      t.bigint :paying_users_d5, default: 0, comment: 'D5 付费用户数'
      t.bigint :paying_users_d6, default: 0, comment: 'D6 付费用户数'

      # 数据质量和状态
      t.string :data_status, default: 'active', comment: 'active, deleted, invalid'
      t.string :data_source, default: 'adjust_api', comment: 'adjust_api, manual, import'
      t.datetime :data_fetched_at, comment: '数据拉取时间'

      # 去重和唯一性
      t.string :unique_key, comment: '唯一标识：project_id + date + hour + dimensions 的组合哈希'

      # 原始数据
      t.text :raw_data, comment: '完整的原始API响应（JSON）'

      t.timestamps
    end

    # 添加索引
    # 主要查询索引
    add_index :ads_adjust_data, [:project_id, :date], name: 'idx_ads_adjust_data_project_date'
    add_index :ads_adjust_data, [:project_id, :date, :hour], name: 'idx_ads_adjust_data_project_date_hour'

    # 时间维度索引
    add_index :ads_adjust_data, :date
    add_index :ads_adjust_data, :datetime

    # 层级查询索引（用于与 ads_data 匹配）
    add_index :ads_adjust_data, :campaign_network, name: 'idx_ads_adjust_data_campaign'
    add_index :ads_adjust_data, :adgroup_network, name: 'idx_ads_adjust_data_adgroup'
    add_index :ads_adjust_data, :creative_network, name: 'idx_ads_adjust_data_creative'

    # 设备和平台索引
    add_index :ads_adjust_data, :os_name

    # 状态索引
    add_index :ads_adjust_data, :data_status
    add_index :ads_adjust_data, :data_fetched_at
  end
end
