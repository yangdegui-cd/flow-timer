# 广告组状态同步 - 快速开始

## 快速概览

这是一个**多平台通用**的广告组配置同步系统，用于获取和存储广告组的状态、预算、出价、定向、素材等信息。

### 支持的平台

- ✅ **Facebook** - 已实现
- ⏳ **Google** - 待实现
- ⏳ **TikTok** - 待实现

### 核心组件

1. **数据表** - `ads_adsets`（通用多平台表）
2. **Model** - `AdsAdset`
3. **Service** - `AdsFetchAdStateService`（抽象基类）
4. **实现** - `AdsFetchAdStateService::Facebook`（及其他平台）

## 快速使用

### 同步 Facebook 广告组

```bash
# 同步所有 Facebook 账户的广告组
rake ads:sync_adsets[facebook]

# 同步指定账户
rake ads:sync_adsets[facebook,4148846068680469]

# 同步单个广告组
rake ads:sync_adset[4148846068680469,23851234567890]
```

### 查看统计信息

```bash
# 所有平台
rake ads:adsets_stats

# 指定平台
rake ads:adsets_stats[facebook]
```

### Ruby 代码中使用

```ruby
# 自动选择对应平台的 Service
ads_account = AdsAccount.find_by(account_id: '4148846068680469')
service = AdsFetchAdStateService.for(ads_account)

# 同步
service.sync_adsets
```

### 查询数据

```ruby
# Facebook 活跃广告组
AdsAdset.facebook.active

# 所有正在投放的广告组
AdsAdset.running

# 高花费广告组
AdsAdset.where('spend_snapshot > ?', 1000)
       .order(spend_snapshot: :desc)

# 按平台统计
AdsAdset.active_count_by_platform
# => {"facebook"=>45, "google"=>20}

AdsAdset.total_spend_by_platform
# => {"facebook"=>1500.0, "google"=>800.0}
```

### 获取广告组详情

```ruby
adset = AdsAdset.facebook.first

# 基本信息
adset.adset_name          # "Summer Campaign - Adset 1"
adset.status              # "ACTIVE"
adset.active?             # true

# 预算信息
adset.budget_type         # "daily"
adset.budget_amount       # 100.0
adset.bid_amount          # 5.0

# 定向摘要
adset.targeting_summary
# => "年龄: 18-35岁 | 性别: 男 | 国家: US, UK | 兴趣: 5个"

# 性能快照
adset.impressions_snapshot
adset.clicks_snapshot
adset.spend_snapshot
adset.conversions_snapshot
```

## 数据库结构

### 核心字段

```
platform             平台标识
adset_id             广告组ID
adset_name           名称
status               状态
is_active            是否投放中
daily_budget         每日预算
bid_amount           出价金额
optimization_goal    优化目标
targeting            定向设置（JSON）
creative_urls        素材URL列表（JSON）
synced_at            同步时间
```

### 索引

```ruby
# 唯一索引
[:platform, :ads_account_id, :adset_id]

# 查询索引
[:platform, :campaign_id]
[:platform, :status]
:is_active
:synced_at
```

## 架构说明

### Service 继承关系

```
AdsFetchAdStateService (抽象基类)
  ├── Facebook (Facebook 实现)
  ├── Google (待实现)
  └── TikTok (待实现)
```

### 工厂模式

```ruby
# 自动根据账户平台选择对应的 Service
service = AdsFetchAdStateService.for(ads_account)

# 等价于
case ads_account.ads_platform.slug
when 'facebook'
  AdsFetchAdStateService::Facebook.new(ads_account)
when 'google'
  AdsFetchAdStateService::Google.new(ads_account)
# ...
end
```

## 定时任务

```ruby
# config/schedule.rb
every 1.hour do
  rake "ads:sync_adsets[facebook]"
end

every 1.day, at: '3:00 am' do
  rake "ads:cleanup_adsets[90,facebook]"
end
```

## 与 FacebookReportService 的区别

| 特性 | FacebookReportService | AdsFetchAdStateService |
|------|----------------------|------------------------|
| 目标 | 统计数据（insights） | 配置信息（adset config）|
| 数据类型 | 曝光、点击、花费 | 预算、出价、定向 |
| 存储表 | ads_data | ads_adsets |
| 时间维度 | 按日期/小时聚合 | 快照（当前状态） |
| 更新频率 | 每天同步历史数据 | 每小时同步最新配置 |
| 用途 | 数据分析、报表 | 广告管理、监控 |

## 扩展新平台

只需 3 步：

### 1. 创建 Service 类

```ruby
# app/services/ads_fetch_ad_state_service/google.rb
class AdsFetchAdStateService::Google < AdsFetchAdStateService
  def sync_adsets
    # 实现 Google Ads API 调用
  end

  def sync_adset(adset_id)
    # 实现单个广告组同步
  end
end
```

### 2. 更新工厂方法

```ruby
# app/services/ads_fetch_ad_state_service.rb
def self.for(ads_account)
  case ads_account.ads_platform.slug
  when 'facebook'
    Facebook.new(ads_account)
  when 'google'   # 新增
    Google.new(ads_account)
  # ...
  end
end
```

### 3. 开始使用

```ruby
google_account = AdsAccount.where(platform: 'google').first
service = AdsFetchAdStateService.for(google_account)
service.sync_adsets
```

## 常见问题

### Q: 如何处理不同平台的金额单位？

A: 在各平台的 Service 实现中转换：
- Facebook: 分 → 元（÷ 100）
- Google: 微元 → 元（÷ 1,000,000）
- 最终都存储为"元"

### Q: 如何存储平台特定的字段？

A: 使用两个 JSON 字段：
- `raw_data` - 存储完整的原始响应
- `platform_specific_data` - 存储提取的平台特有字段

### Q: 多久同步一次？

A: 建议每小时同步一次。可根据需要调整。

### Q: 如何查看同步错误？

A: 查看 `sync_status` 和 `sync_error` 字段：

```ruby
AdsAdset.where(sync_status: 'error').each do |adset|
  puts "#{adset.adset_name}: #{adset.sync_error}"
end
```

## 详细文档

查看完整文档：`docs/ads_adset_state_sync_feature.md`

---

**快速开始完成！** 🎉
