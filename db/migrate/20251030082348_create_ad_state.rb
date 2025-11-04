class CreateAdState < ActiveRecord::Migration[7.1]
  def change
    create_table :ad_states do |t|
      # 平台和账户信息
      t.string :platform, null: false, index: true, comment: '广告平台: facebook, google, tiktok等'
      t.references :ads_account, null: false, foreign_key: true, comment: '广告账户ID'

      # Campaign 层级信息
      t.string :campaign_id, null: false, index: true, comment: '广告系列ID'
      t.string :campaign_name, comment: '广告系列名称'
      t.string :campaign_effective_status, comment: '广告系列实际状态'
      t.string :campaign_objective, comment: '广告目标: APP_INSTALLS, CONVERSIONS等'
      t.string :campaign_buying_type, comment: '购买类型: AUCTION, RESERVATION'

      # Adset 层级信息
      t.string :adset_id, null: false, index: true, comment: '广告组ID'
      t.string :adset_name, comment: '广告组名称'
      t.string :adset_effective_status, comment: '广告组实际状态'

      # Ad 层级信息
      t.string :ad_id, null: false, index: true, comment: '广告ID'
      t.string :ad_name, comment: '广告名称'
      t.string :ad_effective_status, comment: '广告实际状态'

      # 综合状态（整体是否投放中）
      t.boolean :is_active, default: false, comment: '是否正在投放'

      # 预算信息（Campaign 或 Adset 级别）
      t.decimal :daily_budget, precision: 15, scale: 2, comment: '每日预算（元）'
      t.decimal :lifetime_budget, precision: 15, scale: 2, comment: '总预算（元）'
      t.string :budget_remaining, comment: '剩余预算'
      t.string :spend_cap, comment: '花费上限'

      # 出价信息（Adset 级别）
      t.decimal :bid_amount, precision: 15, scale: 2, comment: '出价金额（元）'
      t.string :bid_strategy, comment: '出价策略'
      t.string :optimization_goal, comment: '优化目标'
      t.string :billing_event, comment: '计费事件'

      # 定向信息（Adset 级别）
      t.json :targeting, comment: '定向设置（JSON）'

      # 创意信息（Ad 级别）
      t.string :creative_id, comment: '创意ID'
      t.string :creative_name, comment: '创意名称'

      # 素材信息（Ad 级别 - 重点）
      t.string :image_url, comment: '图片素材URL'
      t.string :image_hash, comment: '图片哈希'
      t.string :video_id, comment: '视频ID'
      t.string :video_url, comment: '视频URL'
      t.string :thumbnail_url, comment: '视频缩略图URL'

      # 广告文案（Ad 级别）
      t.text :ad_title, comment: '广告标题'
      t.text :ad_body, comment: '广告正文'
      t.text :ad_description, comment: '广告描述'
      t.string :call_to_action, comment: '行动号召按钮'
      t.string :link_url, comment: '落地页链接'

      # 时间信息
      t.datetime :start_time, comment: '开始时间'
      t.datetime :stop_time, comment: '结束时间'
      t.datetime :platform_created_time, comment: '平台创建时间'
      t.datetime :platform_updated_time, comment: '平台更新时间'


      # 数据同步信息
      t.datetime :synced_at, comment: '最后同步时间'
      t.string :sync_status, default: 'pending', comment: '同步状态: pending, synced, error'
      t.text :sync_error, comment: '同步错误信息'

      t.timestamps
    end

    # 使用 MD5 哈希作为唯一键（避免索引过长）
    add_column :ad_states, :unique_key, :string, limit: 32, comment: 'MD5哈希唯一键'
    add_index :ad_states, :unique_key, unique: true

    # 查询索引
    add_index :ad_states, [:platform, :campaign_id], name: 'idx_ad_states_platform_campaign'
    add_index :ad_states, [:platform, :adset_id], name: 'idx_ad_states_platform_adset'
    add_index :ad_states, [:platform, :ad_id], name: 'idx_ad_states_platform_ad'
    # 查询索引
    add_index :ad_states, [:platform, :campaign_name], name: 'idx_ad_states_platform_campaign_name'
    add_index :ad_states, [:platform, :adset_name], name: 'idx_ad_states_platform_adset_name'
    add_index :ad_states, [:platform, :ad_name], name: 'idx_ad_states_platform_ad_name'
    add_index :ad_states, :creative_id
    add_index :ad_states, :synced_at
    add_index :ad_states, :is_active
  end
end
