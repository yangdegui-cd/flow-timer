class AdsMetric < ApplicationRecord
  # 验证
  validates :display_name, presence: true
  validates :key, presence: true, uniqueness: true
  validates :sql_expression, presence: true

  # 作用域
  scope :active, -> { where(is_active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_data_source, ->(source) { where(data_source: source) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }

  # 分类常量
  CATEGORIES = {
    volume: '数量指标',
    cost: '成本指标',
    rate: '率指标',
    revenue: '收入指标',
    retention: '留存指标',
    ltv: 'LTV指标'
  }.freeze

  DATA_SOURCES = {
    platform: '平台数据',
    adjust: 'Adjust数据',
    calculated: '计算指标'
  }.freeze

  # 按分类获取指标
  def self.by_category_grouped
    active.ordered.group_by(&:category)
  end

  # 获取SQL聚合表达式
  def aggregation_sql
    sql_expression
  end

  # 获取格式化值
  def format_value(value)
    return '0' if value.nil? || value == 0

    case unit
    when '元', '¥', '$'
      "#{unit}#{value.to_f.round(2)}"
    when '%'
      "#{value.to_f.round(2)}%"
    when '次', '人'
      value.to_i.to_s
    else
      value.to_f.round(4).to_s
    end
  end
end
