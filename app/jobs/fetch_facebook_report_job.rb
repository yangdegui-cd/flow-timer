class FetchFacebookReportJob < BaseResqueJob
  @queue = :facebook_report

  def self.perform(project_id, days = 7, account_id = nil)
    new.perform(project_id, days, account_id)
  end

  def perform(project_id, days = 7, account_id = nil)
    log_info "开始Facebook广告数据同步任务"
    project = Project.find(project_id)
    start_time = Time.current

    begin
      if account_id.blank?
        result = sync_all_accounts(project, days)
      else
        result = sync_single_account(project, days, account_id)
      end

      duration = ((Time.current - start_time) * 1000).to_i

      # 记录成功日志
      AutomationLog.log_action(
        project: project,
        action_type: '定时任务',
        action: "拉取 Facebook 广告数据（最近#{days}天）",
        duration: duration,
        status: 'success',
        remark: {
          project_name: project.name,
          days: days,
          account_id: account_id,
          total_accounts: result[:total_accounts],
          successful_syncs: result[:successful_syncs],
          failed_syncs: result[:failed_syncs],
          total_rows: result[:total_rows],
          task_type: 'fetch_facebook_report'
        }
      )

      log_info "Facebook广告数据同步任务完成，耗时 #{duration}ms"
      result
    rescue => e
      duration = ((Time.current - start_time) * 1000).to_i

      # 记录失败日志
      AutomationLog.log_action(
        project: project,
        action_type: '定时任务',
        action: "拉取 Facebook 广告数据失败",
        duration: duration,
        status: 'failed',
        remark: {
          project_name: project.name,
          days: days,
          account_id: account_id,
          error: e.message,
          backtrace: e.backtrace&.first(5),
          task_type: 'fetch_facebook_report'
        }
      )

      log_error "Facebook同步任务失败: #{e.message}", e
      raise
    end
  end

  private

  def sync_all_accounts(project, days)
    facebook_accounts = AdsAccount.joins(:ads_platform)
                                  .where(project_id: project.id)
                                  .where(ads_platforms: { slug: 'facebook' })
                                  .where(account_status: 'active')

    if facebook_accounts.empty?
      log_info "未找到有效的Facebook广告账户"
      return {
        total_accounts: 0,
        successful_syncs: 0,
        failed_syncs: 0,
        total_rows: 0
      }
    end

    total_accounts = facebook_accounts.count
    log_info "找到 #{total_accounts} 个Facebook广告账户需要同步"

    # 使用多线程并发同步，提高效率
    # 根据账户数量动态调整线程数，避免过多线程
    max_threads = [total_accounts, 5].min  # 最多5个并发线程
    log_info "使用 #{max_threads} 个并发线程进行同步"

    # 线程安全的计数器
    mutex = Mutex.new
    successful_syncs = 0
    failed_syncs = 0
    total_rows = 0

    # 使用线程池并发执行
    threads = []
    facebook_accounts.each_with_index do |account, index|
      # 控制并发数量
      if threads.size >= max_threads
        threads.first.join  # 等待最早的线程完成
        threads.shift
      end

      thread = Thread.new do
        # 为每个线程建立独立的数据库连接
        ActiveRecord::Base.connection_pool.with_connection do
          log_info "[#{index + 1}/#{total_accounts}] 开始同步账户: #{account.name} (#{account.account_id})"

          begin
            sync_account_data(days, account)

            # 显示同步统计
            recent_count = AdsData.where(ads_account: account)
                                  .where(created_at: 1.hour.ago..Time.current)
                                  .count

            # 线程安全地更新计数器
            mutex.synchronize do
              successful_syncs += 1
              total_rows += recent_count
            end

            log_info "✓ 账户 #{account.name} 同步成功，新增记录: #{recent_count} 条"

          rescue => e
            # 线程安全地更新计数器
            mutex.synchronize do
              failed_syncs += 1
            end

            log_error "✗ 账户 #{account.name} 同步失败: #{e.message}", e

            # 更新账户同步状态
            begin
              account.update!(
                sync_status: 'error',
                last_error: e.message,
                last_sync_at: Time.current
              )
            rescue => update_error
              log_error "更新账户状态失败: #{update_error.message}"
            end
          end
        end
      end

      threads << thread
    end

    # 等待所有线程完成
    log_info "等待所有同步线程完成..."
    threads.each(&:join)

    log_info "同步完成统计: 成功 #{successful_syncs}/#{total_accounts}, 失败 #{failed_syncs}/#{total_accounts}, 总记录数: #{total_rows}"

    {
      total_accounts: total_accounts,
      successful_syncs: successful_syncs,
      failed_syncs: failed_syncs,
      total_rows: total_rows
    }
  end

  def sync_single_account(project, days, account_id)
    account = AdsAccount.joins(:ads_platform)
                        .where(project_id: project.id)
                        .where(account_status: 'active')
                        .where(ads_platforms: { slug: 'facebook' })
                        .find_by(account_id: account_id)

    if account.nil?
      log_error "未找到Facebook广告账户: #{account_id}"
      raise "未找到Facebook广告账户: #{account_id}"
    end

    log_info "同步单个Facebook广告账户: #{account.name} (#{account.account_id})"

    sync_account_data(days, account)

    # 显示详细统计
    recent_data = AdsData.where(ads_account: account)
                         .where(created_at: 1.hour.ago..Time.current)

    rows_count = recent_data.count
    log_info "同步统计:"
    log_info "- 新增记录数: #{rows_count}"
    log_info "- 小时级别记录: #{recent_data.where.not(hour_of_day: nil).count}"

    {
      total_accounts: 1,
      successful_syncs: 1,
      failed_syncs: 0,
      total_rows: rows_count
    }
  end

  def sync_account_data(days, account)
    sync_service = FacebookReportService.new(account)

    result = sync_service.fetch_recent_data(build_date_range(days))

    unless result
      error_message = sync_service.errors.join(', ')
      log_error "同步失败: #{error_message}"
      raise "同步失败: #{error_message}"
    end
  end

  def build_date_range(_days = 7)
    {
      since: _days.days.ago.strftime('%Y-%m-%d'),
      until: Date.current.strftime('%Y-%m-%d')
    }
  end
end
