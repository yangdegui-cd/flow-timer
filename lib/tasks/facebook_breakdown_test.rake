namespace :facebook do
  desc "测试Facebook API不同breakdown组合"
  task test_breakdowns: :environment do
    puts "=== 测试Facebook API Breakdown组合 ==="

    account = AdsAccount.joins(:ads_platform)
                       .where(ads_platforms: { slug: 'facebook' })
                       .where.not(access_token: [nil, ''])
                       .last

    if account.nil?
      puts "未找到有效的Facebook广告账户"
      exit
    end

    puts "测试账户: #{account.name} (#{account.account_id})"

    # 测试不同breakdown组合
    breakdown_tests = [
      { name: "无breakdown", breakdowns: [] },
      { name: "年龄", breakdowns: %w[age] },
      { name: "性别", breakdowns: %w[gender] },
      { name: "年龄+性别", breakdowns: %w[age gender] },
      { name: "国家", breakdowns: %w[country] },
      { name: "年龄+性别+国家", breakdowns: %w[age gender country] },
      { name: "设备平台", breakdowns: %w[device_platform] },
      { name: "发布平台", breakdowns: %w[publisher_platform] },
      { name: "版位", breakdowns: %w[placement] }
    ]

    breakdown_tests.each_with_index do |test, index|
      puts "\n[#{index + 1}/#{breakdown_tests.size}] 测试: #{test[:name]}"
      puts "Breakdown: #{test[:breakdowns].join(', ')}" if test[:breakdowns].any?

      begin
        sync_service = FacebookAdsWideSyncService.new(account)

        options = {
          date_range: {
            since: 7.days.ago.strftime('%Y-%m-%d'),
            until: Date.current.strftime('%Y-%m-%d')
          },
          level: 'ad',
          breakdowns: test[:breakdowns],
          clear_existing: false  # 测试时不清理数据
        }

        # 记录测试前的数据数量
        before_count = AdsData.where(ads_account: account).count

        result = sync_service.sync_to_wide_table(options)

        # 记录测试后的数据数量
        after_count = AdsData.where(ads_account: account).count
        new_records = after_count - before_count

        if result
          puts "✅ 测试成功，新增 #{new_records} 条记录"

          # 显示breakdown数据示例
          if new_records > 0 && test[:breakdowns].any?
            recent_data = AdsData.where(ads_account: account)
                                .where(created_at: 1.minute.ago..Time.current)
                                .first

            if recent_data
              puts "   示例数据:"
              test[:breakdowns].each do |breakdown|
                case breakdown
                when 'age'
                  puts "   - 年龄段: #{recent_data.age_range}"
                when 'gender'
                  puts "   - 性别: #{recent_data.gender}"
                when 'country'
                  puts "   - 国家: #{recent_data.country_code}"
                when 'device_platform'
                  puts "   - 设备平台: #{recent_data.device_platform}"
                end
              end
            end
          end
        else
          puts "❌ 测试失败: #{sync_service.errors.join(', ')}"
        end

      rescue => e
        puts "❌ 测试异常: #{e.message}"
      end

      # 防止API频率限制
      sleep(1) if index < breakdown_tests.size - 1
    end

    puts "\n=== 测试完成 ==="
    total_records = AdsData.where(ads_account: account).count
    puts "账户总记录数: #{total_records}"

    # 显示breakdown数据统计
    puts "\n细分数据统计:"
    puts "- 有年龄段数据: #{AdsData.where(ads_account: account).where.not(age_range: nil).count}"
    puts "- 有性别数据: #{AdsData.where(ads_account: account).where.not(gender: nil).count}"
    puts "- 有国家数据: #{AdsData.where(ads_account: account).where.not(country_code: nil).count}"
    puts "- 有设备平台数据: #{AdsData.where(ads_account: account).where.not(device_platform: nil).count}"
  end

  desc "同步Facebook数据包含细分维度"
  task sync_with_breakdowns: :environment do
    puts "=== 同步Facebook数据（包含细分维度）==="

    facebook_accounts = AdsAccount.joins(:ads_platform)
                                 .where(ads_platforms: { slug: 'facebook' })
                                 .where(account_status: 'active')
                                 .where.not(access_token: [nil, ''])

    if facebook_accounts.empty?
      puts "未找到有效的Facebook广告账户"
      exit
    end

    facebook_accounts.each do |account|
      puts "\n同步账户: #{account.name} (#{account.account_id})"

      begin
        sync_service = FacebookAdsWideSyncService.new(account)

        # 使用最有效的breakdown组合
        options = {
          date_range: {
            since: 7.days.ago.strftime('%Y-%m-%d'),
            until: Date.current.strftime('%Y-%m-%d')
          },
          level: 'ad',
          breakdowns: %w[age gender],  # 基础细分维度
          clear_existing: true
        }

        result = sync_service.sync_to_wide_table(options)

        if result
          recent_count = AdsData.where(ads_account: account)
                              .where(created_at: 1.hour.ago..Time.current)
                              .count

          puts "✅ 同步成功，新增 #{recent_count} 条记录"

          # 显示细分数据统计
          breakdown_stats = AdsData.where(ads_account: account)
                                  .where(created_at: 1.hour.ago..Time.current)

          puts "细分数据统计:"
          puts "- 年龄段分布: #{breakdown_stats.group(:age_range).count}"
          puts "- 性别分布: #{breakdown_stats.group(:gender).count}"
        else
          puts "❌ 同步失败: #{sync_service.errors.join(', ')}"
        end

      rescue => e
        puts "❌ 同步异常: #{e.message}"
      end
    end

    puts "\n=== 同步完成 ==="
  end
end