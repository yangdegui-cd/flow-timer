class AddDetailedDimensionsToAdsData < ActiveRecord::Migration[7.1]
  def change
    # 支持小时级别时间粒度
    add_column :ads_data, :datetime, :datetime, comment: '精确到小时的时间'
    add_column :ads_data, :hour_of_day, :integer, comment: '一天中的小时 0-23'
    add_column :ads_data, :day_of_week, :string, comment: '星期几'

    # 更多设备维度
    add_column :ads_data, :impression_device, :string, comment: '展示设备'
    add_column :ads_data, :device_model, :string, comment: '设备型号'
    add_column :ads_data, :operating_system, :string, comment: '操作系统'
    add_column :ads_data, :browser_name, :string, comment: '浏览器名称'
    add_column :ads_data, :carrier, :string, comment: '运营商'

    # 更多地理维度
    add_column :ads_data, :dma_code, :string, comment: 'DMA区域代码'
    add_column :ads_data, :postal_code, :string, comment: '邮政编码'

    # 行为和用户维度
    add_column :ads_data, :user_bucket, :string, comment: '用户分桶'
    add_column :ads_data, :click_device, :string, comment: '点击设备'
    add_column :ads_data, :age_range, :string, comment: '年龄段'

    # 内容和创意维度
    add_column :ads_data, :call_to_action, :string, comment: '行动号召按钮'
    add_column :ads_data, :link_click_destination, :string, comment: '链接点击目标'
    add_column :ads_data, :creative_type, :string, comment: '创意类型'

    # 更多转化类型
    add_column :ads_data, :purchase_conversions, :bigint, default: 0, comment: '购买转化'
    add_column :ads_data, :add_to_cart_conversions, :bigint, default: 0, comment: '加购转化'
    add_column :ads_data, :lead_conversions, :bigint, default: 0, comment: '潜客转化'
    add_column :ads_data, :app_install_conversions, :bigint, default: 0, comment: '应用安装转化'

    # 额外互动指标
    add_column :ads_data, :page_likes, :bigint, default: 0, comment: '页面赞'
    add_column :ads_data, :post_shares, :bigint, default: 0, comment: '帖子分享'
    add_column :ads_data, :video_play_actions, :bigint, default: 0, comment: '视频播放操作'

    # 移除计算指标列（如果存在）- 这些将动态计算
    # remove_column :ads_data, :ctr, :decimal if column_exists?(:ads_data, :ctr)
    # remove_column :ads_data, :cpm, :decimal if column_exists?(:ads_data, :cpm)
    # remove_column :ads_data, :cpc, :decimal if column_exists?(:ads_data, :cpc)
    # remove_column :ads_data, :roas, :decimal if column_exists?(:ads_data, :roas)

    # 添加索引以提升查询性能
    add_index :ads_data, :datetime, comment: '时间索引'
    add_index :ads_data, :hour_of_day, comment: '小时索引'
    add_index :ads_data, :day_of_week, comment: '星期索引'
    add_index :ads_data, :device_model, comment: '设备型号索引'
    add_index :ads_data, :operating_system, comment: '操作系统索引'
    add_index :ads_data, :age_range, comment: '年龄段索引'
    add_index :ads_data, :creative_type, comment: '创意类型索引'

    # 组合索引
    add_index :ads_data, [:country_code, :region_code], comment: '地理位置组合索引'
    add_index :ads_data, [:device_platform, :operating_system], comment: '设备平台组合索引'
    add_index :ads_data, [:datetime, :campaign_id], comment: '时间活动组合索引'
  end
end
