class CheckAllAutomationRuleJob < BaseResqueJob
  @queue = :check_automation_rule

  def self.perform
    sync_all_ads_states
    # 如果没有指定项目ID，则为所有项目拉取数据
    projects = Project.joins(:automation_rules)
                      .active
                      .automation_enabled
                      .where(automation_rules: { enabled: true })
                      .group("projects.id")
                      .having("COUNT(automation_rules.id) > 0")

    Rails.logger.info "[CheckAllAutomationRuleJob] 开始为 #{projects.count} 个项目批量检查自动化规则"

    projects.each do |project|
      begin
        Resque.enqueue(CheckAutomationRuleJob, project.id)
        Rails.logger.info "[CheckAllAutomationRuleJob] 已将项目 #{project.name} (ID: #{project.id}) 加入队列"
      rescue => e
        Rails.logger.error "[CheckAllAutomationRuleJob] 将项目 #{project.name} 加入队列失败: #{e.message}"
      end
    end

    Rails.logger.info "[FetchAllFacebookReportJob] 批量任务调度完成"
  end


  def self.sync_all_ads_states
    ads_accounts = AdsAccount.active.to_a
    max_threads = 10  # 最大并发线程数

    Rails.logger.info "[CheckAllAutomationRuleJob] 开始多线程同步 #{ads_accounts.count} 个广告账户状态，最大并发数: #{max_threads}"

    # 分批处理，每批最多 max_threads 个线程
    ads_accounts.each_slice(max_threads) do |batch|
      threads = batch.map do |ads_account|
        Thread.new do
          begin
            Rails.logger.info "[CheckAllAutomationRuleJob] 开始同步广告账户状态 (ID: #{ads_account.id}, 名称: #{ads_account.name})"
            AdsFetchAdStateService.for(ads_account).sync_all
            Rails.logger.info "[CheckAllAutomationRuleJob] 完成同步广告账户状态 (ID: #{ads_account.id})"
          rescue => e
            AutomationLog.log_action(
              project: ads_account.project,
              action_type: '定时任务',
              action: '同步广告账户状态失败',
              status: 'failed',
              remark: {
                ads_account_id: ads_account.id,
                ads_account_name: ads_account.name,
                error_message: e.message,
                backtrace: e.backtrace&.first(5)
              },
            )
            Rails.logger.error "[CheckAllAutomationRuleJob] 同步广告账户状态失败 (ID: #{ads_account.id}): #{e.message}"
          end
        end
      end

      # 等待当前批次的所有线程完成
      threads.each(&:join)
    end

    Rails.logger.info "[CheckAllAutomationRuleJob] 所有广告账户状态同步完成"
  end
end
