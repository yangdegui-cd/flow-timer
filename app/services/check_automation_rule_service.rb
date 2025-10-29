# frozen_string_literal: true

class CheckAutomationRuleService
  attr_reader :rule, :project

  def initialize(automation_rule)
    @rule = automation_rule
    @project = automation_rule.project
  end

  # 执行规则检查，返回符合条件的广告数据
  def execute
    matched_ads = find_matching_ads

    if matched_ads.any?
      Rails.logger.info "Rule #{rule.id} matched #{matched_ads.count} ads"
      matched_ads.each do |ad_info|
        begin
          AutomationLog.create({
                                 project: project,
                                 action_type: "规则触发",
                                 action: "自动化规则触发",
                                 duration: 0,
                                 status: "success",
                                 remark: ad_info.merge({
                                                         action: rule.action,
                                                         rule: rule.as_json,
                                                         project_name: project.name,
                                                         time_zone: get_timezone,
                                                         ads_account_name: AdsAccount.find(ad_info['ads_account_id']).name
                                                       }),
                               })
        rescue => e
          Rails.logger.error "Failed to create automation log: #{e.message}"
        end
      end
      execute_action(matched_ads)
    else
      Rails.logger.info "Rule #{rule.id} matched no ads"
    end

    matched_ads
  end

  # 构建完整的SQL查询
  def build_query
    <<~SQL
      SELECT #{group_by_rule.join(', ')}
      FROM ads_merge_data
      WHERE #{condition_time_range}
        AND #{condition_project}
        AND (#{condition_by_rule})
      GROUP BY #{group_by_rule.join(', ')}
      HAVING #{having_conditions}
    SQL
  end

  # 1. 根据 time_granularity 以及 time_range 计算出具体的开始时间
  def condition_time_range
    timezone = get_timezone
    current_time = Time.current.in_time_zone(timezone)

    case rule.time_granularity
    when 'day'
      # 最近N天：根据 date 字段计算
      start_date = current_time - rule.time_range.days
      end_date = current_time

      "date >= '#{start_date.to_date}' AND date <= '#{end_date.to_date}'"
    when 'hour'
      # 最近N小时：根据 date 和 hour 字段计算
      start_time = current_time - rule.time_range.hours
      end_time = current_time

      build_hour_range_condition(start_time, end_time)
    else
      raise "Unsupported time_granularity: #{rule.time_granularity}"
    end
  end

  # 2. 处理 condition_group 条件，拼接出一个 condition 语句
  def condition_by_rule
    process_condition_group(rule.condition_group)
  end

  # 分组字段
  def group_by_rule
    %w[platform project_id ads_account_id campaign_name adset_name ad_name]
  end

  private

  # 查找符合条件的广告数据
  def find_matching_ads
    query = build_query
    Rails.logger.info "Executing query: #{query}"

    result = AdsData.connection.execute(query)
    result.map { |row| group_by_rule.zip(row).to_h }
  end

  # 构建小时范围条件
  def build_hour_range_condition(start_time, end_time)
    start_date = start_time.to_date
    end_date = end_time.to_date
    start_hour = start_time.hour
    end_hour = end_time.hour

    if start_date == end_date
      # 同一天内
      "date = '#{start_date}' AND hour >= '#{format_hour(start_hour)}' AND hour <= '#{format_hour(end_hour)}'"
    else
      # 跨天处理
      conditions = []

      # 第一天：从 start_hour 到 23
      conditions << "(date = '#{start_date}' AND hour >= '#{format_hour(start_hour)}')"

      # 中间的完整天数
      if (end_date - start_date).to_i > 1
        middle_start = start_date + 1.day
        middle_end = end_date - 1.day
        conditions << "(date >= '#{middle_start}' AND date <= '#{middle_end}')"
      end

      # 最后一天：从 00 到 end_hour
      conditions << "(date = '#{end_date}' AND hour <= '#{format_hour(end_hour)}')"

      "(#{conditions.join(' OR ')})"
    end
  end

  # 格式化小时为两位数字符串 (00-23)
  def format_hour(hour)
    hour.to_s.rjust(2, '0')
  end

  # 构建项目条件
  def condition_project
    "project_id = #{project.id}"
  end

  # 递归处理条件组
  def process_condition_group(group)
    return '1=1' if group.blank? || group['children'].blank?

    logic_operator = group['logic'] == 'OR' ? 'OR' : 'AND'
    conditions = []

    group['children'].each do |child|
      if child['type'] == 'group'
        # 递归处理子组
        conditions << "(#{process_condition_group(child)})"
      elsif child['type'] == 'condition'
        # 处理单个条件
        condition_str = process_single_condition(child)
        conditions << condition_str if condition_str != '1=1'
      end
    end

    conditions.any? ? conditions.join(" #{logic_operator} ") : '1=1'
  end

  # 处理单个条件
  def process_single_condition(condition)
    metric = condition['metric']
    operator = condition['operator']
    value = condition['value']
    metric_type = condition['metricType']

    # 映射前端字段名到数据库字段名
    db_field = map_metric_to_db_field(metric)

    case metric_type
    when 'numeric'
      # 数值类型条件将在 HAVING 子句中处理，这里返回占位符
      '1=1'
    when 'string'
      # 字符串类型条件直接在 WHERE 中处理
      build_string_condition(db_field, operator, value)
    else
      '1=1'
    end
  end

  # 构建 HAVING 子句条件（处理聚合后的数值条件）
  def having_conditions
    conditions = extract_numeric_conditions(rule.condition_group)
    conditions.any? ? conditions.join(' AND ') : '1=1'
  end

  # 提取数值类型条件
  def extract_numeric_conditions(group, parent_logic = 'AND')
    return [] if group.blank? || group['children'].blank?

    current_logic = group['logic'] == 'OR' ? 'OR' : 'AND'
    conditions = []

    group['children'].each do |child|
      if child['type'] == 'group'
        # 递归处理子组
        sub_conditions = extract_numeric_conditions(child, current_logic)
        conditions << "(#{sub_conditions.join(" #{current_logic} ")})" if sub_conditions.any?
      elsif child['type'] == 'condition' && child['metricType'] == 'numeric'
        # 处理数值条件
        conditions << build_numeric_condition(child)
      end
    end

    conditions
  end

  # 构建数值条件（用于 HAVING 子句）
  # 注意：因为是聚合运算，所以数值类型的字段要进行 SUM 后再运算
  def build_numeric_condition(condition)
    metric = condition['metric']
    operator = condition['operator']
    value = condition['value']

    db_field = map_metric_to_db_field(metric)
    sql_operator = map_operator_to_sql(operator)

    # 需要 SUM 聚合的数值字段（累计指标）
    sum_fields = %w[
      impressions clicks spend reach conversions purchases
      video_views video_views_3s video_views_10s video_views_15s
      likes comments shares saves follows
      link_clicks post_engagements app_installs app_launches
      registrations add_to_carts checkouts
    ]

    # 需要从基础指标计算的字段
    calculated_fields = {
      'cpm' => '(SUM(spend) / NULLIF(SUM(impressions), 0)) * 1000',
      'cpc' => 'SUM(spend) / NULLIF(SUM(clicks), 0)',
      'cpi' => 'SUM(spend) / NULLIF(SUM(app_installs), 0)',
      'cost_per_purchase' => 'SUM(spend) / NULLIF(SUM(purchases), 0)',
      'ctr' => '(SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100',
      'cvr' => '(SUM(conversions) / NULLIF(SUM(clicks), 0)) * 100',
      'cost_per_conversion' => 'SUM(spend) / NULLIF(SUM(conversions), 0)',
      'roas' => 'SUM(conversion_value) / NULLIF(SUM(spend), 0)'
    }

    # 需要 AVG 聚合的字段（真正的平均值指标）
    avg_fields = %w[
      frequency quality_score relevance_score
      video_avg_play_time budget_used_percent
    ]

    if calculated_fields.key?(db_field)
      # 计算型指标：从基础指标计算
      "(#{calculated_fields[db_field]}) #{sql_operator} #{value}"
    elsif sum_fields.include?(db_field)
      # 累计型指标：直接 SUM
      "SUM(#{db_field}) #{sql_operator} #{value}"
    elsif avg_fields.include?(db_field)
      # 平均值指标：使用 AVG
      "AVG(#{db_field}) #{sql_operator} #{value}"
    else
      # 默认使用 SUM
      "SUM(#{db_field}) #{sql_operator} #{value}"
    end
  end

  # 构建字符串条件
  def build_string_condition(field, operator, value)
    sanitized_value = sanitize_sql_value(value)

    case operator
    when 'contains'
      "#{field} LIKE '%#{sanitized_value}%'"
    when 'not_contains'
      "#{field} NOT LIKE '%#{sanitized_value}%'"
    when 'equals'
      "#{field} = '#{sanitized_value}'"
    when 'not_equals'
      "#{field} != '#{sanitized_value}'"
    else
      '1=1'
    end
  end

  # 映射操作符到SQL
  def map_operator_to_sql(operator)
    case operator
    when 'gt'
      '>'
    when 'lt'
      '<'
    when 'eq', 'equals'
      '='
    when 'gte'
      '>='
    when 'lte'
      '<='
    when 'ne', 'not_equals'
      '!='
    else
      '='
    end
  end

  # 映射前端指标名到数据库字段名
  def map_metric_to_db_field(metric)
    metric_mapping = {
      # 字符串字段
      'account_name' => 'ads_account_id', # 简化处理，实际需要 JOIN
      'campaign_name' => 'campaign_name',
      'adset_name' => 'adset_name',
      'ad_name' => 'ad_name',

      # 核心指标
      'impressions' => 'impressions',
      'clicks' => 'clicks',
      'spend' => 'spend',
      'reach' => 'reach',

      # 计算指标（这些在 HAVING 子句中会被特殊处理，从基础指标计算）
      'cpm' => 'cpm',
      'cpc' => 'cpc',
      'ctr' => 'ctr',
      'cpi' => 'cpi',
      'cvRate' => 'cvr',

      # 转化指标
      'conversions' => 'conversions',
      'purchases' => 'purchases',
      'conversion_value' => 'conversion_value',
      'roas' => 'roas',
      'cost_per_conversion' => 'cost_per_conversion',
      'installs' => 'app_installs',

      # 视频指标
      'video_views' => 'video_views',
      'video_views_3s' => 'video_views_3s',

      # 互动指标
      'likes' => 'likes',
      'comments' => 'comments',
      'shares' => 'shares',
      'link_clicks' => 'link_clicks',
      'post_engagements' => 'post_engagements',

      # 应用指标
      'app_installs' => 'app_installs'
    }

    metric_mapping[metric] || metric
  end

  # 获取时区 - 使用项目的时区
  def get_timezone
    # project.time_zone 是整数类型,表示UTC偏移量(小时)
    # 例如: 0 => 'UTC', 8 => 'UTC+8', -5 => 'UTC-5'
    offset_hours = project.time_zone || 0

    if offset_hours.zero?
      'UTC'
    elsif offset_hours.positive?
      "Etc/GMT-#{offset_hours}" # 注意:Etc/GMT的符号是反的
    else
      "Etc/GMT+#{offset_hours.abs}"
    end
  end

  # SQL值清理（防止SQL注入）
  def sanitize_sql_value(value)
    ActiveRecord::Base.connection.quote_string(value.to_s)
  end

  # 执行规则动作
  def execute_action(matched_ads)
    case rule.action
    when 'pause_ad'
      pause_ads(matched_ads)
    when 'add_ad'
      add_ads(matched_ads)
    when 'increase_bid'
      adjust_bids(matched_ads, :increase)
    when 'decrease_bid'
      adjust_bids(matched_ads, :decrease)
    when 'increase_budget'
      adjust_budgets(matched_ads, :increase)
    when 'decrease_budget'
      adjust_budgets(matched_ads, :decrease)
    else
      Rails.logger.warn "Unknown action: #{rule.action}"
    end
  end

  # 暂停广告
  def pause_ads(matched_ads)
    matched_ads.each do |ad_info|
      # TODO: 调用广告平台API暂停广告
      Rails.logger.info "Pausing ad: #{ad_info[:ad_id]} (Platform: #{ad_info[:platform]}, Account: #{ad_info[:ads_account_id]})"
      # 示例: FacebookAdService.new(ad_info).pause_ad
    end
  end

  # 添加广告
  def add_ads(matched_ads)
    matched_ads.each do |ad_info|
      # TODO: 调用广告平台API创建新广告
      Rails.logger.info "Adding new ad based on: #{ad_info[:ad_id]} (Platform: #{ad_info[:platform]})"
    end
  end

  # 调整出价
  def adjust_bids(matched_ads, direction)
    percentage = rule.action_value / 100.0

    matched_ads.each do |ad_info|
      # 需要先查询当前出价
      # TODO: 从广告平台API获取当前出价
      current_bid = 0 # 临时值
      new_bid = if direction == :increase
                  current_bid * (1 + percentage)
                else
                  current_bid * (1 - percentage)
                end

      Rails.logger.info "Adjusting bid for #{ad_info[:ad_id]}: #{current_bid} -> #{new_bid}"
      # TODO: 调用广告平台API调整出价
    end
  end

  # 调整预算
  def adjust_budgets(matched_ads, direction)
    percentage = rule.action_value / 100.0

    matched_ads.each do |ad_info|
      # 需要先查询当前预算
      # TODO: 从广告平台API获取当前预算
      current_budget = 0 # 临时值
      new_budget = if direction == :increase
                     current_budget * (1 + percentage)
                   else
                     current_budget * (1 - percentage)
                   end

      Rails.logger.info "Adjusting budget for #{ad_info[:ad_id]}: #{current_budget} -> #{new_budget}"
      # TODO: 调用广告平台API调整预算
    end
  end
end
