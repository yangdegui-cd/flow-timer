# 测试有真实数据的Facebook广告账户同步

puts "=== 测试有真实数据的Facebook广告账户同步 ==="

# 使用现有的用户和项目
user = SysUser.first
project = Project.find_by(name: "Facebook广告测试项目-20250929065306") || Project.last
facebook_platform = AdsPlatform.find_by(slug: "facebook")

puts "使用用户: #{user.name}"
puts "使用项目: #{project.name}"

# 创建MH-L11-WW-02账户记录
ads_account = AdsAccount.create!(
  name: "MH-L11-WW-02",
  account_id: "4148846068680469",
  ads_platform: facebook_platform,
  project: project,
  sys_user: user,
  access_token: "EAALQGnCUegIBPqbtQVhrfHIQCGHXKV8SYWTBI4QpP5bSsVRmp4RpErFQGRBLZAN9r0ID3xws88RAo6nYPIEI3BR726ggXXG09NZBVAmPXGWcOxnuNbyEfUAzEfQkJzIhwkdreHPTTWAbm0QqFVHCD6YMZCYc1K7IJeGd8hyVr7HISoJMsyJS19roQNTKZCrwvFZCS7BXbhQjVDhpt",
  currency: "USD",
  timezone: "Etc/GMT+0",
  account_status: "active"
)

puts "创建广告账户: #{ads_account.name} (#{ads_account.account_id})"

# 先测试获取一个活动的洞察数据
puts "\n=== 测试获取洞察数据 ==="
campaign_id = "120233634805800731" # MH02-L11-AND-Global-MAIA-0921星耀划线玩法_现场BGM-0922

begin
  url = "https://graph.facebook.com/v18.0/#{campaign_id}/insights"
  response = HTTParty.get(url, query: {
    access_token: ads_account.access_token,
    fields: "campaign_id,campaign_name,date_start,date_stop,impressions,clicks,spend,reach,frequency",
    time_range: { since: "2025-09-20", until: "2025-09-29" },
    time_increment: "day",
    level: "campaign"
  })

  if response.success?
    insights = response.parsed_response["data"]
    puts "✓ 找到 #{insights.size} 条洞察记录"
    insights.each do |insight|
      puts "  日期: #{insight['date_start']} - 展示: #{insight['impressions']}, 点击: #{insight['clicks']}, 花费: #{insight['spend']}"
    end
  else
    puts "✗ 洞察数据获取失败: #{response.body}"
  end
rescue => e
  puts "✗ 获取洞察数据异常: #{e.message}"
end

# 开始完整的数据同步
puts "\n=== 开始完整数据同步 ==="
sync_service = FacebookAdsWideSyncService.new(ads_account)

begin
  # 同步最近10天的数据，使用活动级别
  result = sync_service.sync_to_wide_table(
    date_range: {
      since: 10.days.ago.strftime("%Y-%m-%d"),
      until: Date.current.strftime("%Y-%m-%d")
    },
    level: "campaign"  # 先用活动级别测试，速度更快
  )

  if result
    puts "✓ 数据同步成功"
  else
    puts "✗ 数据同步失败"
    puts "错误: #{sync_service.errors.join(', ')}"
  end
rescue => e
  puts "✗ 同步过程异常: #{e.message}"
  puts "错误堆栈:"
  puts e.backtrace.first(5).join("\n")
end

# 检查同步结果
puts "\n=== 检查同步结果 ==="
ads_data_count = AdsData.where(ads_account: ads_account).count
puts "同步的广告数据记录数: #{ads_data_count}"

if ads_data_count > 0
  puts "\n最新5条记录示例:"
  AdsData.where(ads_account: ads_account).order(:date).last(5).each_with_index do |data, i|
    puts "#{i+1}. 日期: #{data.date}, 活动: #{data.campaign_name}"
    puts "   展示: #{data.impressions}, 点击: #{data.clicks}, 花费: $#{data.spend}"
    puts "   CTR: #{data.calculated_ctr}%, CPM: $#{data.calculated_cpm}, CPC: $#{data.calculated_cpc}"
    puts ""
  end

  # 统计数据
  puts "=== 数据统计汇总 ==="
  total_stats = AdsData.where(ads_account: ads_account).sum_metrics
  puts "总计数据:"
  puts "- 总展示数: #{total_stats[:impressions].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  puts "- 总点击数: #{total_stats[:clicks].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  puts "- 总花费: $#{sprintf('%.2f', total_stats[:spend])}"
  puts "- 总转化数: #{total_stats[:conversions]}"
  puts "- 总转化价值: $#{sprintf('%.2f', total_stats[:conversion_value])}"

  # 平均指标
  avg_stats = AdsData.calculate_averages(AdsData.where(ads_account: ads_account))
  puts "\n平均指标:"
  puts "- 平均CTR: #{sprintf('%.4f', avg_stats[:avg_ctr])}%"
  puts "- 平均CPM: $#{sprintf('%.4f', avg_stats[:avg_cpm])}"
  puts "- 平均CPC: $#{sprintf('%.4f', avg_stats[:avg_cpc])}"
  puts "- 平均转化率: #{sprintf('%.4f', avg_stats[:avg_conversion_rate])}%"
  puts "- 平均转化成本: $#{sprintf('%.4f', avg_stats[:avg_cost_per_conversion])}"
  puts "- 平均ROAS: #{sprintf('%.4f', avg_stats[:avg_roas])}"
else
  puts "没有同步到任何数据"
end

puts "\n=== 测试完成 ==="