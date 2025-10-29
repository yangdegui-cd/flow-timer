class FetchAllFacebookReportJob < BaseResqueJob
  @queue = :facebook_report

  def self.perform(days = 7)
    # 如果没有指定项目ID，则为所有项目拉取数据
    projects = Project.joins(:ads_accounts)
                      .active
                      .where(ads_accounts: { account_status: 'active' })
                      .group("projects.id")
                      .having("COUNT(ads_accounts.id) > 0")

    Rails.logger.info "[FetchAllFacebookReportJob] 开始为 #{projects.count} 个项目批量拉取 Adjust 报告数据"

    projects.each do |project|
      begin
        Resque.enqueue(FetchFacebookReportJob, project.id, days)
        Rails.logger.info "[FetchAllFacebookReportJob] 已将项目 #{project.name} (ID: #{project.id}) 加入队列"
      rescue => e
        Rails.logger.error "[FetchAllFacebookReportJob] 将项目 #{project.name} 加入队列失败: #{e.message}"
      end
    end

    Rails.logger.info "[FetchAllFacebookReportJob] 批量任务调度完成"
  end
end
