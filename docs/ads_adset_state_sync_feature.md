# 广告组状态同步功能（多平台支持）

## 功能概述

创建了通用的广告组状态同步系统，支持多个广告平台（Facebook、Google、TikTok 等）。该系统专门记录广告组的详细配置信息，包括状态、预算、出价、定向、素材等。

这个功能通过抽象的 Service 架构设计，独立于现有的数据同步服务，专注于获取广告组的配置和元数据。

## 架构设计

### 1. 数据表：`ads_adsets`（通用多平台表）

支持所有广告平台的广告组数据存储，通过 `platform` 字段区分不同平台。

#### 核心字段

**平台标识**
- `platform` - 广告平台标识（facebook, google, tiktok等）

**基本信息**
- `adset_id` - 广告组 ID（平台原生 ID）
- `adset_name` - 广告组名称

**关联信息**
- `ads_account_id` - 关联的广告账户
- `project_id` - 关联的项目
- `campaign_id` / `campaign_name` - 所属广告系列

**状态信息**
- `status` - 广告组状态（ACTIVE, PAUSED, ARCHIVED, DELETED）
- `effective_status` - 实际投放状态
- `is_active` - 是否正在投放（自动计算）

**预算信息**
- `daily_budget` - 每日预算（元）
- `lifetime_budget` - 总预算（元）
- `budget_remaining` - 剩余预算

**出价信息**
- `bid_amount` - 出价金额（元）
- `bid_strategy` - 出价策略
- `optimization_goal` - 优化目标
- `billing_event` - 计费事件

**时间信息**
- `start_time` - 开始时间
- `end_time` - 结束时间
- `platform_created_time` - 平台创建时间
- `platform_updated_time` - 平台更新时间

**JSON 字段（支持平台差异）**
- `targeting` - 定向设置（年龄、性别、地域、兴趣等）
- `promoted_object` - 推广对象（应用 ID、像素 ID等）
- `placement_settings` - 版位设置
- `creative_ids` - 关联的创意 ID 列表
- `creative_urls` - 素材 URL 列表
- `raw_data` - 平台 API 返回的原始数据
- `platform_specific_data` - 平台特定的额外数据

**性能快照**
- `impressions_snapshot` - 曝光量快照
- `clicks_snapshot` - 点击量快照
- `spend_snapshot` - 花费快照
- `conversions_snapshot` - 转化量快照

**同步信息**
- `synced_at` - 最后同步时间
- `sync_status` - 同步状态（pending, synced, error）
- `sync_error` - 同步错误信息

#### 索引设计

```ruby
# 唯一索引：平台 + 账户 + 广告组ID
add_index :ads_adsets, [:platform, :ads_account_id, :adset_id], unique: true

# 复合索引
add_index :ads_adsets, [:platform, :campaign_id]
add_index :ads_adsets, [:platform, :status]
add_index :ads_adsets, :synced_at
add_index :ads_adsets, :is_active
```

### 2. Model：`AdsAdset`

通用的广告组 Model，支持多平台数据管理。

#### 作用域

```ruby
# 平台筛选
AdsAdset.by_platform('facebook')
AdsAdset.facebook    # 快捷方法
AdsAdset.google
AdsAdset.tiktok

# 状态筛选
AdsAdset.active      # ACTIVE 状态
AdsAdset.paused      # PAUSED 状态
AdsAdset.archived    # ARCHIVED 状态
AdsAdset.running     # 正在投放（考虑时间范围）

# 其他
AdsAdset.by_campaign(campaign_id)
AdsAdset.recent_synced
AdsAdset.need_sync   # 需要同步的（超过1小时未同步）
```

#### 实例方法

```ruby
adset = AdsAdset.first

# 状态检查
adset.active?                       # => true/false

# 预算信息
adset.budget_type                   # => 'daily' / 'lifetime' / 'none'
adset.budget_amount                 # => 100.0

# 定向摘要（支持不同平台格式）
adset.targeting_summary             # => "年龄: 18-65岁 | 性别: 男/女 | 国家: US, CN"

# 版位摘要
adset.placement_summary             # => "feed, story, ..."

# 优化目标描述（根据平台自动翻译）
adset.optimization_goal_description # => "转化"

# 出价策略描述（根据平台自动翻译）
adset.bid_strategy_description      # => "最低成本（无上限）"

# 性能摘要
adset.performance_summary           # => { platform, adset_id, status, ... }
```

#### 类方法

```ruby
# 同步方法
AdsAdset.sync_all_needed(ads_account)

# 统计方法
AdsAdset.active_count_by_platform
# => {"facebook"=>45, "google"=>20, "tiktok"=>10}

AdsAdset.total_spend_by_platform
# => {"facebook"=>1500.0, "google"=>800.0, "tiktok"=>200.0}
```

### 3. Service：`AdsFetchAdStateService`（抽象基类）

抽象基类，定义了广告组同步的标准接口。

#### 工厂方法

```ruby
# 根据账户平台自动选择对应的 Service 实现
service = AdsFetchAdStateService.for(ads_account)
# 返回 AdsFetchAdStateService::Facebook 或 Google 或 TikTok
```

#### 必须实现的方法

子类必须实现：
- `sync_adsets` - 同步所有广告组
- `sync_adset(adset_id)` - 同步单个广告组

#### 通用方法

基类提供的通用方法：
- `validate_account` - 账户验证
- `save_or_update_adset(data, platform)` - 保存或更新数据
- `handle_sync_error(error)` - 错误处理
- `parse_time(time_str)` - 时间解析

### 4. Service 实现：`AdsFetchAdStateService::Facebook`

Facebook 平台的具体实现。

#### 初始化

```ruby
ads_account = AdsAccount.find_by(account_id: '4148846068680469')
service = AdsFetchAdStateService::Facebook.new(ads_account)
# 或使用工厂方法
service = AdsFetchAdStateService.for(ads_account)
```

#### 方法

```ruby
# 同步所有广告组
service.sync_adsets
# => true/false

# 同步单个广告组
service.sync_adset('23851234567890')
# => true/false

# 获取广告组的创意素材
creatives = service.fetch_adset_creatives('23851234567890')
# => [{ ad_id, ad_name, creative_id, image_url, video_id, ... }]
```

#### 数据转换

Facebook Service 负责将 Facebook API 返回的数据转换为标准格式：

```ruby
# Facebook API 返回的字段
facebook_data = {
  'id' => '23851234567890',
  'name' => 'My Adset',
  'daily_budget' => '10000',  # 100元（分）
  'bid_amount' => '500',      # 5元（分）
  # ...
}

# 转换为标准格式
standard_data = {
  adset_id: '23851234567890',
  adset_name: 'My Adset',
  daily_budget: 100.0,   # 自动转换为元
  bid_amount: 5.0,
  platform: 'facebook',
  # ...
}
```

### 5. Service 实现：`AdsFetchAdStateService::Google`（占位）

Google Ads 平台的实现（待开发）。

```ruby
class AdsFetchAdStateService::Google < AdsFetchAdStateService
  def sync_adsets
    # TODO: 实现 Google Ads API 调用
  end

  def sync_adset(adset_id)
    # TODO: 实现单个广告组同步
  end
end
```

### 6. Service 实现：`AdsFetchAdStateService::TikTok`（占位）

TikTok Ads 平台的实现（待开发）。

```ruby
class AdsFetchAdStateService::TikTok < AdsFetchAdStateService
  def sync_adsets
    # TODO: 实现 TikTok Ads API 调用
  end

  def sync_adset(adset_id)
    # TODO: 实现单个广告组同步
  end
end
```

## Rake 任务

提供了方便的命令行工具来管理多平台广告组同步。

### 同步所有平台的广告组

```bash
rake ads:sync_adsets
```

### 同步指定平台的广告组

```bash
# Facebook
rake ads:sync_adsets[facebook]

# Google
rake ads:sync_adsets[google]

# TikTok
rake ads:sync_adsets[tiktok]
```

### 同步指定账户的广告组

```bash
rake ads:sync_adsets[facebook,4148846068680469]
```

### 同步单个广告组

```bash
rake ads:sync_adset[4148846068680469,23851234567890]
```

### 查看统计信息

```bash
# 所有平台统计
rake ads:adsets_stats

# 指定平台统计
rake ads:adsets_stats[facebook]
```

输出示例：
```
全平台广告组统计
==================================================
总数: 150
状态:
  - ACTIVE:   75
  - PAUSED:   50
  - ARCHIVED: 25
  - 正在投放: 65

按平台统计:
  - FACEBOOK: 45 个活跃广告组
  - GOOGLE: 20 个活跃广告组
  - TIKTOK: 10 个活跃广告组

按平台花费:
  - FACEBOOK: $1500.00
  - GOOGLE: $800.00
  - TIKTOK: $200.00

最近同步的 5 个广告组:
  - [FACEBOOK] Summer Campaign - Adset 1 (ACTIVE) - 2025-10-30 15:30
  - [GOOGLE] Winter Campaign - Adset 2 (PAUSED) - 2025-10-30 15:28
  ...
```

### 清理过期数据

```bash
# 清理所有平台的过期数据（90天前）
rake ads:cleanup_adsets[90]

# 清理指定平台的过期数据
rake ads:cleanup_adsets[90,facebook]
```

### 向后兼容

旧的 Facebook 命名空间仍然可用（已废弃）：

```bash
# 会显示废弃警告，然后调用新的任务
rake facebook:sync_adsets
rake facebook:adsets_stats
```

## 使用示例

### 1. Ruby 代码中使用

```ruby
# 获取 Facebook 账户
facebook_account = AdsAccount.joins(:ads_platform)
                             .where(ads_platforms: { slug: 'facebook' })
                             .first

# 自动选择对应的 Service
service = AdsFetchAdStateService.for(facebook_account)

# 同步广告组
service.sync_adsets

# 检查错误
if service.errors.any?
  puts "错误: #{service.errors.join(', ')}"
end
```

### 2. 查询不同平台的数据

```ruby
# Facebook 活跃广告组
facebook_adsets = AdsAdset.facebook.active

# Google 正在投放的广告组
google_running = AdsAdset.google.running

# 所有平台的高花费广告组
high_spend = AdsAdset.where('spend_snapshot > ?', 1000)
                    .order(spend_snapshot: :desc)

high_spend.each do |adset|
  puts "[#{adset.platform.upcase}] #{adset.adset_name}: $#{adset.spend_snapshot}"
end
```

### 3. 平台对比分析

```ruby
# 各平台活跃广告组数量
platform_counts = AdsAdset.active_count_by_platform
# => {"facebook"=>45, "google"=>20, "tiktok"=>10}

# 各平台总花费
platform_spends = AdsAdset.total_spend_by_platform
# => {"facebook"=>1500.0, "google"=>800.0, "tiktok"=>200.0}

# 各平台平均出价
AdsAdset.group(:platform).average(:bid_amount)
# => {"facebook"=>5.0, "google"=>8.0, "tiktok"=>3.0}
```

### 4. 定向分析

```ruby
# Facebook 广告组的定向摘要
facebook_adset = AdsAdset.facebook.first
puts facebook_adset.targeting_summary
# => "年龄: 18-35岁 | 性别: 男 | 国家: US, UK | 兴趣: 5个"

# 访问原始定向数据
targeting = facebook_adset.targeting
age_range = "#{targeting['age_min']}-#{targeting['age_max']}"
countries = targeting.dig('geo_locations', 'countries')
```

### 5. 定时任务

```ruby
# config/schedule.rb (whenever gem)
every 1.hour do
  rake "ads:sync_adsets[facebook]"
end

every 2.hours do
  rake "ads:sync_adsets[google]"
end

every 1.day, at: '3:00 am' do
  rake "ads:cleanup_adsets[90]"
end
```

## 平台差异处理

### Facebook

- 金额单位：分（自动转换为元）
- 状态：ACTIVE, PAUSED, ARCHIVED, DELETED
- 优化目标：IMPRESSIONS, LINK_CLICKS, CONVERSIONS等
- 出价策略：LOWEST_COST_WITHOUT_CAP, COST_CAP等

### Google（待实现）

- 金额单位：微元（需转换）
- 状态：ENABLED, PAUSED, REMOVED
- 优化目标：MAXIMIZE_CLICKS, TARGET_CPA等
- 出价策略：MANUAL_CPC, ENHANCED_CPC, TARGET_ROAS等

### TikTok（待实现）

- 金额单位：分（类似 Facebook）
- 状态：ENABLE, DISABLE, DELETE
- 优化目标：CLICK, INSTALL, PURCHASE等
- 出价策略：BID_TYPE_NO_BID, BID_TYPE_CUSTOM

## 数据流程

```
用户触发同步
  ↓
AdsFetchAdStateService.for(ads_account)
  ├─ facebook → AdsFetchAdStateService::Facebook
  ├─ google → AdsFetchAdStateService::Google
  └─ tiktok → AdsFetchAdStateService::TikTok
  ↓
Service.sync_adsets
  ↓
验证账户和令牌
  ↓
从平台 API 获取广告组列表
  ↓
处理分页，获取所有广告组
  ↓
遍历每个广告组
  ├─ 转换为标准格式
  ├─ 保存到 ads_adsets 表
  ├─ 标记 platform 字段
  └─ 获取关联的创意素材
  ↓
更新同步状态和时间
  ↓
完成
```

## 扩展新平台

要添加新平台支持，只需：

### 1. 创建新的 Service 类

```ruby
# app/services/ads_fetch_ad_state_service/twitter.rb
class AdsFetchAdStateService::Twitter < AdsFetchAdStateService
  def initialize(ads_account)
    super(ads_account)
    # 初始化 Twitter Ads API 客户端
    @api_key = ENV['TWITTER_API_KEY']
    @api_secret = ENV['TWITTER_API_SECRET']
  end

  def sync_adsets
    # 实现 Twitter Ads API 调用逻辑
    # ...
  end

  def sync_adset(adset_id)
    # 实现单个广告组同步
    # ...
  end

  private

  def fetch_from_twitter_api
    # Twitter API 调用
  end

  def convert_to_standard_format(twitter_data)
    # 转换为标准格式
    {
      adset_id: twitter_data['id'],
      adset_name: twitter_data['name'],
      platform: 'twitter',
      # ...
    }
  end
end
```

### 2. 更新工厂方法

```ruby
# app/services/ads_fetch_ad_state_service.rb
def self.for(ads_account)
  platform = ads_account.ads_platform.slug

  case platform
  when 'facebook'
    AdsFetchAdStateService::Facebook.new(ads_account)
  when 'google'
    AdsFetchAdStateService::Google.new(ads_account)
  when 'tiktok'
    AdsFetchAdStateService::TikTok.new(ads_account)
  when 'twitter'   # 新增
    AdsFetchAdStateService::Twitter.new(ads_account)
  else
    raise "不支持的平台: #{platform}"
  end
end
```

### 3. 更新 Model 验证

```ruby
# app/models/ads_adset.rb
validates :platform, presence: true,
          inclusion: { in: %w[facebook google tiktok twitter] }  # 添加 twitter
```

### 4. 使用

```ruby
# 自动使用 Twitter Service
twitter_account = AdsAccount.joins(:ads_platform)
                            .where(ads_platforms: { slug: 'twitter' })
                            .first

service = AdsFetchAdStateService.for(twitter_account)
service.sync_adsets

# 查询 Twitter 数据
twitter_adsets = AdsAdset.by_platform('twitter')
```

## 注意事项

1. **平台验证**
   - 每个平台有自己的令牌验证逻辑
   - 在 Service 子类中实现 `validate_*_token` 方法

2. **金额单位**
   - Facebook: 分 → 元（÷ 100）
   - Google: 微元 → 元（÷ 1,000,000）
   - TikTok: 分 → 元（÷ 100）

3. **时间格式**
   - 统一转换为 Rails DateTime
   - 使用基类的 `parse_time` 方法

4. **JSON 字段**
   - `targeting` - 各平台格式不同，原样存储
   - `platform_specific_data` - 存储平台特有字段

5. **同步频率**
   - 建议每小时同步一次
   - 避免频繁调用（API 有速率限制）

6. **错误处理**
   - 同步失败时记录到 `sync_error`
   - 不影响其他账户的同步

## 文件结构

```
ads-automate/
├── db/migrate/
│   └── 20251030080708_create_ads_adsets.rb
├── app/
│   ├── models/
│   │   └── ads_adset.rb
│   └── services/
│       ├── ads_fetch_ad_state_service.rb (基类)
│       └── ads_fetch_ad_state_service/
│           ├── facebook.rb (Facebook 实现)
│           ├── google.rb (Google 占位)
│           └── tik_tok.rb (TikTok 占位)
├── lib/tasks/
│   └── ads_adsets.rake
└── docs/
    └── ads_adset_state_sync_feature.md (本文档)
```

## 总结

✅ **通用的多平台架构** - 支持 Facebook、Google、TikTok 等多个平台
✅ **抽象的 Service 设计** - 易于扩展新平台
✅ **统一的数据模型** - 所有平台共用一个表
✅ **灵活的 JSON 存储** - 支持平台特定数据
✅ **完善的 Rake 任务** - 方便的命令行工具
✅ **向后兼容** - 保留旧的 Facebook 命名空间
✅ **丰富的查询方法** - 支持多维度数据分析

---

**创建时间**: 2025-10-30
**状态**: 已完成 ✅
**当前实现**: Facebook ✅ | Google ⏳ | TikTok ⏳
