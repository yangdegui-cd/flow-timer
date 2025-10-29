# frozen_string_literal: true

class FetchAllAdjustReportJob
  @queue = :adjust_report

  def self.perform(days = 7)
    # 如果没有指定项目ID，则为所有项目拉取数据
    projects = Project.active.where.not(adjust_game_token: [nil, ''])

    Rails.logger.info "[FetchAdjustReportJob] 开始为 #{projects.count} 个项目批量拉取 Adjust 报告数据"

    projects.each do |project|
      begin
        Resque.enqueue(FetchAdjustReportJob, project.id, days)
        Rails.logger.info "[FetchAdjustReportJob] 已将项目 #{project.name} (ID: #{project.id}) 加入队列"
      rescue => e
        Rails.logger.error "[FetchAdjustReportJob] 将项目 #{project.name} 加入队列失败: #{e.message}"
      end
    end

    Rails.logger.info "[FetchAdjustReportJob] 批量任务调度完成"
  end
end
