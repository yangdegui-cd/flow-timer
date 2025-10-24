<script setup lang="ts">
import { computed, nextTick, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Chart from 'chart.js/auto'
import PageHeader from '@/views/layer/PageHeader.vue'
import AdsDataList from '@/views/_tables/AdsDataList.vue'
import Card from 'primevue/card'
import Panel from 'primevue/panel'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'
import adsDataApi from '@/api/ads-data-api'
import type { AdsAccount, AdsStatsResponse, DetailedAdsDataItem, PaginationInfo } from '@/data/types/ads-types'
import {
  DATE_RANGE_PRESETS,
  METRIC_CARDS,
  SORT_OPTIONS,
  TIME_GRANULARITY_OPTIONS
} from '@/data/constants/ads-constants'

const router = useRouter()

// 响应式数据
const loading = ref(false)
const accounts = ref<AdsAccount[]>([])
const stats = ref<AdsStatsResponse>({
  total_stats: {
    impressions: 0,
    clicks: 0,
    spend: 0,
    reach: 0,
    conversions: 0,
    conversion_value: 0,
    video_views: 0,
    likes: 0,
    comments: 0,
    shares: 0,
    saves: 0
  },
  average_stats: {
    avg_ctr: 0,
    avg_cpm: 0,
    avg_cpc: 0,
    avg_conversion_rate: 0,
    avg_cost_per_conversion: 0,
    avg_roas: 0,
    avg_frequency: 0
  },
  hourly_stats: [],
  daily_stats: [],
  weekly_stats: [],
  monthly_stats: [],
  campaign_stats: [],
  adset_stats: [],
  creative_stats: [],
  device_platform_stats: [],
  audience_stats: [],
  summary: {
    total_records: 0,
    date_range: { start_date: '', end_date: '' },
    unique_campaigns: 0,
    unique_adsets: 0,
    unique_ads: 0,
    total_accounts: 0,
    data_granularity: 'day' as const
  }
})

const adsData = ref<DetailedAdsDataItem[]>([])
const pagination = ref<PaginationInfo>({
  current_page: 1,
  per_page: 25,
  total_count: 0,
  total_pages: 0
})

// 筛选器
const filters = reactive({
  ads_account_id: null as number | null,
  start_date: '',
  end_date: '',
  granularity: 'day' as const,
  page: 1,
  per_page: 25,
  order_by: 'datetime',
  order_direction: 'desc' as const
})

const selectedDateRange = ref('30')
const selectedDateDates = ref<Date[]>([])
const searchQuery = ref('')
const selectedSort = ref({ label: '时间（最新）', value: 'datetime', direction: 'desc' })

// 图表引用
const trendChart = ref(null)
const deviceChart = ref(null)
const campaignChart = ref(null)
let trendChartInstance: Chart | null = null
let deviceChartInstance: Chart | null = null
let campaignChartInstance: Chart | null = null

// 计算属性
const filteredAdsData = computed(() => {
  if (!searchQuery.value) return adsData.value
  return adsData.value.filter(data =>
      data.campaign_name?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      data.adset_name?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      data.ad_name?.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

// 指标卡片数据
const metricCardsData = computed(() => {
  return METRIC_CARDS.map(card => ({
    ...card,
    value: stats.value.total_stats[card.key as keyof typeof stats.value.total_stats] ||
        stats.value.average_stats[card.key as keyof typeof stats.value.average_stats] || 0
  }))
})

// 工具函数
const formatNumber = (num: number | string): string => {
  if (!num || num === 0) return '0'
  const numValue = typeof num === 'string' ? parseFloat(num) : num
  if (isNaN(numValue)) return '0'
  return numValue.toLocaleString()
}

const formatCurrency = (amount: number | string): string => {
  if (!amount || amount === 0) return '¥0.00'
  const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount
  if (isNaN(numAmount)) return '¥0.00'
  return `¥${numAmount.toFixed(2)}`
}

const formatPercentage = (value: number | string): string => {
  if (!value || value === 0) return '0.00%'
  const numValue = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(numValue)) return '0.00%'
  return `${numValue.toFixed(2)}%`
}

const formatDate = (date: string): string => {
  return new Date(date).toLocaleDateString('zh-CN')
}

// 更新日期范围
const updateDateRange = () => {
  const today = new Date()
  let startDate = new Date()

  if (selectedDateRange.value !== 'custom') {
    const days = parseInt(selectedDateRange.value)
    startDate.setDate(today.getDate() - days)

    filters.start_date = startDate.toISOString().split('T')[0]
    filters.end_date = today.toISOString().split('T')[0]

    // 清除自定义日期选择
    selectedDateDates.value = []

    loadData()
  }
}

// 处理自定义日期范围选择
const handleCustomDateChange = () => {
  if (selectedDateDates.value?.length === 2) {
    filters.start_date = selectedDateDates.value[0].toISOString().split('T')[0]
    filters.end_date = selectedDateDates.value[1].toISOString().split('T')[0]
    loadData()
  }
}

// 加载账户列表
const loadAccounts = async () => {
  try {
    accounts.value = await adsDataApi.getAccounts()
  } catch (error) {
    console.error('加载账户失败:', error)
  }
}

// 加载统计数据
const loadStats = async () => {
  try {
    const params = {} as any
    if (filters.ads_account_id) params.ads_account_id = filters.ads_account_id
    if (filters.start_date) params.start_date = filters.start_date
    if (filters.end_date) params.end_date = filters.end_date
    if (filters.granularity) params.granularity = filters.granularity

    const result = await adsDataApi.getStats(params)

    // 确保数据结构完整
    stats.value = {
      total_stats: result.total_stats || {},
      average_stats: result.average_stats || {},
      hourly_stats: result.hourly_stats || [],
      daily_stats: result.daily_stats || [],
      weekly_stats: result.weekly_stats || [],
      monthly_stats: result.monthly_stats || [],
      campaign_stats: result.campaign_stats || [],
      adset_stats: result.adset_stats || [],
      creative_stats: result.creative_stats || [],
      device_platform_stats: result.device_platform_stats || [],
      audience_stats: result.audience_stats || [],
      summary: result.summary || {
        total_records: 0,
        date_range: { start_date: '', end_date: '' },
        unique_campaigns: 0,
        unique_adsets: 0,
        unique_ads: 0,
        total_accounts: 0,
        data_granularity: 'day'
      }
    }

    // 更新图表
    await nextTick()
    updateCharts()
  } catch (error) {
    console.error('加载统计数据失败:', error)
    // 重置为默认值
    stats.value = {
      total_stats: {
        impressions: 0, clicks: 0, spend: 0, reach: 0, conversions: 0,
        conversion_value: 0, video_views: 0, likes: 0, comments: 0, shares: 0, saves: 0
      },
      average_stats: {
        avg_ctr: 0, avg_cpm: 0, avg_cpc: 0, avg_conversion_rate: 0,
        avg_cost_per_conversion: 0, avg_roas: 0, avg_frequency: 0
      },
      hourly_stats: [], daily_stats: [], weekly_stats: [], monthly_stats: [],
      campaign_stats: [], adset_stats: [], creative_stats: [],
      device_platform_stats: [], audience_stats: [],
      summary: {
        total_records: 0, date_range: { start_date: '', end_date: '' },
        unique_campaigns: 0, unique_adsets: 0, unique_ads: 0,
        total_accounts: 0, data_granularity: 'day'
      }
    }
  }
}

// 加载广告数据
const loadAdsData = async () => {
  try {
    const params = {} as any
    if (filters.ads_account_id) params.ads_account_id = filters.ads_account_id
    if (filters.start_date) params.start_date = filters.start_date
    if (filters.end_date) params.end_date = filters.end_date
    params.page = filters.page
    params.per_page = filters.per_page
    params.order_by = filters.order_by
    params.order_direction = filters.order_direction

    const result = await adsDataApi.getAdsData(params)
    adsData.value = result.data
    pagination.value = result.pagination
  } catch (error) {
    console.error('加载广告数据失败:', error)
  }
}

// 加载所有数据
const loadData = async () => {
  loading.value = true
  try {
    await Promise.all([
      loadStats(),
      loadAdsData()
    ])
  } catch (error) {
    console.error('加载数据失败:', error)
  } finally {
    loading.value = false
  }
}

// 更新图表
const updateCharts = () => {
  updateTrendChart()
  updateDeviceChart()
  updateCampaignChart()
}

// 趋势图表
const updateTrendChart = () => {
  if (!trendChart.value || !stats.value?.daily_stats?.length) return

  // 销毁旧图表
  if (trendChartInstance) {
    try {
      trendChartInstance.destroy()
    } catch (e) {
      console.warn('Chart destroy error:', e)
    }
    trendChartInstance = null
  }

  const ctx = (trendChart.value as HTMLCanvasElement).getContext('2d')
  if (!ctx) return

  trendChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: stats.value.daily_stats.map(item => formatDate(item.datetime)),
      datasets: [
        {
          label: '展示量',
          data: stats.value.daily_stats.map(item => item.impressions),
          borderColor: '#3B82F6',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.4,
          yAxisID: 'y'
        },
        {
          label: '点击量',
          data: stats.value.daily_stats.map(item => item.clicks),
          borderColor: '#10B981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          tension: 0.4,
          yAxisID: 'y'
        },
        {
          label: '花费',
          data: stats.value.daily_stats.map(item => item.spend),
          borderColor: '#F59E0B',
          backgroundColor: 'rgba(245, 158, 11, 0.1)',
          tension: 0.4,
          yAxisID: 'y1'
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          type: 'linear',
          display: true,
          position: 'left',
          title: { display: true, text: '展示量 / 点击量' }
        },
        y1: {
          type: 'linear',
          display: true,
          position: 'right',
          title: { display: true, text: '花费 (¥)' },
          grid: { drawOnChartArea: false }
        }
      },
      plugins: {
        legend: { position: 'top' },
        title: { display: true, text: '数据趋势' }
      }
    }
  })
}

// 设备分布图表
const updateDeviceChart = () => {
  if (!deviceChart.value || !stats.value?.device_platform_stats?.length) return

  if (deviceChartInstance) {
    try {
      deviceChartInstance.destroy()
    } catch (e) {
      console.warn('Device chart destroy error:', e)
    }
    deviceChartInstance = null
  }

  const ctx = (deviceChart.value as HTMLCanvasElement).getContext('2d')
  if (!ctx) return

  deviceChartInstance = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: stats.value.device_platform_stats.map(item => item.device_platform),
      datasets: [{
        data: stats.value.device_platform_stats.map(item => item.impressions),
        backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'],
        borderWidth: 2
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: 'bottom' },
        title: { display: true, text: '设备平台分布' }
      }
    }
  })
}

// 广告系列表现图表
const updateCampaignChart = () => {
  if (!campaignChart.value || !stats.value?.campaign_stats?.length) return

  if (campaignChartInstance) {
    try {
      campaignChartInstance.destroy()
    } catch (e) {
      console.warn('Campaign chart destroy error:', e)
    }
    campaignChartInstance = null
  }

  const ctx = (campaignChart.value as HTMLCanvasElement).getContext('2d')
  if (!ctx) return

  const top10Campaigns = stats.value.campaign_stats.slice(0, 10)

  campaignChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: top10Campaigns.map(item => item.campaign_name.substring(0, 20) + '...'),
      datasets: [{
        label: '花费',
        data: top10Campaigns.map(item => item.spend),
        backgroundColor: '#3B82F6',
        borderColor: '#1D4ED8',
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: 'y',
      plugins: {
        legend: { display: false },
        title: { display: true, text: 'Top 10 广告系列表现' }
      },
      scales: {
        x: { title: { display: true, text: '花费 (¥)' } }
      }
    }
  })
}

// 处理表格事件
const handlePageChange = (page: number) => {
  filters.page = page
  loadAdsData()
}

const handleSortChange = (field: string, order: 'asc' | 'desc') => {
  filters.order_by = field
  filters.order_direction = order
  loadAdsData()
}

const handleRowSelect = (item: DetailedAdsDataItem) => {
  // 处理行选择，可以打开详情对话框
  console.log('Selected item:', item)
}

// 处理排序选择
const handleSortSelection = () => {
  if (selectedSort.value) {
    filters.order_by = selectedSort.value.value
    filters.order_direction = selectedSort.value.direction
    loadAdsData()
  }
}

// 初始化
onMounted(async () => {
  // 设置默认日期范围（最近30天）
  updateDateRange()

  // 加载账户列表
  await loadAccounts()
})
</script>

<template>
  <PageHeader
      title="广告数据分析"
      description="Facebook广告投放效果分析与洞察"
      icon="pi pi-chart-line"
      icon-color="text-blue-600"
  >
    <template #actions>
      <Button
          @click="loadData"
          :loading="loading"
          icon="pi pi-refresh"
          label="刷新数据"
          size="small"
          class="mr-2"
      />
      <Button
          icon="pi pi-download"
          label="导出"
          size="small"
          severity="secondary"
      />
    </template>
  </PageHeader>

  <div class="flex-1 overflow-auto bg-gray-50 h-[calc(100vh-100px)]">
    <!-- 筛选器面板 -->
    <Panel header="数据筛选" class="m-4" :toggleable="true">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- 广告账户筛选 -->
        <div class="flex flex-col">
          <label class="text-sm font-medium text-gray-700 mb-2">广告账户</label>
          <Dropdown
              v-model="filters.ads_account_id"
              :options="accounts"
              optionLabel="name"
              optionValue="id"
              placeholder="选择账户"
              @change="loadData"
              size="small"
              class="w-full"
          >
            <template #option="slotProps">
              <div class="flex items-center">
                <Tag :value="slotProps.option.platform" size="small" class="mr-2"/>
                <span>{{ slotProps.option.name }}</span>
              </div>
            </template>
          </Dropdown>
        </div>

        <!-- 日期范围预设 -->
        <div class="flex flex-col">
          <label class="text-sm font-medium text-gray-700 mb-2">日期范围</label>
          <Dropdown
              v-model="selectedDateRange"
              :options="DATE_RANGE_PRESETS"
              optionLabel="label"
              optionValue="value"
              @change="updateDateRange"
              size="small"
              class="w-full"
          />
        </div>

        <!-- 自定义日期范围 -->
        <div v-if="selectedDateRange === 'custom'" class="flex flex-col">
          <label class="text-sm font-medium text-gray-700 mb-2">自定义日期</label>
          <Calendar
              v-model="selectedDateDates"
              selectionMode="range"
              :manualInput="false"
              @date-select="handleCustomDateChange"
              placeholder="选择日期范围"
              size="small"
              class="w-full"
          />
        </div>

        <!-- 时间粒度 -->
        <div class="flex flex-col">
          <label class="text-sm font-medium text-gray-700 mb-2">时间粒度</label>
          <Dropdown
              v-model="filters.granularity"
              :options="TIME_GRANULARITY_OPTIONS"
              optionLabel="label"
              optionValue="value"
              @change="loadData"
              size="small"
              class="w-full"
          />
        </div>
      </div>
    </Panel>

    <!-- 核心指标卡片 -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mx-4 mb-4">
      <Card v-for="metric in metricCardsData" :key="metric.key" class="shadow-sm">
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-sm text-gray-600">{{ metric.title }}</div>
              <div class="text-2xl font-bold text-gray-900 mt-1">
                <span v-if="metric.format === 'currency'">{{ formatCurrency(metric.value || 0) }}</span>
                <span v-else-if="metric.format === 'percentage'">{{ formatPercentage(metric.value || 0) }}</span>
                <span v-else>{{ formatNumber(metric.value || 0) }}</span>
              </div>
            </div>
            <div :class="[metric.bgColor, 'p-3 rounded-lg']">
              <i :class="[metric.icon, metric.color, 'text-xl']"></i>
            </div>
          </div>
        </template>
      </Card>
    </div>

    <!-- 图表面板 -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mx-4 mb-4">
      <!-- 趋势图表 -->
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-chart-line text-blue-600 mr-2"></i>
            数据趋势
          </div>
        </template>
        <template #content>
          <div v-if="loading" class="h-64 flex items-center justify-center">
            <ProgressSpinner size="50"/>
          </div>
          <div v-else-if="!stats.daily_stats?.length" class="h-64 flex items-center justify-center text-gray-500">
            <div class="text-center">
              <i class="pi pi-chart-line text-4xl mb-2 block"></i>
              <p>暂无趋势数据</p>
            </div>
          </div>
          <canvas v-else ref="trendChart" class="h-64"></canvas>
        </template>
      </Card>

      <!-- 设备分布图表 -->
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-mobile text-green-600 mr-2"></i>
            设备平台分布
          </div>
        </template>
        <template #content>
          <div v-if="loading" class="h-64 flex items-center justify-center">
            <ProgressSpinner size="50"/>
          </div>
          <div v-else-if="!stats.device_platform_stats?.length"
               class="h-64 flex items-center justify-center text-gray-500">
            <div class="text-center">
              <i class="pi pi-mobile text-4xl mb-2 block"></i>
              <p>暂无设备数据</p>
            </div>
          </div>
          <canvas v-else ref="deviceChart" class="h-64"></canvas>
        </template>
      </Card>
    </div>

    <!-- 广告系列表现图表 -->
    <div class="mx-4 mb-4">
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-chart-bar text-purple-600 mr-2"></i>
            广告系列表现
          </div>
        </template>
        <template #content>
          <div v-if="loading" class="h-80 flex items-center justify-center">
            <ProgressSpinner size="50"/>
          </div>
          <div v-else-if="!stats.campaign_stats?.length" class="h-80 flex items-center justify-center text-gray-500">
            <div class="text-center">
              <i class="pi pi-chart-bar text-4xl mb-2 block"></i>
              <p>暂无广告系列数据</p>
            </div>
          </div>
          <canvas v-else ref="campaignChart" class="h-80"></canvas>
        </template>
      </Card>
    </div>

    <!-- 数据表格面板 -->
    <Panel header="详细数据" class="m-4">
      <template #icons>
        <div class="flex items-center gap-2">
          <!-- 搜索 -->
          <InputText
              v-model="searchQuery"
              placeholder="搜索广告系列、广告组、广告..."
              size="small"
              class="w-64"
          >
            <template #prefix>
              <i class="pi pi-search text-gray-400"></i>
            </template>
          </InputText>

          <!-- 排序 -->
          <Dropdown
              v-model="selectedSort"
              :options="SORT_OPTIONS"
              optionLabel="label"
              @change="handleSortSelection"
              placeholder="排序方式"
              size="small"
              class="w-48"
          />
        </div>
      </template>

      <AdsDataList
          :data="filteredAdsData"
          :pagination="pagination"
          :loading="loading"
          :filters="filters"
          @page-change="handlePageChange"
          @sort-change="handleSortChange"
          @row-select="handleRowSelect"
      />
    </Panel>
  </div>

</template>
