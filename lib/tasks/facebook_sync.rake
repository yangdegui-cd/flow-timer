namespace :facebook do
  desc "同步所有Facebook广告账户的数据"
  task sync_all: :environment do
    puts "开始同步所有Facebook广告账户的数据..."

    facebook_accounts = AdsAccount.joins(:ads_platform)
                                 .where(ads_platforms: { slug: 'facebook' })
                                 .where(account_status: 'active')
                                 .where.not(access_token: [nil, ''])

    if facebook_accounts.empty?
      puts "未找到有效的Facebook广告账户"
      exit
    end

    total_accounts = facebook_accounts.count
    successful_syncs = 0
    failed_syncs = 0

    facebook_accounts.each_with_index do |account, index|
      puts "\n[#{index + 1}/#{total_accounts}] 同步账户: #{account.name} (#{account.account_id})"

      begin
        sync_service = FacebookReportService.new(account)

        # 同步最近7天的数据，使用基础breakdown获取细分数据
        options = {
          date_range: {
            since: 7.days.ago.strftime('%Y-%m-%d'),
            until: Date.current.strftime('%Y-%m-%d')
          },
          level: 'ad',
          hourly: false,  # 暂时关闭小时级别
          breakdowns: %w[age gender]  # 基础breakdown：年龄段+性别
        }

        result = sync_service.fetch_recent_data(options)

        if result
          puts "✅ 同步成功"
          successful_syncs += 1

          # 显示同步统计
          recent_count = AdsData.where(ads_account: account)
                              .where(created_at: 1.hour.ago..Time.current)
                              .count
          puts "   新增记录: #{recent_count} 条"

        else
          puts "❌ 同步失败: #{sync_service.errors.join(', ')}"
          failed_syncs += 1
        end

      rescue => e
        puts "❌ 同步异常: #{e.message}"
        Rails.logger.error "Facebook数据同步异常: #{account.name} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        failed_syncs += 1
      end

      # 避免API频率限制
      sleep(2) if index < total_accounts - 1
    end

    puts "\n=== 同步完成 ==="
    puts "总账户数: #{total_accounts}"
    puts "成功同步: #{successful_syncs}"
    puts "失败同步: #{failed_syncs}"
    puts "成功率: #{(successful_syncs.to_f / total_accounts * 100).round(2)}%"
  end

  desc "同步指定Facebook广告账户的数据"
  task :sync_account, [:account_id] => :environment do |task, args|
    account_id = args[:account_id]

    if account_id.blank?
      puts "请提供广告账户ID: rake facebook:sync_account[账户ID]"
      exit
    end

    account = AdsAccount.joins(:ads_platform)
                       .where(ads_platforms: { slug: 'facebook' })
                       .find_by(account_id: account_id)

    if account.nil?
      puts "未找到Facebook广告账户: #{account_id}"
      exit
    end

    puts "同步Facebook广告账户: #{account.name} (#{account.account_id})"

    begin
      sync_service = FacebookReportService.new(account)

      # 提供更多自定义选项
      options = {
        date_range: {
          since: ENV.fetch('SYNC_SINCE', 3.days.ago.strftime('%Y-%m-%d')),
          until: ENV.fetch('SYNC_UNTIL', Date.current.strftime('%Y-%m-%d'))
        },
        level: ENV.fetch('SYNC_LEVEL', 'ad'),
        hourly: ENV.fetch('SYNC_HOURLY', 'true') == 'true',
        breakdowns: ENV.fetch('SYNC_BREAKDOWNS', 'publisher_platform,device_platform,age,gender').split(',')
      }

      puts "同步参数:"
      puts "- 日期范围: #{options[:date_range][:since]} 到 #{options[:date_range][:until]}"
      puts "- 级别: #{options[:level]}"
      puts "- 小时级别: #{options[:hourly]}"
      puts "- 维度分解: #{options[:breakdowns].join(', ')}"

      result = sync_service.fetch_recent_data(options)

      if result
        puts "✅ 同步成功"

        # 显示详细统计
        recent_data = AdsData.where(ads_account: account)
                           .where(created_at: 1.hour.ago..Time.current)

        puts "\n同步统计:"
        puts "- 新增记录数: #{recent_data.count}"
        puts "- 小时级别记录: #{recent_data.where.not(hour_of_day: nil).count}"
        puts "- 包含年龄维度: #{recent_data.where.not(age_range: nil).count}"
        puts "- 包含设备型号: #{recent_data.where.not(device_model: nil).count}"

      else
        puts "❌ 同步失败: #{sync_service.errors.join(', ')}"
        exit 1
      end

    rescue => e
      puts "❌ 同步异常: #{e.message}"
      Rails.logger.error "Facebook数据同步异常: #{account.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      exit 1
    end
  end

  desc "清理过期的Facebook广告数据"
  task :cleanup_old_data, [:days] => :environment do |task, args|
    days = args[:days]&.to_i || 90

    puts "清理#{days}天前的Facebook广告数据..."

    cutoff_date = days.days.ago
    old_data = AdsData.joins(ads_account: :ads_platform)
                     .where(ads_platforms: { slug: 'facebook' })
                     .where('ads_data.date < ?', cutoff_date)

    count = old_data.count

    if count > 0
      old_data.delete_all
      puts "✅ 已清理 #{count} 条过期数据"
    else
      puts "没有找到需要清理的过期数据"
    end
  end

  desc "验证Facebook API访问令牌"
  task validate_tokens: :environment do
    puts "验证所有Facebook广告账户的访问令牌..."

    facebook_accounts = AdsAccount.joins(:ads_platform)
                                 .where(ads_platforms: { slug: 'facebook' })
                                 .where.not(access_token: [nil, ''])

    valid_count = 0
    invalid_count = 0

    facebook_accounts.each do |account|
      print "验证账户 #{account.name} (#{account.account_id})... "

      begin
        token_service = FacebookTokenService.new(account)
        if token_service.validate_token
          puts "✅ 有效"
          valid_count += 1
        else
          puts "❌ 无效"
          invalid_count += 1
        end
      rescue => e
        puts "❌ 验证异常: #{e.message}"
        invalid_count += 1
      end
    end

    puts "\n验证结果:"
    puts "- 有效令牌: #{valid_count}"
    puts "- 无效令牌: #{invalid_count}"
    puts "- 总计: #{valid_count + invalid_count}"
  end
end
