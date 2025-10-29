# 指标种子数据
puts "开始创建指标配置..."

metrics_data = [
  # 数量指标 - 平台数据
  {
    name_cn: '展示(平台)',
    name_en: 'impressions_p',
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
    name_cn: '点击(平台)',
    name_en: 'clicks_p',
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
    name_cn: '安装(平台)',
    name_en: 'installs_p',
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
    name_cn: '转化(平台)',
    name_en: 'conversions_p',
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
    name_cn: '安装(Adjust)',
    name_en: 'installs_a',
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
    name_cn: '花费(平台)',
    name_en: 'spend_p',
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
    name_cn: 'CPM(平台)',
    name_en: 'cpm_p',
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
    name_cn: 'CPC(平台)',
    name_en: 'cpc_p',
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
    name_cn: 'CPI(平台)',
    name_en: 'cpi_p',
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
    name_cn: '单次转化成本(平台)',
    name_en: 'cost_per_conversion_p',
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
    name_cn: '花费(Adjust)',
    name_en: 'spend_a',
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
    name_cn: 'CPM(Adjust)',
    name_en: 'cpm_a',
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
    name_cn: 'CPC(Adjust)',
    name_en: 'cpc_a',
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
    name_cn: 'CPI(Adjust)',
    name_en: 'cpi_a',
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
    name_cn: 'CTR(平台)',
    name_en: 'ctr_p',
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
    name_cn: 'CVR(平台)',
    name_en: 'cvr_p',
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
    name_cn: '同期群收入(Adjust)',
    name_en: 'cohort_all_revenue_a',
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
    name_cn: 'ROAS(Adjust)',
    name_en: 'roas_a',
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
    name_cn: "同期群收入D#{day}(Adjust)",
    name_en: "revenue_d#{day}_a",
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
    name_cn: "ROAS D#{day}(Adjust)",
    name_en: "roas_d#{day}_a",
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
    name_cn: "LTV D#{day}(Adjust)",
    name_en: "ltv_d#{day}_a",
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
    name_cn: "留存人数D#{day}(Adjust)",
    name_en: "retained_users_d#{day}_a",
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
    name_cn: "留存率D#{day}(Adjust)",
    name_en: "retention_rate_d#{day}_a",
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
    name_cn: "付费人数D#{day}(Adjust)",
    name_en: "paying_users_d#{day}_a",
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
  metric = Metric.find_or_initialize_by(name_en: data[:name_en])
  metric.assign_attributes(data)

  if metric.save
    puts "✓ 创建/更新指标: #{data[:name_cn]} (#{data[:name_en]})"
  else
    puts "✗ 创建指标失败: #{data[:name_cn]} - #{metric.errors.full_messages.join(', ')}"
  end
end

puts "指标配置创建完成！"
puts "总共创建了 #{Metric.count} 个指标"
