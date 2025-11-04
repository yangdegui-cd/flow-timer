namespace :ads do
  desc "同步广告状态信息（支持多平台）"
  task :sync_states, [:platform, :account_id] => :environment do |t, args|
    platform = args[:platform] || 'all'

    if args[:account_id].present?
      # 同步指定账户
      ads_account = AdsAccount.find_by(account_id: args[:account_id])

      unless ads_account
        puts "错误: 未找到账户 #{args[:account_id]}"
        exit 1
      end

      puts "开始同步账户 #{ads_account.name} (#{ads_account.account_id}) 的广告组信息..."

      service = AdsFetchAdStateService.for(ads_account)
      if service.sync_all
        puts "✓ 同步成功"
      else
        puts "✗ 同步失败: #{service.errors.join(', ')}"
        exit 1
      end
    else
      # 同步指定平台或所有平台的账户
      platforms = if platform == 'all'
        AdsPlatform.pluck(:slug)
      else
        [platform]
      end

      total_success = 0
      total_error = 0

      platforms.each do |platform_slug|
        ads_platform = AdsPlatform.find_by(slug: platform_slug)

        unless ads_platform
          puts "警告: 未找到平台 #{platform_slug}"
          next
        end

        ads_accounts = ads_platform.ads_accounts

        if ads_accounts.empty?
          puts "#{platform_slug.upcase}: 未找到任何广告账户"
          next
        end

        puts "\n" + "="*50
        puts "#{platform_slug.upcase}: 找到 #{ads_accounts.size} 个广告账户"
        puts "="*50

        success_count = 0
        error_count = 0

        ads_accounts.each do |ads_account|
          puts "\n同步账户: #{ads_account.name} (#{ads_account.account_id})"

          begin
            service = AdsFetchAdStateService.for(ads_account)
            if service.sync_all
              puts "  ✓ 成功"
              success_count += 1
            else
              puts "  ✗ 失败: #{service.errors.join(', ')}"
              error_count += 1
            end
          rescue StandardError => e
            puts "  ✗ 错误: #{e.message}"
            error_count += 1
          end
        end

        puts "\n#{platform_slug.upcase} 同步完成: 成功 #{success_count} 个, 失败 #{error_count} 个"

        total_success += success_count
        total_error += error_count
      end

      puts "\n" + "="*50
      puts "总计: 成功 #{total_success} 个, 失败 #{total_error} 个"
    end
  end

  desc "显示广告状态统计信息"
  task :states_stats, [:platform] => :environment do |t, args|
    platform = args[:platform]

    ad_states = if platform.present?
      AdState.by_platform(platform)
    else
      AdState.all
    end

    total = ad_states.count
    active = ad_states.active.count

    title = platform.present? ? "#{platform.upcase} 广告状态统计" : "全平台广告状态统计"

    puts title
    puts "="*50
    puts "总数: #{total}"
    puts "  - 正在投放: #{active}"

    # 按平台统计
    if platform.blank?
      puts "\n按平台统计:"
      platform_stats = AdState.active_count_by_platform
      platform_stats.each do |p, count|
        puts "  - #{p.upcase}: #{count} 个活跃广告"
      end
    end

    # 按广告系列统计
    puts "\n按广告系列统计（前10）:"
    campaign_stats = ad_states.count_by_campaign.sort_by { |_, count| -count }.first(10)
    campaign_stats.each do |(platform, campaign_id, campaign_name), count|
      puts "  - [#{platform.upcase}] #{campaign_name}: #{count} 个广告"
    end

    # 素材统计
    video_count = ad_states.video_ads.count
    image_count = ad_states.image_ads.count
    puts "\n素材类型统计:"
    puts "  - 视频广告: #{video_count}"
    puts "  - 图片广告: #{image_count}"

    if total > 0
      recent = ad_states.recent_synced.limit(5)
      puts "\n最近同步的 5 个广告:"
      recent.each do |ad_state|
        puts "  - [#{ad_state.platform.upcase}] #{ad_state.ad_name} - #{ad_state.synced_at&.strftime('%Y-%m-%d %H:%M')}"
      end
    end
  end
end
