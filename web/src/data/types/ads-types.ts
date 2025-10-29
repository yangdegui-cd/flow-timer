// 广告数据分析相关类型定义

/** 时间粒度枚举 */
export enum TimeGranularity {
  HOUR = 'hour',
  DAY = 'day',
  WEEK = 'week',
  MONTH = 'month'
}

/** 广告平台枚举 */
export enum AdsPlatform {
  FACEBOOK = 'Facebook',
  GOOGLE = 'Google',
  TIKTOK = 'TikTok',
  TWITTER = 'Twitter',
  LINKEDIN = 'LinkedIn'
}

/** 投放目标类型 */
export enum ObjectiveType {
  AWARENESS = 'AWARENESS',
  TRAFFIC = 'TRAFFIC',
  ENGAGEMENT = 'ENGAGEMENT',
  LEADS = 'LEADS',
  APP_PROMOTION = 'APP_PROMOTION',
  SALES = 'SALES'
}

/** 广告素材类型 */
export enum CreativeType {
  IMAGE = 'image',
  VIDEO = 'video',
  CAROUSEL = 'carousel',
  COLLECTION = 'collection',
  DYNAMIC = 'dynamic'
}

/** 设备平台 */
export enum DevicePlatform {
  MOBILE = 'mobile',
  DESKTOP = 'desktop',
  TABLET = 'tablet'
}

/** 广告账户基础信息 */
export interface AdsAccount {
  id: number
  name: string
  account_id: string
  platform: AdsPlatform
  project: string
  currency: string
  timezone: string
  status: 'active' | 'paused' | 'disabled'
  data_count: number
  created_at: string
  updated_at: string
}

/** 广告系列详细信息 */
export interface AdsCampaign {
  id: string
  name: string
  objective: ObjectiveType
  status: 'active' | 'paused' | 'disabled'
  budget_type: 'daily' | 'lifetime'
  budget: number
  bid_strategy: string
  start_time: string
  end_time?: string
  ads_account_id: number
  created_at: string
  updated_at: string
}

/** 广告组详细信息 */
export interface AdsAdSet {
  id: string
  name: string
  campaign_id: string
  status: 'active' | 'paused' | 'disabled'
  budget_type: 'daily' | 'lifetime'
  budget: number
  bid_amount: number
  optimization_goal: string
  billing_event: string
  targeting: {
    age_min?: number
    age_max?: number
    genders?: string[]
    locations?: string[]
    interests?: string[]
    behaviors?: string[]
    custom_audiences?: string[]
  }
  start_time: string
  end_time?: string
  created_at: string
  updated_at: string
}

/** 广告素材详细信息 */
export interface AdsCreative {
  id: string
  name: string
  ad_id: string
  type: CreativeType
  title?: string
  body?: string
  call_to_action?: string
  image_url?: string
  video_url?: string
  link_url?: string
  status: 'active' | 'paused' | 'disabled'
  created_at: string
  updated_at: string
}

/** 详细广告数据项 */
export interface DetailedAdsDataItem {
  // 基础标识信息
  id: number
  unique_key: string
  datetime: string  // 支持小时级别：2024-01-01 14:00:00
  date: string      // 日期：2024-01-01
  hour: number      // 小时：0-23

  // 层级关系
  ads_account: AdsAccount
  campaign: AdsCampaign
  adset: AdsAdSet
  ad: {
    id: string
    name: string
    status: 'active' | 'paused' | 'disabled'
    creative: AdsCreative
  }

  // 投放设置维度
  device_platform: DevicePlatform  // 设备类型：mobile, desktop, tablet
  publisher_platform: string       // 发布商平台：Facebook, Instagram, Messenger, etc.
  platform_position: string        // 投放位置：feed, story, reel, right_column, etc.
  impression_device: string        // 展示设备：iPhone, Android, etc.

  // 地理维度
  country: string                   // 国家：CN, US, JP, etc.
  region: string                    // 地区/省份：Guangdong, California, etc.
  city: string                      // 城市：Shenzhen, Los Angeles, etc.
  dma?: string                      // DMA区域（美国市场）

  // 受众维度
  age_range: string                 // 年龄段：18-24, 25-34, 35-44, 45-54, 55-64, 65+
  gender: 'male' | 'female' | 'unknown'  // 性别

  // 技术维度
  operating_system: string          // 操作系统：iOS, Android, Windows, macOS, etc.
  browser?: string                  // 浏览器：Chrome, Safari, Firefox, etc.
  device_model?: string             // 设备型号：iPhone 13, Samsung Galaxy S21, etc.
  carrier?: string                  // 运营商：China Mobile, Verizon, etc.

  // 行为维度
  user_bucket?: string              // 用户分桶
  conversion_device?: string        // 转化设备
  click_device?: string             // 点击设备

  // 时间维度
  day_of_week?: string              // 星期几：Monday, Tuesday, etc.
  hour_of_day?: number              // 一天中的小时：0-23

  // 内容维度
  ad_format?: string                // 广告格式：single_image, single_video, carousel, etc.
  call_to_action?: string           // 行动号召按钮类型
  link_click_destination?: string   // 链接点击目标

  // 核心指标
  impressions: number
  clicks: number
  spend: number
  reach: number
  frequency: number

  // 互动指标
  likes: number
  comments: number
  shares: number
  saves: number
  video_views: number
  video_view_25p: number
  video_view_50p: number
  video_view_75p: number
  video_view_100p: number

  // 额外互动指标
  post_engagements: number          // 帖子互动
  page_likes: number                // 页面赞
  post_shares: number               // 帖子分享
  video_play_actions: number        // 视频播放操作

  // 转化指标
  conversions: number
  conversion_value: number
  cost_per_conversion: number
  conversion_rate: number

  // 不同类型转化
  purchase_conversions?: number     // 购买转化
  add_to_cart_conversions?: number  // 加购转化
  lead_conversions?: number         // 潜客转化
  app_install_conversions?: number  // 应用安装转化

  // 质量分数（原始存储）
  relevance_score?: number          // 相关性分数
  quality_score?: number            // 质量分数

  // 注意：CTR、CPM、CPC、ROAS等计算指标不存储，在聚合时动态计算

  // 时间戳
  created_at: string
  updated_at: string
}

/** 分页响应 */
export interface PaginationInfo {
  current_page: number
  per_page: number
  total_count: number
  total_pages: number
}

/** 广告数据响应 */
export interface AdsDataResponse {
  data: DetailedAdsDataItem[]
  pagination: PaginationInfo
}

/** 统计指标汇总 */
export interface AdsStatsSummary {
  total_stats: {
    impressions: number
    clicks: number
    spend: number
    reach: number
    conversions: number
    conversion_value: number
    video_views: number
    likes: number
    comments: number
    shares: number
    saves: number
  }
  average_stats: {
    avg_ctr: number
    avg_cpm: number
    avg_cpc: number
    avg_conversion_rate: number
    avg_cost_per_conversion: number
    avg_roas: number
    avg_frequency: number
  }
}

/** 时间维度统计（包含计算指标） */
export interface TimeSeriesStats {
  datetime: string
  impressions: number
  clicks: number
  spend: number
  conversions: number
  reach: number
  // 以下为动态计算指标
  ctr: number         // clicks / impressions * 100
  cpm: number         // spend / impressions * 1000
  cpc: number         // spend / clicks
  roas: number        // conversion_value / spend * 100
  cpp?: number        // spend / purchase_conversions
  cpv?: number        // spend / video_views
}

/** 广告系列统计 */
export interface CampaignStats {
  campaign_id: string
  campaign_name: string
  objective: ObjectiveType
  impressions: number
  clicks: number
  spend: number
  conversions: number
  ctr: number
  cpm: number
  cpc: number
  roas: number
}

/** 广告组统计 */
export interface AdSetStats {
  adset_id: string
  adset_name: string
  campaign_id: string
  campaign_name: string
  impressions: number
  clicks: number
  spend: number
  conversions: number
  ctr: number
  cpm: number
  targeting_summary: string
}

/** 素材统计 */
export interface CreativeStats {
  creative_id: string
  creative_type: CreativeType
  ad_id: string
  ad_name: string
  impressions: number
  clicks: number
  spend: number
  engagement_rate: number
  video_view_rate?: number
}

/** 设备平台统计 */
export interface DevicePlatformStats {
  device_platform: DevicePlatform
  publisher_platform: string
  platform_position: string
  impressions: number
  clicks: number
  spend: number
  ctr: number
  cpm: number
}

/** 受众统计 */
export interface AudienceStats {
  age_range: string
  gender: string
  location: string
  impressions: number
  clicks: number
  spend: number
  ctr: number
  conversion_rate: number
}

/** 完整统计响应 */
export interface AdsStatsResponse {
  total_stats: AdsStatsSummary['total_stats']
  average_stats: AdsStatsSummary['average_stats']

  // 时间维度（支持小时级别）
  hourly_stats: TimeSeriesStats[]
  daily_stats: TimeSeriesStats[]
  weekly_stats: TimeSeriesStats[]
  monthly_stats: TimeSeriesStats[]

  // 层级维度
  campaign_stats: CampaignStats[]
  adset_stats: AdSetStats[]
  creative_stats: CreativeStats[]

  // 投放维度
  device_platform_stats: DevicePlatformStats[]
  audience_stats: AudienceStats[]

  // 摘要信息
  summary: {
    total_records: number
    date_range: {
      start_date: string
      end_date: string
    }
    unique_campaigns: number
    unique_adsets: number
    unique_ads: number
    total_accounts: number
    data_granularity: TimeGranularity
  }
}

/** 数据筛选参数 */
export interface AdsDataFilters {
  ads_account_id?: number
  campaign_ids?: string[]
  adset_ids?: string[]
  ad_ids?: string[]
  start_date?: string
  end_date?: string
  start_datetime?: string  // 支持小时级别
  end_datetime?: string    // 支持小时级别
  granularity?: TimeGranularity
  device_platforms?: DevicePlatform[]
  publisher_platforms?: string[]
  objectives?: ObjectiveType[]
  creative_types?: CreativeType[]
  page?: number
  per_page?: number
  order_by?: string
  order_direction?: 'asc' | 'desc'
}

/** 数据导出格式 */
export interface ExportOptions {
  format: 'csv' | 'xlsx' | 'json'
  include_fields: string[]
  group_by?: string[]
  date_range: {
    start_date: string
    end_date: string
  }
  granularity: TimeGranularity
  filters?: AdsDataFilters
}

export interface Metrics {
  id: number;
  name_cn: string;
  name_en: string;
  description?: string | null;
  sql_expression: string;
  unit?: string | null;
  color?: string | null;
  filter_max?: number | null;
  filter_min?: number | null;
  category?: string | null;
  data_source?: 'platform' | 'adjust' | 'calculated' | string | null;
  sort_order?: number;
  is_active?: boolean;
  created_at: string; // or Date if you plan to convert to Date object
  updated_at: string; // or Date if you plan to convert to Date object
}
