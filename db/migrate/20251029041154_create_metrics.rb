class CreateMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :metrics do |t|
      t.string :name_cn, null: false, comment: '中文名称'
      t.string :name_en, null: false, comment: '英文名称'
      t.text :description, comment: '描述'
      t.text :sql_expression, null: false, comment: 'SQL表达式'
      t.string :unit, comment: '单位'
      t.string :color, comment: '展示颜色'
      t.decimal :filter_max, precision: 15, scale: 2, comment: '筛选最大值'
      t.decimal :filter_min, precision: 15, scale: 2, comment: '筛选最小值'
      t.string :category, comment: '分类'
      t.string :data_source, comment: '数据源：platform(平台数据), adjust(Adjust数据), calculated(计算指标)'
      t.integer :sort_order, default: 0, comment: '排序'
      t.boolean :is_active, default: true, comment: '是否启用'

      t.timestamps
    end

    add_index :metrics, :name_en, unique: true
    add_index :metrics, :category
    add_index :metrics, :data_source
    add_index :metrics, :is_active
  end
end
