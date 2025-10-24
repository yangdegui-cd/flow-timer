# frozen_string_literal: true

module AutomationLoggable
  extend ActiveSupport::Concern

  # 记录自动化日志
  # @param project [Project] 项目对象
  # @param action_type [String] 操作类型: "项目编辑", "规则触发", "定时任务", "调整广告投放"
  # @param action [String] 操作描述
  # @param status [String] 状态: "success", "failed"
  # @param remark [Hash] 备注信息 (JSON格式)
  # @param user [SysUser, nil] 操作用户
  # @param duration [Integer, nil] 执行时长(毫秒)
  def log_automation_action(project:, action_type:, action:, status: 'success', remark: {}, user: nil, duration: nil)
    AutomationLog.create!(
      project: project,
      sys_user: user,
      action_type: action_type,
      action: action,
      duration: duration,
      status: status,
      remark: remark
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create automation log: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # 包装操作并自动记录日志
  # @param project [Project] 项目对象
  # @param action_type [String] 操作类型
  # @param action [String] 操作描述
  # @param remark [Hash] 备注信息
  # @param user [SysUser, nil] 操作用户
  # @yield 要执行的操作块
  def with_automation_log(project:, action_type:, action:, remark: {}, user: nil)
    start_time = Time.current
    result = yield
    duration = ((Time.current - start_time) * 1000).to_i

    log_automation_action(
      project: project,
      action_type: action_type,
      action: action,
      status: 'success',
      remark: remark,
      user: user,
      duration: duration
    )

    result
  rescue StandardError => e
    duration = ((Time.current - start_time) * 1000).to_i
    error_remark = remark.merge(
      error: e.message,
      error_class: e.class.name,
      backtrace: e.backtrace.first(5)
    )

    log_automation_action(
      project: project,
      action_type: action_type,
      action: action,
      status: 'failed',
      remark: error_remark,
      user: user,
      duration: duration
    )

    raise e
  end
end
