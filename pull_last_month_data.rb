# 拉取最近一个月的Facebook广告数据

puts "=== 拉取最近一个月的Facebook广告数据 ==="

# 获取已创建的广告账户
ads_account = AdsAccount.find_by(account_id: "4148846068680469")
if ads_account.nil?
  puts "广告账户未找到，请先创建广告账户"
  exit 1
end

puts "使用广告账户: #{ads_account.name} (#{ads_account.account_id})"

# 清理旧数据（可选）
puts "\n=== 清理旧数据 ==="
old_count = AdsData.where(ads_account: ads_account).count
puts "当前数据记录数: #{old_count}"

# 询问是否清理旧数据
print "是否清理旧数据？(y/N): "
response = gets.chomp.downcase
if response == 'y' || response == 'yes'
  AdsData.where(ads_account: ads_account).delete_all
  puts "已清理旧数据"
else
  puts "保留现有数据"
end

# 设置时间范围 - 最近30天
date_range = {
  since: 30.days.ago.strftime("%Y-%m-%d"),
  until: Date.current.strftime("%Y-%m-%d")
}

puts "\n=== 开始数据同步 ==="
puts "时间范围: #{date_range[:since]} 到 #{date_range[:until]}"

sync_service = FacebookAdsWideSyncService.new(ads_account)

begin
  # 首先同步活动级别数据
  puts "\n1. 同步活动级别数据..."
  result1 = sync_service.sync_to_wide_table(
    date_range: date_range,
    level: "campaign",
    time_increment: "day"
  )

  if result1
    puts "✓ 活动级别数据同步成功"
  else
    puts "✗ 活动级别数据同步失败: #{sync_service.errors.join(', ')}"
  end

  # 然后同步广告组级别数据
  puts "\n2. 同步广告组级别数据..."
  sync_service.errors.clear
  result2 = sync_service.sync_to_wide_table(
    date_range: date_range,
    level: "adset",
    time_increment: "day"
  )

  if result2
    puts "✓ 广告组级别数据同步成功"
  else
    puts "✗ 广告组级别数据同步失败: #{sync_service.errors.join(', ')}"
  end

  # 最后同步广告级别数据（最详细）
  puts "\n3. 同步广告级别数据..."
  sync_service.errors.clear
  result3 = sync_service.sync_to_wide_table(
    date_range: date_range,
    level: "ad",
    time_increment: "day",
    breakdowns: ['publisher_platform', 'device_platform']
  )

  if result3
    puts "✓ 广告级别数据同步成功"
  else
    puts "✗ 广告级别数据同步失败: #{sync_service.errors.join(', ')}"
  end

rescue => e
  puts "✗ 同步过程异常: #{e.message}"
  puts "错误堆栈:"
  puts e.backtrace.first(5).join("\n")
end

# 检查同步结果
puts "\n=== 数据同步结果统计 ==="
total_count = AdsData.where(ads_account: ads_account).count
puts "总记录数: #{total_count}"

if total_count > 0
  # 按不同标识统计
  campaign_level_count = AdsData.where(ads_account: ads_account).where.not(campaign_id: nil).where(adset_id: nil, ad_id: nil).count
  adset_level_count = AdsData.where(ads_account: ads_account).where.not(adset_id: nil).where(ad_id: nil).count
  ad_level_count = AdsData.where(ads_account: ads_account).where.not(ad_id: nil).count

  puts "按数据级别统计:"
  puts "- 活动级别: #{campaign_level_count} 条"
  puts "- 广告组级别: #{adset_level_count} 条"
  puts "- 广告级别: #{ad_level_count} 条"

  # 时间范围统计
  puts "\n按日期统计:"
  date_stats = AdsData.where(ads_account: ads_account)
                      .group(:date)
                      .count
                      .sort_by { |date, _| date }

  puts "总共 #{date_stats.size} 天的数据"
  if date_stats.size <= 10
    date_stats.each do |date, count|
      puts "  #{date}: #{count} 条记录"
    end
  else
    puts "  最早: #{date_stats.first[0]} (#{date_stats.first[1]} 条)"
    puts "  最晚: #{date_stats.last[0]} (#{date_stats.last[1]} 条)"
    puts "  平均每天: #{(total_count.to_f / date_stats.size).round(1)} 条"
  end

  # 核心指标汇总
  puts "\n=== 核心指标汇总 ==="
  total_stats = AdsData.where(ads_account: ads_account).sum_metrics
  puts "30天汇总数据:"
  puts "- 总展示数: #{total_stats[:impressions].to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse}"
  puts "- 总点击数: #{total_stats[:clicks].to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse}"
  puts "- 总花费: $#{sprintf('%.2f', total_stats[:spend])}"
  puts "- 总转化数: #{total_stats[:conversions]}"
  puts "- 总转化价值: $#{sprintf('%.2f', total_stats[:conversion_value])}"

  # 平均指标
  avg_stats = AdsData.calculate_averages(AdsData.where(ads_account: ads_account))
  puts "\n30天平均指标:"
  puts "- 平均CTR: #{sprintf('%.4f', avg_stats[:avg_ctr])}%"
  puts "- 平均CPM: $#{sprintf('%.4f', avg_stats[:avg_cpm])}"
  puts "- 平均CPC: $#{sprintf('%.4f', avg_stats[:avg_cpc])}"
  puts "- 平均转化率: #{sprintf('%.4f', avg_stats[:avg_conversion_rate])}%" if avg_stats[:avg_conversion_rate]
  puts "- 平均转化成本: $#{sprintf('%.4f', avg_stats[:avg_cost_per_conversion])}" if avg_stats[:avg_cost_per_conversion]
  puts "- 平均ROAS: #{sprintf('%.4f', avg_stats[:avg_roas])}" if avg_stats[:avg_roas]

  # 表现最好的活动
  puts "\n=== 表现最好的活动 TOP 5 ==="
  top_campaigns = AdsData.where(ads_account: ads_account)
                          .group(:campaign_name)
                          .sum(:spend)
                          .sort_by { |_, spend| -spend }
                          .first(5)

  top_campaigns.each_with_index do |(campaign_name, spend), i|
    campaign_data = AdsData.where(ads_account: ads_account, campaign_name: campaign_name)
    total_impressions = campaign_data.sum(:impressions)
    total_clicks = campaign_data.sum(:clicks)
    ctr = total_clicks > 0 ? (total_clicks.to_f / total_impressions * 100) : 0

    puts "#{i+1}. #{campaign_name}"
    puts "   花费: $#{sprintf('%.2f', spend)} | 展示: #{total_impressions} | 点击: #{total_clicks} | CTR: #{sprintf('%.2f', ctr)}%"
  end

else
  puts "没有同步到任何数据"
end

puts "\n=== 数据拉取完成 ==="