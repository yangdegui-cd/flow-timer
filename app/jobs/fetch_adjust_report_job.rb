# frozen_string_literal: true

class FetchAdjustReportJob
  @queue = :adjust_report

  def self.perform( project_id = nil, days = 7)
    # 如果没有指定项目ID，则为所有项目拉取数据
    project = Project.find(project_id)

    Rails.logger.info "[FetchAdjustReportJob] 开始为项目 #{project.name} (ID: #{project.id}) 拉取 Adjust 报告数据"

    start_time = Time.current

    begin
      service = AdjustReportService.new(project)
      result = service.fetch_recent_data(days: days)

      duration = ((Time.current - start_time) * 1000).to_i

      # 记录成功日志
      AutomationLog.log_action(
        project: project,
        action_type: '定时任务',
        action: "拉取 Adjust 报告数据（最近#{days}天）",
        duration: duration,
        status: 'success',
        remark: {
          project_name: project.name,
          days: days,
          rows_count: result[:rows_count],
          task_type: 'fetch_adjust_report'
        }
      )

      Rails.logger.info "[FetchAdjustReportJob] 成功拉取 #{result[:rows_count]} 条记录，耗时 #{duration}ms"
      result
    rescue AdjustReportService::AdjustApiError => e
      duration = ((Time.current - start_time) * 1000).to_i

      # 记录失败日志
      AutomationLog.log_action(
        project: project,
        action_type: '定时任务',
        action: "拉取 Adjust 报告数据失败",
        duration: duration,
        status: 'failed',
        remark: {
          project_name: project.name,
          days: days,
          error: e.message,
          task_type: 'fetch_adjust_report'
        }
      )

      Rails.logger.error "[FetchAdjustReportJob] Adjust API 错误: #{e.message}"
      raise e
    rescue => e
      duration = ((Time.current - start_time) * 1000).to_i

      # 记录系统错误日志
      AutomationLog.log_action(
        project: project,
        action_type: '定时任务',
        action: "拉取 Adjust 报告数据失败",
        duration: duration,
        status: 'failed',
        remark: {
          project_name: project.name,
          days: days,
          error: e.message,
          backtrace: e.backtrace&.first(5),
          task_type: 'fetch_adjust_report'
        }
      )
      Rails.logger.error "[FetchAdjustReportJob] 系统错误: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
