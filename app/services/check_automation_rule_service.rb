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
        ad = AdState.find_by(ad_id: ad_info['ad_id'])

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
                                                       ads_account_name: AdsAccount.find(ad_info['ads_account_id']).name,
                                                       thumbnail_url: ad&.thumbnail_url,
                                                       ad_is_active: ad&.is_active,
                                                       ad_status: ad&.status,
                                                       ad_status_updated_at: ad&.updated_at,
                                                     }),
                             })
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
        AND #{condition_active_status_ads}
      GROUP BY #{group_by_rule.join(', ')}
      HAVING #{having_conditions}
    SQL
  end

  def condition_active_status_ads
    "ad_id IN (SELECT ad_id FROM ad_states WHERE is_active = 1)"
  end

  # 1. 根据时间类型计算时间范围条件
  def condition_time_range
    timezone = get_timezone
    current_time = Time.current.in_time_zone(timezone)

    if rule.time_type == 'range' && rule.time_range_config.present?
      # 使用日期范围配置
      build_range_time_condition(rule.time_range_config, current_time)
    else
      # 使用最近时间配置
      build_recent_time_condition(current_time)
    end
  end

  # 构建最近时间条件（原逻辑）
  def build_recent_time_condition(current_time)
    case rule.time_granularity
    when 'day'
      # 最近N天：根据 date 字段计算
      start_date = current_time - rule.time_range.days
      "date >= '#{start_date.to_date}' AND date <= '#{current_time.to_date}'"
    when 'hour'
      # 最近N小时：根据 date 和 hour 字段计算
      start_time = current_time - rule.time_range.hours
      "datetime >= '#{start_time.strftime('%Y-%m-%d %H:00:00')}' AND datetime <= '#{current_time.strftime('%Y-%m-%d %H:59:59')}'"
    else
      raise "Unsupported time_granularity: #{rule.time_granularity}"
    end
  end

  # 构建日期范围条件
  def build_range_time_condition(config, current_time)
    start_date_config = config['start_date']
    end_date_config = config['end_date']

    # 计算开始日期
    start_date = if start_date_config['type'] == 'absolute'
                   Date.parse(start_date_config['date'].to_s)
                 else
                   # relative: date 是负数，表示距今天数
                   days_ago = start_date_config['date'].to_i.abs
                   current_time.to_date - days_ago.days
                 end

    # 计算结束日期
    end_date = if end_date_config['type'] == 'absolute'
                 Date.parse(end_date_config['date'].to_s)
               else
                 # relative: date 是负数，表示距今天数
                 days_ago = end_date_config['date'].to_i.abs
                 current_time.to_date - days_ago.days
               end

    # 日期范围条件统一使用 date 字段
    "date >= '#{start_date}' AND date <= '#{end_date}'"
  end

  # 2. 处理 condition_group 条件，拼接出一个 condition 语句
  def condition_by_rule
    process_condition_group(rule.condition_group)
  end

  # 分组字段
  def group_by_rule
    %w[platform project_id ads_account_id campaign_name campaign_id adset_name adset_id ad_name ad_id]
  end

  private

  # 查找符合条件的广告数据
  def find_matching_ads
    query = build_query
    Rails.logger.info "Executing query: #{query}"
    begin
      result = AdsData.connection.execute(query)
    rescue => e
      Rails.logger.error "Failed to execute query: #{e.message}"
      AutomationLog.log_action(
        project: project,
        action_type: "规则触发",
        action: "自动化规则触发",
        duration: 0,
        status: "failed",
        remark: {
          error: e.message,
          query: query,
        })
    end
    result&.map { |row| group_by_rule.zip(row).to_h } || []
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

    case metric_type
    when 'numeric'
      # 数值类型条件将在 HAVING 子句中处理，这里返回占位符
      '1=1'
    when 'string'
      # 字符串类型条件直接在 WHERE 中处理
      build_string_condition(metric, operator, value)
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
    metric = AdsMetric.find_by(key: condition['metric'])
    "(#{metric.sql_expression}) #{condition['operator']} #{condition['value']}"
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
