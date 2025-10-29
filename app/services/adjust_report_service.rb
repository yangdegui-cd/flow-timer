# frozen_string_literal: true

require 'net/http'
require 'json'

class AdjustReportService
  class AdjustApiError < StandardError; end

  # Adjust API 维度
  DIMENSIONS = %w[
    day
    hour
    campaign_network
    adgroup_network
    creative_network
  ].freeze

  # Adjust API 指标
  METRICS = %w[
    installs
    network_clicks
    network_impressions
    cohort_all_revenue
    cost
    all_revenue_total_d0
    all_revenue_total_d1
    all_revenue_total_d2
    all_revenue_total_d3
    all_revenue_total_d4
    all_revenue_total_d5
    all_revenue_total_d6
    retained_users_d0
    retained_users_d1
    retained_users_d2
    retained_users_d3
    retained_users_d4
    retained_users_d5
    retained_users_d6
    paying_users_d0
    paying_users_d1
    paying_users_d2
    paying_users_d3
    paying_users_d4
    paying_users_d5
    paying_users_d6
  ].freeze

  def initialize(project)
    @project = project
    @config = Config.first

    raise AdjustApiError, 'Adjust API 配置未找到' unless @config
    raise AdjustApiError, 'Adjust API Token 未配置' if @config.adjust_api_token.blank?
    raise AdjustApiError, 'Adjust API Server 未配置' if @config.adjust_api_server.blank?
    raise AdjustApiError, '项目的 Adjust Game Token 未配置' if @project.adjust_game_token.blank?
  end

  # 拉取最近7天的报告数据
  def fetch_recent_data(days: 7)
    end_date = Date.today
    start_date = end_date - days + 1

    fetch_and_save_report(start_date, end_date)
  end

  # 拉取指定日期范围的报告数据并保存
  def fetch_and_save_report(start_date, end_date)
    params = build_request_params(start_date, end_date)
    response = send_request(params)
    parsed_data = parse_response(response)

    # 保存数据到数据库
    saved_count = save_to_database(parsed_data[:data], start_date, end_date)

    {
      success: true,
      rows_count: saved_count,
      date_range: "#{start_date} to #{end_date}"
    }
  end

  # 仅拉取数据不保存（用于测试）
  def fetch_report(start_date, end_date)
    params = build_request_params(start_date, end_date)
    response = send_request(params)

    parse_response(response)
  end

  private

  def build_request_params(start_date, end_date)
    params = {
      app_token__in: @project.adjust_game_token,
      date_period: "#{start_date}:#{end_date}",
      dimensions: DIMENSIONS.join(','),
      metrics: METRICS.join(','),
      format: 'json'
    }

    # 添加时区参数，转换为 Adjust API 要求的格式 [+-]HH:MM
    if @project.time_zone.present?
      params[:utc_offset] = format_timezone(@project.time_zone)
    end

    params
  end

  # 将时区数字转换为 Adjust API 要求的格式
  # 例如: 8 -> "+08:00", -5 -> "-05:00"
  def format_timezone(timezone)
    tz = timezone.to_i
    sign = tz >= 0 ? '+' : '-'
    hours = tz.abs
    "#{sign}#{hours.to_s.rjust(2, '0')}:00"
  end

  def send_request(params)
    uri = URI(@config.adjust_api_server)
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@config.adjust_api_token}"
    request['Content-Type'] = 'application/json'

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.read_timeout = 60
    http.open_timeout = 30

    Rails.logger.info "[AdjustReportService] 发送请求到 Adjust API: #{uri}"

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = "Adjust API 请求失败: #{response.code} - #{response.body}"
      Rails.logger.error "[AdjustReportService] #{error_message}"
      raise AdjustApiError, error_message
    end

    response.body
  rescue StandardError => e
    Rails.logger.error "[AdjustReportService] 请求异常: #{e.message}"
    raise AdjustApiError, "Adjust API 请求异常: #{e.message}"
  end

  def parse_response(response_body)
    data = JSON.parse(response_body)

    Rails.logger.info "[AdjustReportService] 成功获取数据，记录数: #{data['rows']&.size || 0}"

    {
      success: true,
      data: data,
      rows_count: data['rows']&.size || 0
    }
  rescue JSON::ParserError => e
    Rails.logger.error "[AdjustReportService] JSON 解析失败: #{e.message}"
    raise AdjustApiError, "响应数据解析失败: #{e.message}"
  end

  def save_to_database(data, start_date, end_date)
    return 0 unless data && data['rows']

    # 先删除该日期范围内的旧数据，避免重复
    deleted_count = AdsAdjustDatum.delete_for_date_range(@project.id, start_date, end_date)
    Rails.logger.info "[AdjustReportService] 删除项目 #{@project.id} 在 #{start_date} 到 #{end_date} 的旧数据: #{deleted_count} 条"
    adjust_data = data['rows'].map { |row| generate_adjust_datum(row) }
    AdsAdjustDatum.insert_all(adjust_data)
    Rails.logger.info "[AdjustReportService] 保存完成: 成功 #{adjust_data.count} 条"
  end

  def generate_adjust_datum(row)
    record_data = {
      project_id: @project.id,
      platform: 'adjust',
      data_status: 'active',
      data_source: 'adjust_api',
      data_fetched_at: Time.current,
    }

    DIMENSIONS.each_with_index do |dim, index|
      record_data[dim] = row[dim]
    end

    METRICS.each_with_index do |metric, index|
      record_data[metric] = row[metric]
    end

    record_data["date"] = parse_date(record_data["day"])
    record_data["hour"] = record_data["hour"].to_time.hour if record_data["hour"]
    record_data.delete("day")
    record_data
  end

  def parse_date(date_string)
    return Date.today unless date_string

    Date.parse(date_string)
  rescue ArgumentError
    Rails.logger.warn "[AdjustReportService] 日期解析失败: #{date_string}, 使用今天日期"
    Date.today
  end

  # 测试 Adjust API 连接
  def self.test_connection(config)
    raise AdjustApiError, 'Adjust API Token 未配置' if config.adjust_api_token.blank?
    raise AdjustApiError, 'Adjust API Server 未配置' if config.adjust_api_server.blank?

    # 使用简单的请求测试连接
    uri = URI(config.adjust_api_server)
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{config.adjust_api_token}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.read_timeout = 10
    http.open_timeout = 10

    response = http.request(request)

    {
      success: response.is_a?(Net::HTTPSuccess) || response.code.to_i < 500,
      message: response.is_a?(Net::HTTPSuccess) ? 'Adjust API 连接测试成功' : "HTTP #{response.code}: #{response.message}"
    }
  rescue StandardError => e
    {
      success: false,
      message: "连接失败: #{e.message}"
    }
  end
end
