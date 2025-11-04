# 指标种子数据
puts "开始创建指标配置..."

metrics_data = [
  # 数量指标 - 平台数据
  {
    display_name: '展示(平台)',
    key: 'impressions_p',
    description: '广告展示次数，统计来源于广告平台报告',
    sql_expression: 'SUM(impressions)',
    unit: '次',
    color: '#3B82F6',
    category: 'volume',
    data_source: 'platform',
    filter_min: 0,
    filter_max: nil,
    sort_order: 1
  },
  {
    display_name: '点击(平台)',
    key: 'clicks_p',
    description: '广告点击次数，统计来源于广告平台报告',
    sql_expression: 'SUM(clicks)',
    unit: '次',
    color: '#10B981',
    category: 'volume',
    data_source: 'platform',
    filter_min: 0,
    filter_max: nil,
    sort_order: 2
  },
  {
    display_name: '安装(平台)',
    key: 'installs_p',
    description: '应用安装次数，统计来源于广告平台报告',
    sql_expression: 'SUM(installs)',
    unit: '次',
    color: '#F59E0B',
    category: 'volume',
    data_source: 'platform',
    filter_min: 0,
    filter_max: nil,
    sort_order: 3
  },
  {
    display_name: '转化(平台)',
    key: 'conversions_p',
    description: '转化次数，统计来源于广告平台报告',
    sql_expression: 'SUM(conversions)',
    unit: '次',
    color: '#EF4444',
    category: 'volume',
    data_source: 'platform',
    filter_min: 0,
    filter_max: nil,
    sort_order: 4
  },

  # 数量指标 - Adjust数据
  {
    display_name: '安装(Adjust)',
    key: 'installs_a',
    description: '应用安装次数，统计来源于Adjust归因数据',
    sql_expression: 'SUM(adjust_install)',
    unit: '次',
    color: '#8B5CF6',
    category: 'volume',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 5
  },

  # 成本指标 - 平台数据
  {
    display_name: '花费(平台)',
    key: 'spend_p',
    description: '广告总花费，统计来源于广告平台报告',
    sql_expression: 'SUM(spend)',
    unit: '$',
    color: '#F59E0B',
    category: 'cost',
    data_source: 'platform',
    filter_min: 0,
    filter_max: nil,
    sort_order: 10
  },
  {
    display_name: 'CPM(平台)',
    key: 'cpm_p',
    description: '千次展示成本，计算方式：(总花费 / 展示次数) × 1000',
    sql_expression: '(SUM(spend) / NULLIF(SUM(impressions), 0)) * 1000',
    unit: '$',
    color: '#06B6D4',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 1000,
    sort_order: 11
  },
  {
    display_name: 'CPC(平台)',
    key: 'cpc_p',
    description: '单次点击成本，计算方式：总花费 / 点击次数',
    sql_expression: 'SUM(spend) / NULLIF(SUM(clicks), 0)',
    unit: '$',
    color: '#14B8A6',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 12
  },
  {
    display_name: 'CPI(平台)',
    key: 'cpi_p',
    description: '单次安装成本，计算方式：总花费 / 安装次数',
    sql_expression: 'SUM(spend) / NULLIF(SUM(installs), 0)',
    unit: '$',
    color: '#F97316',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 500,
    sort_order: 13
  },
  {
    display_name: '单次转化成本(平台)',
    key: 'cost_per_conversion_p',
    description: '单次转化成本，计算方式：总花费 / 转化次数',
    sql_expression: 'SUM(spend) / NULLIF(SUM(conversions), 0)',
    unit: '$',
    color: '#EC4899',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 1000,
    sort_order: 14
  },

  # 成本指标 - Adjust数据
  {
    display_name: '花费(Adjust)',
    key: 'spend_a',
    description: '广告总花费，统计来源于Adjust归因数据',
    sql_expression: 'SUM(adjust_spend)',
    unit: '$',
    color: '#8B5CF6',
    category: 'cost',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 15
  },
  {
    display_name: 'CPM(Adjust)',
    key: 'cpm_a',
    description: '千次展示成本，计算方式：(Adjust花费 / 展示次数) × 1000',
    sql_expression: '(SUM(adjust_spend) / NULLIF(SUM(impressions), 0)) * 1000',
    unit: '$',
    color: '#7C3AED',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 1000,
    sort_order: 16
  },
  {
    display_name: 'CPC(Adjust)',
    key: 'cpc_a',
    description: '单次点击成本，计算方式：Adjust花费 / 点击次数',
    sql_expression: 'SUM(adjust_spend) / NULLIF(SUM(clicks), 0)',
    unit: '$',
    color: '#6D28D9',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 17
  },
  {
    display_name: 'CPI(Adjust)',
    key: 'cpi_a',
    description: '单次安装成本，计算方式：Adjust花费 / Adjust安装次数',
    sql_expression: 'SUM(adjust_spend) / NULLIF(SUM(adjust_install), 0)',
    unit: '$',
    color: '#5B21B6',
    category: 'cost',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 500,
    sort_order: 18
  },

  # 率指标
  {
    display_name: 'CTR(平台)',
    key: 'ctr_p',
    description: '点击率，计算方式：(点击次数 / 展示次数) × 100%',
    sql_expression: '(SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100',
    unit: '%',
    color: '#10B981',
    category: 'rate',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 20
  },
  {
    display_name: 'CVR(平台)',
    key: 'cvr_p',
    description: '转化率，计算方式：(转化次数 / 点击次数) × 100%',
    sql_expression: '(SUM(conversions) / NULLIF(SUM(clicks), 0)) * 100',
    unit: '%',
    color: '#EF4444',
    category: 'rate',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 21
  },

  # 收入指标 - Adjust数据
  {
    display_name: '同期群收入(Adjust)',
    key: 'cohort_all_revenue_a',
    description: '同期群总收入，统计来源于Adjust归因数据',
    sql_expression: 'SUM(cohort_all_revenue)',
    unit: '$',
    color: '#10B981',
    category: 'revenue',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 30
  },
  {
    display_name: 'ROAS(Adjust)',
    key: 'roas_a',
    description: '广告支出回报率，计算方式：同期群总收入 / Adjust花费',
    sql_expression: 'SUM(cohort_all_revenue) / NULLIF(SUM(adjust_spend), 0)',
    unit: '',
    color: '#059669',
    category: 'revenue',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 31
  }
]

# D0-D6 收入指标
(0..6).each do |day|
  metrics_data << {
    display_name: "同期群收入D#{day}(Adjust)",
    key: "revenue_d#{day}_a",
    description: "D#{day}天收入，统计来源于Adjust归因数据",
    sql_expression: "SUM(all_revenue_total_d#{day})",
    unit: '$',
    color: '#10B981',
    category: 'revenue',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 40 + day
  }

  metrics_data << {
    display_name: "ROAS D#{day}(Adjust)",
    key: "roas_d#{day}_a",
    description: "D#{day}天广告支出回报率，计算方式：D#{day}收入 / Adjust花费",
    sql_expression: "SUM(all_revenue_total_d#{day}) / NULLIF(SUM(adjust_spend), 0)",
    unit: '',
    color: '#059669',
    category: 'revenue',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 50 + day
  }

  metrics_data << {
    display_name: "LTV D#{day}(Adjust)",
    key: "ltv_d#{day}_a",
    description: "D#{day}天用户生命周期价值，计算方式：D#{day}收入 / Adjust安装次数",
    sql_expression: "SUM(all_revenue_total_d#{day}) / NULLIF(SUM(adjust_install), 0)",
    unit: '$',
    color: '#3B82F6',
    category: 'ltv',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: nil,
    sort_order: 60 + day
  }
end

# D0-D6 留存指标
(0..6).each do |day|
  metrics_data << {
    display_name: "留存人数D#{day}(Adjust)",
    key: "retained_users_d#{day}_a",
    description: "D#{day}天留存用户数，统计来源于Adjust归因数据",
    sql_expression: "SUM(retained_users_d#{day})",
    unit: '人',
    color: '#8B5CF6',
    category: 'retention',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 70 + day
  }

  metrics_data << {
    display_name: "留存率D#{day}(Adjust)",
    key: "retention_rate_d#{day}_a",
    description: "D#{day}天留存率，计算方式：D#{day}留存用户数 / Adjust安装次数 × 100%",
    sql_expression: "SUM(retained_users_d#{day}) / NULLIF(SUM(adjust_install), 0) * 100",
    unit: '%',
    color: '#7C3AED',
    category: 'retention',
    data_source: 'calculated',
    filter_min: 0,
    filter_max: 100,
    sort_order: 80 + day
  }

  metrics_data << {
    display_name: "付费人数D#{day}(Adjust)",
    key: "paying_users_d#{day}_a",
    description: "D#{day}天付费用户数，统计来源于Adjust归因数据",
    sql_expression: "SUM(paying_users_d#{day})",
    unit: '人',
    color: '#F59E0B',
    category: 'retention',
    data_source: 'adjust',
    filter_min: 0,
    filter_max: nil,
    sort_order: 90 + day
  }
end

# 批量创建或更新指标
metrics_data.each do |data|
  metric = AdsMetric.find_or_initialize_by(key: data[:key])
  metric.assign_attributes(data)

  if metric.save
    puts "✓ 创建/更新指标: #{data[:display_name]} (#{data[:key]})"
  else
    puts "✗ 创建指标失败: #{data[:display_name]} - #{metric.errors.full_messages.join(', ')}"
  end
end

puts "指标配置创建完成！"
puts "总共创建了 #{AdsMetric.count} 个指标"
