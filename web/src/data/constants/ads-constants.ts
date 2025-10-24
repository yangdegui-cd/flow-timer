// 广告数据分析相关常量定义

import type { TimeGranularity, AdsPlatform, ObjectiveType, CreativeType, DevicePlatform } from '@/data/types/ads-types'

/** 时间粒度选项 */
export const TIME_GRANULARITY_OPTIONS = [
  { label: '小时', value: 'hour' as TimeGranularity, icon: 'pi pi-clock' },
  { label: '天', value: 'day' as TimeGranularity, icon: 'pi pi-calendar' },
  { label: '周', value: 'week' as TimeGranularity, icon: 'pi pi-calendar-plus' },
  { label: '月', value: 'month' as TimeGranularity, icon: 'pi pi-calendar-times' }
]

/** 预设日期范围 */
export const DATE_RANGE_PRESETS = [
  { label: '今天', value: 'today', days: 0 },
  { label: '昨天', value: 'yesterday', days: 1 },
  { label: '最近7天', value: '7d', days: 7 },
  { label: '最近14天', value: '14d', days: 14 },
  { label: '最近30天', value: '30d', days: 30 },
  { label: '最近90天', value: '90d', days: 90 },
  { label: '本月', value: 'this_month', days: 'month' },
  { label: '上月', value: 'last_month', days: 'last_month' },
  { label: '自定义', value: 'custom', days: 'custom' }
]

/** 广告平台配置 */
export const PLATFORM_CONFIG = {
  Facebook: {
    color: '#1877F2',
    icon: 'pi pi-facebook',
    publishers: ['Facebook', 'Instagram', 'Messenger', 'Audience_Network']
  },
  Google: {
    color: '#4285F4',
    icon: 'pi pi-google',
    publishers: ['Google', 'YouTube', 'Gmail', 'Discover', 'Maps']
  },
  TikTok: {
    color: '#000000',
    icon: 'pi pi-video',
    publishers: ['TikTok', 'Pangle']
  },
  Twitter: {
    color: '#1DA1F2',
    icon: 'pi pi-twitter',
    publishers: ['Twitter']
  },
  LinkedIn: {
    color: '#0077B5',
    icon: 'pi pi-linkedin',
    publishers: ['LinkedIn']
  }
}

/** 投放目标配置 */
export const OBJECTIVE_CONFIG = {
  AWARENESS: { label: '品牌认知', color: '#E8F4FD', icon: 'pi pi-eye' },
  TRAFFIC: { label: '网站流量', color: '#E1F5FE', icon: 'pi pi-external-link' },
  ENGAGEMENT: { label: '互动', color: '#F3E5F5', icon: 'pi pi-heart' },
  LEADS: { label: '潜在客户', color: '#E8F5E8', icon: 'pi pi-users' },
  APP_PROMOTION: { label: '应用推广', color: '#FFF3E0', icon: 'pi pi-mobile' },
  SALES: { label: '销售转化', color: '#FFEBEE', icon: 'pi pi-shopping-cart' }
}

/** 素材类型配置 */
export const CREATIVE_TYPE_CONFIG = {
  image: { label: '图片', icon: 'pi pi-image', color: '#4CAF50' },
  video: { label: '视频', icon: 'pi pi-video', color: '#FF9800' },
  carousel: { label: '轮播', icon: 'pi pi-images', color: '#2196F3' },
  collection: { label: '精品栏', icon: 'pi pi-th-large', color: '#9C27B0' },
  dynamic: { label: '动态', icon: 'pi pi-refresh', color: '#607D8B' }
}

/** 设备平台配置 */
export const DEVICE_PLATFORM_CONFIG = {
  mobile: { label: '移动端', icon: 'pi pi-mobile', color: '#4CAF50' },
  desktop: { label: '桌面端', icon: 'pi pi-desktop', color: '#2196F3' },
  tablet: { label: '平板', icon: 'pi pi-tablet', color: '#FF9800' }
}

/** 数据表格列配置 */
export const ADS_DATA_COLUMNS = [
  { key: 'datetime', label: '时间', sortable: true, width: '120px' },
  { key: 'campaign_name', label: '广告系列', sortable: true, width: '200px' },
  { key: 'adset_name', label: '广告组', sortable: true, width: '180px' },
  { key: 'ad_name', label: '广告', sortable: true, width: '180px' },
  { key: 'impressions', label: '展示量', sortable: true, width: '100px', type: 'number' },
  { key: 'clicks', label: '点击量', sortable: true, width: '100px', type: 'number' },
  { key: 'spend', label: '花费', sortable: true, width: '100px', type: 'currency' },
  { key: 'ctr', label: 'CTR', sortable: true, width: '80px', type: 'percentage' },
  { key: 'cpm', label: 'CPM', sortable: true, width: '80px', type: 'currency' },
  { key: 'cpc', label: 'CPC', sortable: true, width: '80px', type: 'currency' },
  { key: 'conversions', label: '转化', sortable: true, width: '80px', type: 'number' },
  { key: 'roas', label: 'ROAS', sortable: true, width: '80px', type: 'percentage' }
]

/** 指标卡片配置 */
export const METRIC_CARDS = [
  {
    key: 'impressions',
    title: '总展示量',
    icon: 'pi pi-eye',
    color: 'text-blue-600',
    bgColor: 'bg-blue-50',
    format: 'number'
  },
  {
    key: 'clicks',
    title: '总点击量',
    icon: 'pi pi-cursor',
    color: 'text-green-600',
    bgColor: 'bg-green-50',
    format: 'number'
  },
  {
    key: 'spend',
    title: '总花费',
    icon: 'pi pi-dollar',
    color: 'text-orange-600',
    bgColor: 'bg-orange-50',
    format: 'currency'
  },
  {
    key: 'conversions',
    title: '总转化',
    icon: 'pi pi-check-circle',
    color: 'text-purple-600',
    bgColor: 'bg-purple-50',
    format: 'number'
  },
  {
    key: 'ctr',
    title: '平均CTR',
    icon: 'pi pi-percentage',
    color: 'text-indigo-600',
    bgColor: 'bg-indigo-50',
    format: 'percentage'
  },
  {
    key: 'cpm',
    title: '平均CPM',
    icon: 'pi pi-chart-line',
    color: 'text-pink-600',
    bgColor: 'bg-pink-50',
    format: 'currency'
  },
  {
    key: 'roas',
    title: '平均ROAS',
    icon: 'pi pi-trending-up',
    color: 'text-teal-600',
    bgColor: 'bg-teal-50',
    format: 'percentage'
  },
  {
    key: 'reach',
    title: '总覆盖',
    icon: 'pi pi-users',
    color: 'text-cyan-600',
    bgColor: 'bg-cyan-50',
    format: 'number'
  }
]

/** 图表颜色配置 */
export const CHART_COLORS = [
  '#3B82F6', '#EF4444', '#10B981', '#F59E0B',
  '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16',
  '#F97316', '#6366F1', '#14B8A6', '#F43F5E'
]

/** 排序选项 */
export const SORT_OPTIONS = [
  { label: '时间（最新）', value: 'datetime', direction: 'desc' },
  { label: '时间（最早）', value: 'datetime', direction: 'asc' },
  { label: '展示量（高到低）', value: 'impressions', direction: 'desc' },
  { label: '点击量（高到低）', value: 'clicks', direction: 'desc' },
  { label: '花费（高到低）', value: 'spend', direction: 'desc' },
  { label: 'CTR（高到低）', value: 'ctr', direction: 'desc' },
  { label: '转化量（高到低）', value: 'conversions', direction: 'desc' }
]

/** 导出格式选项 */
export const EXPORT_FORMAT_OPTIONS = [
  { label: 'CSV', value: 'csv', icon: 'pi pi-file' },
  { label: 'Excel', value: 'xlsx', icon: 'pi pi-file-excel' },
  { label: 'JSON', value: 'json', icon: 'pi pi-code' }
]

/** 分组选项 */
export const GROUP_BY_OPTIONS = [
  { label: '广告系列', value: 'campaign' },
  { label: '广告组', value: 'adset' },
  { label: '广告', value: 'ad' },
  { label: '素材类型', value: 'creative_type' },
  { label: '设备平台', value: 'device_platform' },
  { label: '投放位置', value: 'publisher_platform' },
  { label: '年龄', value: 'age_range' },
  { label: '性别', value: 'gender' },
  { label: '地区', value: 'location' }
]

/** 每页显示数量选项 */
export const PER_PAGE_OPTIONS = [
  { label: '10', value: 10 },
  { label: '25', value: 25 },
  { label: '50', value: 50 },
  { label: '100', value: 100 }
]

/** 状态配置 */
export const STATUS_CONFIG = {
  active: { label: '活跃', color: 'success', icon: 'pi pi-check-circle' },
  paused: { label: '暂停', color: 'warning', icon: 'pi pi-pause-circle' },
  disabled: { label: '禁用', color: 'danger', icon: 'pi pi-times-circle' }
}