# Facebook广告数据同步测试脚本

puts "=== Facebook广告数据同步测试 ==="

# 使用现有的用户
user = SysUser.first
puts "使用用户: #{user.name} (ID: #{user.id})"

# 创建项目
project = Project.create!(
  name: "Facebook广告测试项目-#{Time.current.strftime('%Y%m%d%H%M%S')}",
  description: "用于测试Facebook广告数据同步",
  status: "active",
  start_date: Date.current
)
puts "创建项目: #{project.name} (ID: #{project.id})"

# 获取Facebook平台
facebook_platform = AdsPlatform.find_by(slug: "facebook")
puts "Facebook平台: #{facebook_platform.name}"

# 创建广告账户记录
ads_account = AdsAccount.create!(
  name: "杨德贵",
  account_id: "1732112470254152",
  ads_platform: facebook_platform,
  project: project,
  sys_user: user,
  access_token: "EAALQGnCUegIBPqbtQVhrfHIQCGHXKV8SYWTBI4QpP5bSsVRmp4RpErFQGRBLZAN9r0ID3xws88RAo6nYPIEI3BR726ggXXG09NZBVAmPXGWcOxnuNbyEfUAzEfQkJzIhwkdreHPTTWAbm0QqFVHCD6YMZCYc1K7IJeGd8hyVr7HISoJMsyJS19roQNTKZCrwvFZCS7BXbhQjVDhpt",
  currency: "CNY",
  timezone: "Asia/Shanghai",
  account_status: "active"
)

puts "创建广告账户: #{ads_account.name} (#{ads_account.account_id})"
puts "关联用户: #{ads_account.sys_user.name}"
puts "关联项目: #{ads_account.project.name}"

# 先测试令牌是否有效
puts "\n=== 测试Facebook API访问令牌 ==="
token_service = FacebookTokenService.new(ads_account)
if token_service.validate_token
  puts "✓ 访问令牌有效"
else
  puts "✗ 访问令牌无效"
  exit 1
end

# 测试获取广告账户信息
puts "\n=== 获取Facebook广告账户信息 ==="
begin
  url = "https://graph.facebook.com/v18.0/act_#{ads_account.account_id}"
  response = HTTParty.get(url, query: {
    access_token: ads_account.access_token,
    fields: "id,name,currency,timezone_name,account_status"
  })

  if response.success?
    account_info = response.parsed_response
    puts "✓ 账户信息获取成功:"
    puts "  - 账户ID: #{account_info['id']}"
    puts "  - 账户名: #{account_info['name']}"
    puts "  - 货币: #{account_info['currency']}"
    puts "  - 时区: #{account_info['timezone_name']}"
    puts "  - 状态: #{account_info['account_status']}"
  else
    puts "✗ 账户信息获取失败: #{response.body}"
    exit 1
  end
rescue => e
  puts "✗ API请求异常: #{e.message}"
  exit 1
end

# 测试获取广告活动列表
puts "\n=== 获取广告活动列表 ==="
begin
  url = "https://graph.facebook.com/v18.0/act_#{ads_account.account_id}/campaigns"
  response = HTTParty.get(url, query: {
    access_token: ads_account.access_token,
    fields: "id,name,status,objective",
    limit: 5
  })

  if response.success?
    campaigns = response.parsed_response['data']
    puts "✓ 找到 #{campaigns.size} 个广告活动:"
    campaigns.each do |campaign|
      puts "  - #{campaign['name']} (#{campaign['id']}) - #{campaign['status']}"
    end
  else
    puts "✗ 广告活动获取失败: #{response.body}"
  end
rescue => e
  puts "✗ 获取广告活动异常: #{e.message}"
end

# 开始数据同步测试
puts "\n=== 开始Facebook广告数据同步测试 ==="
sync_service = FacebookReportService.new(ads_account)

begin
  # 同步最近3天的数据
  result = sync_service.fetch_recent_data(
    date_range: {
      since: 3.days.ago.strftime("%Y-%m-%d"),
      until: Date.current.strftime("%Y-%m-%d")
    },
    level: "ad"
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
  AdsData.where(ads_account: ads_account).order(:created_at).last(5).each_with_index do |data, i|
    puts "#{i+1}. 日期: #{data.date}, 平台: #{data.platform}, 活动: #{data.campaign_name}"
    puts "   展示: #{data.impressions}, 点击: #{data.clicks}, 花费: #{data.spend}"
    puts "   CTR: #{data.calculated_ctr}%, CPC: #{data.calculated_cpc}, CPM: #{data.calculated_cpm}"
  end

  # 统计数据
  puts "\n=== 数据统计 ==="
  total_stats = AdsData.where(ads_account: ads_account).sum_metrics
  puts "总计数据:"
  puts "- 总展示数: #{total_stats[:impressions]}"
  puts "- 总点击数: #{total_stats[:clicks]}"
  puts "- 总花费: #{total_stats[:spend]}"
  puts "- 总转化数: #{total_stats[:conversions]}"
  puts "- 总转化价值: #{total_stats[:conversion_value]}"
else
  puts "没有同步到任何数据"
end

puts "\n=== 测试完成 ==="
