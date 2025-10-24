class FacebookSyncJob < BaseResqueJob
  @queue = :facebook_sync

  def self.perform(options = {})
    new.perform(options)
  end

  def perform(options = {})
    log_info "开始Facebook广告数据同步任务"

    account_id = options['account_id']
    sync_all = options['sync_all'] || account_id.blank?

    if sync_all
      sync_all_accounts(options)
    else
      sync_single_account(account_id, options)
    end

    log_info "Facebook广告数据同步任务完成"
  rescue => e
    log_error "Facebook同步任务失败: #{e.message}", e
    raise
  end

  private

  def sync_all_accounts(options = {})
    facebook_accounts = AdsAccount.joins(:ads_platform)
                                 .where(ads_platforms: { slug: 'facebook' })
                                 .where(account_status: 'active')
                                 .where.not(access_token: [nil, ''])

    if facebook_accounts.empty?
      log_info "未找到有效的Facebook广告账户"
      return
    end

    total_accounts = facebook_accounts.count
    successful_syncs = 0
    failed_syncs = 0

    log_info "找到 #{total_accounts} 个Facebook广告账户需要同步"

    facebook_accounts.each_with_index do |account, index|
      log_info "[#{index + 1}/#{total_accounts}] 同步账户: #{account.name} (#{account.account_id})"

      begin
        sync_account_data(account, options)
        successful_syncs += 1
        log_info "账户 #{account.name} 同步成功"

        # 显示同步统计
        recent_count = AdsData.where(ads_account: account)
                            .where(created_at: 1.hour.ago..Time.current)
                            .count
        log_info "账户 #{account.name} 新增记录: #{recent_count} 条"

      rescue => e
        failed_syncs += 1
        log_error "账户 #{account.name} 同步失败: #{e.message}", e

        # 更新账户同步状态
        account.update!(
          sync_status: 'error',
          last_error: e.message,
          last_sync_at: Time.current
        )
      end

      # 避免API频率限制
      sleep(2) if index < total_accounts - 1
    end

    log_info "同步完成统计: 成功 #{successful_syncs}/#{total_accounts}, 失败 #{failed_syncs}/#{total_accounts}"
  end

  def sync_single_account(account_id, options = {})
    account = AdsAccount.joins(:ads_platform)
                       .where(ads_platforms: { slug: 'facebook' })
                       .find_by(account_id: account_id)

    if account.nil?
      log_error "未找到Facebook广告账户: #{account_id}"
      raise "未找到Facebook广告账户: #{account_id}"
    end

    log_info "同步单个Facebook广告账户: #{account.name} (#{account.account_id})"

    sync_account_data(account, options)

    # 显示详细统计
    recent_data = AdsData.where(ads_account: account)
                        .where(created_at: 1.hour.ago..Time.current)

    log_info "同步统计:"
    log_info "- 新增记录数: #{recent_data.count}"
    log_info "- 小时级别记录: #{recent_data.where.not(hour_of_day: nil).count}"
    log_info "- 包含年龄维度: #{recent_data.where.not(age_range: nil).count}"
    log_info "- 包含设备型号: #{recent_data.where.not(device_model: nil).count}"
  end

  def sync_account_data(account, options = {})
    sync_service = FacebookAdsWideSyncService.new(account)

    # 构建同步选项
    sync_options = build_sync_options(options)

    log_info "同步参数: #{sync_options.inspect}"

    result = sync_service.sync_to_wide_table(sync_options)

    unless result
      error_message = sync_service.errors.join(', ')
      log_error "同步失败: #{error_message}"
      raise "同步失败: #{error_message}"
    end
  end

  def build_sync_options(options = {})
    {
      date_range: {
        since: options['since'] || 7.days.ago.strftime('%Y-%m-%d'),
        until: options['until'] || Date.current.strftime('%Y-%m-%d')
      },
      level: options['level'] || 'ad',
      hourly: options['hourly'] != false,  # 默认启用小时级别
      breakdowns: parse_breakdowns(options['breakdowns'])
    }
  end

  def parse_breakdowns(breakdowns_option)
    if breakdowns_option.is_a?(String)
      breakdowns_option.split(',').map(&:strip)
    elsif breakdowns_option.is_a?(Array)
      breakdowns_option
    else
      %w[]
    end
  end
end
