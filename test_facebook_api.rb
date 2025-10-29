#!/usr/bin/env ruby
# 测试 Facebook API 字段展开

require_relative 'config/environment'

puts "=" * 80
puts "测试 Facebook API 字段展开"
puts "=" * 80
puts

# 从 Config 读取配置
config = Config.first
if config.blank?
  puts "❌ 错误：未找到系统配置"
  exit 1
end

if config.facebook_access_token.blank?
  puts "❌ 错误：Facebook 访问令牌未配置"
  exit 1
end

# 获取第一个 Facebook 广告账户
ads_account = AdsAccount.joins(:ads_platform)
                        .where(ads_platforms: { slug: 'facebook' })
                        .last

if ads_account.blank?
  puts "❌ 错误：未找到 Facebook 广告账户"
  exit 1
end

ACCESS_TOKEN = config.facebook_access_token
ACCOUNT_ID = ads_account.account_id

puts "配置信息:"
puts "  - 广告账户: #{ads_account.name} (#{ACCOUNT_ID})"
puts "  - 访问令牌: #{ACCESS_TOKEN[0..10]}...#{ACCESS_TOKEN[-10..-1]}"
puts

# 日期范围
since_date = (Date.today - 60).strftime('%Y-%m-%d')
until_date = Date.today.strftime('%Y-%m-%d')

puts "日期范围: #{since_date} ~ #{until_date}"
puts

# 构建字段查询
insights_fields = [
  'date_start',
  'date_stop',
  'impressions',
  'clicks',
  'spend',
  'actions',
  'action_values',
  'cost_per_action_type'
].join(',')

fields = "id,name,status,objective,adsets.limit(100){id,name,status,ads.limit(100){id,name,status,insights.time_range({'since':'#{since_date}','until':'#{until_date}'}).time_increment(1).level(ad).breakdowns(['hourly_stats_aggregated_by_advertiser_time_zone']){#{insights_fields}}}}"

puts "完整字段参数:"
puts fields
puts
puts "=" * 80
puts

url = "https://graph.facebook.com/v18.0/act_#{ACCOUNT_ID}/campaigns"

query_params = {
  access_token: ACCESS_TOKEN,
  fields: fields,
  limit: 5  # 只获取5个campaigns用于测试
}

puts "正在请求 Facebook API..."
puts "URL: #{url}"
puts

begin
  response = HTTParty.get(url, query: query_params, timeout: 60)

  puts "HTTP 状态码: #{response.code}"
  puts

  if response.success?
    data = response.parsed_response

    puts "✅ 请求成功！"
    puts
    puts "返回数据结构:"
    puts "  - data.keys: #{data.keys}"
    puts

    campaigns = data['data'] || []
    puts "获取到 #{campaigns.size} 个 campaigns"
    puts

    if campaigns.any?
      campaigns.each_with_index do |campaign, idx|
        puts "-" * 60
        puts "Campaign ##{idx + 1}: #{campaign['name']} (#{campaign['id']})"
        puts "  Status: #{campaign['status']}"

        adsets = campaign['adsets']&.dig('data') || []
        puts "  包含 #{adsets.size} 个 AdSets"

        adsets.first(2).each do |adset|
          puts "    - AdSet: #{adset['name']} (#{adset['id']})"

          ads = adset['ads']&.dig('data') || []
          puts "      包含 #{ads.size} 个 Ads"

          ads.first(2).each do |ad|
            puts "        - Ad: #{ad['name']} (#{ad['id']})"

            insights = ad['insights']&.dig('data') || []
            puts "          包含 #{insights.size} 条 Insights"

            if insights.any?
              first_insight = insights.first
              puts "          示例数据:"
              puts "            date_start: #{first_insight['date_start']}"
              puts "            hour: #{first_insight['hourly_stats_aggregated_by_advertiser_time_zone']}"
              puts "            impressions: #{first_insight['impressions']}"
              puts "            clicks: #{first_insight['clicks']}"
              puts "            spend: #{first_insight['spend']}"

              # 显示 actions
              if first_insight['actions']
                puts "            actions:"
                first_insight['actions'].each do |action|
                  puts "              - #{action['action_type']}: #{action['value']}"
                end
              end

              # 显示 action_values
              if first_insight['action_values']
                puts "            action_values:"
                first_insight['action_values'].each do |av|
                  puts "              - #{av['action_type']}: #{av['value']}"
                end
              end
            end
          end
        end
      end

      puts
      puts "=" * 80
      puts "测试总结:"
      puts "=" * 80
      total_adsets = campaigns.sum { |c| (c['adsets']&.dig('data') || []).size }
      total_ads = campaigns.sum { |c| (c['adsets']&.dig('data') || []).sum { |a| (a['ads']&.dig('data') || []).size } }
      total_insights = campaigns.sum do |c|
        (c['adsets']&.dig('data') || []).sum do |a|
          (a['ads']&.dig('data') || []).sum { |ad| (ad['insights']&.dig('data') || []).size }
        end
      end

      puts "  - Campaigns: #{campaigns.size}"
      puts "  - AdSets: #{total_adsets}"
      puts "  - Ads: #{total_ads}"
      puts "  - Insights: #{total_insights}"
      puts

    else
      puts "⚠️  没有获取到任何 campaigns"
      puts
      puts "可能的原因："
      puts "  1. 该账户没有创建任何广告活动"
      puts "  2. 所有广告活动都已删除"
      puts "  3. 访问令牌权限不足"
    end

    puts
    puts "=" * 80
    puts "完整响应数据 (前1000字符):"
    puts "=" * 80
    json_str = JSON.pretty_generate(data)
    puts json_str[0..1000]
    if json_str.length > 1000
      puts "... (省略 #{json_str.length - 1000} 个字符)"
    end

  else
    puts "❌ 请求失败！"
    puts
    puts "错误响应:"
    puts response.body
  end

rescue StandardError => e
  puts "❌ 发生异常："
  puts e.message
  puts
  puts "Backtrace:"
  puts e.backtrace.first(10).join("\n")
end

puts
puts "=" * 80
