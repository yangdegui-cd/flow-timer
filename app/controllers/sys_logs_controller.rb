class SysLogsController < ApplicationController

  # 获取所有日志（管理员）
  def index
    logs = SysLog.includes(:user).recent
    
    # 筛选条件
    logs = logs.by_user(params[:user_id]) if params[:user_id].present?
    logs = logs.by_controller(params[:controller_name]) if params[:controller_name].present?
    logs = logs.by_action(params[:action_name]) if params[:action_name].present?
    logs = logs.by_method(params[:request_method]) if params[:request_method].present?
    logs = logs.by_status(params[:status_code]) if params[:status_code].present?
    
    # 时间筛选
    if params[:start_date].present?
      logs = logs.where('request_time >= ?', params[:start_date])
    end
    if params[:end_date].present?
      logs = logs.where('request_time <= ?', params[:end_date])
    end

    # 特殊筛选
    logs = logs.errors if params[:errors_only] == 'true'
    logs = logs.slow_requests(params[:slow_threshold].to_i) if params[:slow_requests] == 'true'

    # 分页
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min
    
    # 获取总数应该基于筛选后的查询
    total_count = logs.count
    logs = logs.limit(per_page).offset((page - 1) * per_page)
    
    render json: ok({
      logs: logs.map { |log| format_log(log) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    })
  end

  # 获取当前用户的日志
  def my_logs
    logs = current_user.sys_logs.recent.limit(100)
    render json: ok(logs.map { |log| format_log(log) })
  end

  # 获取单个日志详情
  def show
    log = SysLog.find(params[:id])
    render json: ok(format_log_detail(log))
  end

  # 获取日志统计
  def stats
    stats = {
      total_requests: SysLog.count,
      today_requests: SysLog.today.count,
      this_week_requests: SysLog.this_week.count,
      error_requests: SysLog.errors.count,
      slow_requests: SysLog.slow_requests.count,
      
      # 按控制器统计
      by_controller: SysLog.group(:controller_name).count.sort_by { |_, count| -count }.first(10),
      
      # 按状态码统计
      by_status: SysLog.group(:status_code).count,
      
      # 按用户统计（top 10）
      by_user: SysLog.joins(:user)
                    .group('sys_users.name')
                    .count
                    .sort_by { |_, count| -count }
                    .first(10),
      
      # 按小时统计（今天）
      by_hour: SysLog.today
                     .group("DATE_FORMAT(request_time, '%H')")
                     .count
                     .transform_keys { |hour| "#{hour}:00" },

      # 路由性能统计
      route_performance: calculate_route_performance
    }
    
    render json: ok(stats)
  end

  # 清理旧日志
  def cleanup
    days = params[:days]&.to_i || 30
    deleted_count = SysLog.where('request_time < ?', days.days.ago).delete_all
    
    render json: ok({
      message: "已清理 #{deleted_count} 条超过 #{days} 天的日志记录",
      deleted_count: deleted_count
    })
  end

  private

  def format_log(log)
    {
      id: log.id,
      user: {
        id: log.user.id,
        name: log.user.name,
        email: log.user.email
      },
      controller_name: log.controller_name,
      action_name: log.action_name,
      request_method: log.request_method,
      request_url: log.request_url,
      status_code: log.status_code,
      duration: log.duration,
      formatted_duration: log.formatted_duration,
      request_time: log.request_time,
      response_time: log.response_time,
      ip_address: log.ip_address,
      error: log.error?,
      slow: log.slow?,
      action_description: log.action_description
    }
  end

  def format_log_detail(log)
    format_log(log).merge({
      url_params: log.url_params_hash,
      body_params: log.body_params_hash,
      user_agent: log.user_agent,
      error_message: log.error_message
    })
  end

  def calculate_route_performance
    # 按路由分组并计算统计信息
    SysLog.select('
        controller_name,
        action_name,
        request_method,
        COUNT(*) as total_requests,
        AVG(duration) as avg_duration,
        SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as error_rate,
        SUM(CASE WHEN duration > 1000 THEN 1 ELSE 0 END) as slow_requests
      ')
      .where('duration IS NOT NULL')
      .group(:controller_name, :action_name, :request_method)
      .having('COUNT(*) >= 10') # 只显示至少有10个请求的路由
      .order('avg_duration DESC')
      .limit(20)
      .map do |log|
        {
          route: "#{log.request_method} #{log.controller_name}##{log.action_name}",
          controller: log.controller_name,
          action: log.action_name,
          total_requests: log.total_requests,
          avg_duration: log.avg_duration.to_f.round(2),
          error_rate: log.error_rate.to_f.round(2),
          slow_requests: log.slow_requests
        }
      end
  end
end
