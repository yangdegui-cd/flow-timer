class CreateAdsDimensions < ActiveRecord::Migration[7.1]
  def change
    create_table :ads_dimensions do |t|
      t.string :display_name
      t.string :name
      t.string :column
      t.string :category
      t.string :description
      t.integer :sort_order, default: 0
      t.boolean :is_active, default: true
      t.json :display_config, comment: '前端展示配置（宽度、对齐方式等）'
      t.timestamps
    end

    add_index :ads_dimensions, :name, unique: true
    add_index :ads_dimensions, :column, unique: true

    if AdsDimension.all.empty?
      AdsDimension.insert_all!(
        [
          { name: 'quarter', display_name: '季度', column: 'quarter', category: 'time', description: '季度维度', display_config: { width: 120, align: 'center', sortable: true, frozen: true }.to_json },
          { name:'month', display_name: '月', column:'month', category: 'time', description: '月维度', display_config: { width: 120, align: 'center', sortable: true, frozen: true }.to_json },
          { name: 'week', display_name: '周', column: 'week', category: 'time', description: '周维度', display_config: { width: 120, align: 'center', sortable: true, frozen: true }.to_json },
          { name: 'date', display_name: '日期', column: 'date', category: 'time', description: '日期维度', display_config: { width: 120, align: 'center', sortable: true, frozen: true }.to_json },
          { name: 'hour', display_name: '小时', column: 'datetime', category: 'time', description: '小时维度', display_config: { width: 150, align: 'center', sortable: true, frozen: true }.to_json },
          { name: 'project_id', display_name: '项目', column: 'project_id', category: 'dimension', description: '项目维度', display_config: { width: 150, align: 'left', sortable: true }.to_json },
          { name: 'platform', display_name: '平台', column: 'platform', category: 'dimension', description: '平台维度', display_config: { width: 100, align: 'center', sortable: true }.to_json },
          { name: 'ads_account_id', display_name: '账号', column: 'ads_account_id', category: 'dimension', description: '账号维度', display_config: { width: 180, align: 'left', sortable: true }.to_json },
          { name: 'campaign_name', display_name: '广告系列', column: 'campaign_name', category: 'dimension', description: '广告系列维度', display_config: { width: 200, align: 'left', sortable: true, ellipsis: true }.to_json },
          { name: 'adset_name', display_name: '广告组', column: 'adset_name', category: 'dimension', description: '广告组维度', display_config: { width: 200, align: 'left', sortable: true, ellipsis: true }.to_json },
          { name: 'ad_name', display_name: '广告', column: 'ad_name', category: 'dimension', description: '广告维度', display_config: { width: 200, align: 'left', sortable: true, ellipsis: true }.to_json }
        ])
    end
  end


  def down
    drop_table :ads_dimensions
  end
end
