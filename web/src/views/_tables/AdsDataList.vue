<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Paginator from 'primevue/paginator'
import Skeleton from 'primevue/skeleton'
import ProgressSpinner from 'primevue/progressspinner'
import type { DetailedAdsDataItem, PaginationInfo, AdsDataFilters } from '@/data/types/ads-types'
import { ADS_DATA_COLUMNS, STATUS_CONFIG } from '@/data/constants/ads-constants'

interface Props {
  data: DetailedAdsDataItem[]
  pagination: PaginationInfo
  loading?: boolean
  filters?: AdsDataFilters
}

interface Emits {
  (e: 'page-change', page: number): void
  (e: 'sort-change', field: string, order: 'asc' | 'desc'): void
  (e: 'row-select', item: DetailedAdsDataItem): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const emit = defineEmits<Emits>()

// 表格选择
const selectedItems = ref<DetailedAdsDataItem[]>([])

// 格式化函数
const formatNumber = (value: number): string => {
  if (!value) return '0'
  return value.toLocaleString()
}

const formatCurrency = (value: number | string): string => {
  if (!value || value === 0) return '¥0.00'
  const numValue = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(numValue)) return '¥0.00'
  return `¥${numValue.toFixed(2)}`
}

const formatPercentage = (value: number | string): string => {
  if (!value || value === 0) return '0.00%'
  const numValue = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(numValue)) return '0.00%'
  return `${numValue.toFixed(2)}%`
}

const formatDateTime = (datetime: string): string => {
  if (!datetime) return '-'
  const date = new Date(datetime)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
}

// 计算指标函数
const calculateCTR = (clicks: number, impressions: number): string => {
  if (!clicks || !impressions || impressions === 0) return '0.00%'
  const ctr = (clicks / impressions) * 100
  return `${ctr.toFixed(2)}%`
}

const calculateCPM = (spend: number, impressions: number): string => {
  if (!spend || !impressions || impressions === 0) return '¥0.00'
  const cpm = (spend / impressions) * 1000
  return `¥${cpm.toFixed(2)}`
}

const calculateCPC = (spend: number, clicks: number): string => {
  if (!spend || !clicks || clicks === 0) return '¥0.00'
  const cpc = spend / clicks
  return `¥${cpc.toFixed(2)}`
}

// 获取状态配置
const getStatusConfig = (status: string) => {
  return STATUS_CONFIG[status as keyof typeof STATUS_CONFIG] || STATUS_CONFIG.active
}

// 排序处理
const handleSort = (event: any) => {
  const field = event.sortField
  const order = event.sortOrder === 1 ? 'asc' : 'desc'
  emit('sort-change', field, order)
}

// 分页处理
const handlePageChange = (event: any) => {
  emit('page-change', event.page + 1)
}

// 行点击处理
const handleRowSelect = (event: any) => {
  emit('row-select', event.data)
}

// 计算总数
const totalRecords = computed(() => props.pagination?.total_count || 0)
const currentPage = computed(() => (props.pagination?.current_page || 1) - 1)
const rowsPerPage = computed(() => props.pagination?.per_page || 25)
</script>

<template>
  <div class="ads-data-table w-full">
    <!-- 加载状态 -->
    <div v-if="loading" class="flex justify-center items-center py-8">
      <ProgressSpinner size="50" strokeWidth="4" animationDuration="1s" />
      <span class="ml-3 text-gray-600">加载中...</span>
    </div>

    <!-- 数据表格 -->
    <DataTable
      v-else
      :value="data"
      v-model:selection="selectedItems"
      dataKey="id"
      :paginator="false"
      :rows="rowsPerPage"
      scrollable
      scrollHeight="600px"
      :loading="loading"
      selectionMode="multiple"
      :metaKeySelection="false"
      @sort="handleSort"
      @rowSelect="handleRowSelect"
      size="small"
      class="w-full"
    >
      <!-- 选择列 -->
      <Column selectionMode="multiple" headerStyle="width: 3rem" />

      <!-- 时间列 -->
      <Column
        field="datetime"
        header="时间"
        :sortable="true"
        style="min-width: 140px"
      >
        <template #body="slotProps">
          <span class="text-sm font-mono">
            {{ formatDateTime(slotProps.data.datetime) }}
          </span>
        </template>
      </Column>

      <!-- 广告系列列 -->
      <Column
        field="campaign_name"
        header="广告系列"
        :sortable="true"
        style="min-width: 200px"
      >
        <template #body="slotProps">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900 truncate" :title="slotProps.data.campaign_name">
              {{ slotProps.data.campaign_name || '-' }}
            </span>
            <Tag
              v-if="slotProps.data.campaign_objective"
              :value="slotProps.data.campaign_objective"
              size="small"
              class="mt-1"
            />
          </div>
        </template>
      </Column>

      <!-- 平台列 -->
      <Column
        field="platform"
        header="平台"
        style="min-width: 100px"
      >
        <template #body="slotProps">
          <div class="flex flex-col items-center">
            <i class="pi pi-facebook text-blue-600 text-lg mb-1" />
            <span class="text-xs text-gray-500">Facebook</span>
          </div>
        </template>
      </Column>

      <!-- 账户列 -->
      <Column
        field="ads_account_name"
        header="广告账户"
        style="min-width: 150px"
      >
        <template #body="slotProps">
          <span class="text-gray-900 truncate" :title="slotProps.data.ads_account_name">
            {{ slotProps.data.ads_account_name || '-' }}
          </span>
        </template>
      </Column>

      <!-- 设备平台列 -->
      <Column
        field="device_platform"
        header="设备"
        style="min-width: 100px"
      >
        <template #body="slotProps">
          <div class="flex flex-col text-center">
            <i
              :class="`pi pi-${slotProps.data.device_platform === 'mobile' ? 'mobile' : slotProps.data.device_platform === 'desktop' ? 'desktop' : 'tablet'}`"
              class="text-lg text-gray-600 mb-1"
            />
            <span class="text-xs text-gray-500">
              {{ slotProps.data.device_platform }}
            </span>
          </div>
        </template>
      </Column>

      <!-- 展示量列 -->
      <Column
        field="impressions"
        header="展示量"
        :sortable="true"
        style="min-width: 100px"
      >
        <template #body="slotProps">
          <span class="font-medium text-blue-600">
            {{ formatNumber(slotProps.data.impressions) }}
          </span>
        </template>
      </Column>

      <!-- 点击量列 -->
      <Column
        field="clicks"
        header="点击量"
        :sortable="true"
        style="min-width: 100px"
      >
        <template #body="slotProps">
          <span class="font-medium text-green-600">
            {{ formatNumber(slotProps.data.clicks) }}
          </span>
        </template>
      </Column>

      <!-- 花费列 -->
      <Column
        field="spend"
        header="花费"
        :sortable="true"
        style="min-width: 100px"
      >
        <template #body="slotProps">
          <span class="font-medium text-orange-600">
            {{ formatCurrency(slotProps.data.spend) }}
          </span>
        </template>
      </Column>

      <!-- CTR列 -->
      <Column
        header="CTR"
        style="min-width: 80px"
      >
        <template #body="slotProps">
          <span class="font-medium text-indigo-600">
            {{ calculateCTR(slotProps.data.clicks, slotProps.data.impressions) }}
          </span>
        </template>
      </Column>

      <!-- CPM列 -->
      <Column
        header="CPM"
        style="min-width: 80px"
      >
        <template #body="slotProps">
          <span class="font-medium text-pink-600">
            {{ calculateCPM(slotProps.data.spend, slotProps.data.impressions) }}
          </span>
        </template>
      </Column>

      <!-- CPC列 -->
      <Column
        header="CPC"
        style="min-width: 80px"
      >
        <template #body="slotProps">
          <span class="font-medium text-purple-600">
            {{ calculateCPC(slotProps.data.spend, slotProps.data.clicks) }}
          </span>
        </template>
      </Column>

      <!-- 转化量列 -->
      <Column
        field="conversions"
        header="转化"
        :sortable="true"
        style="min-width: 80px"
      >
        <template #body="slotProps">
          <span class="font-medium text-teal-600">
            {{ formatNumber(slotProps.data.conversions) }}
          </span>
        </template>
      </Column>

      <!-- ROAS列 -->
      <Column
        field="roas"
        header="ROAS"
        :sortable="true"
        style="min-width: 80px"
      >
        <template #body="slotProps">
          <span class="font-medium text-cyan-600">
            {{ formatPercentage(slotProps.data.roas) }}
          </span>
        </template>
      </Column>

      <!-- 操作列 -->
      <Column header="操作" style="min-width: 100px">
        <template #body="slotProps">
          <div class="flex gap-2">
            <Button
              icon="pi pi-eye"
              size="small"
              severity="info"
              text
              @click="handleRowSelect({ data: slotProps.data })"
              v-tooltip="'查看详情'"
            />
            <Button
              icon="pi pi-chart-line"
              size="small"
              severity="success"
              text
              v-tooltip="'查看趋势'"
            />
          </div>
        </template>
      </Column>

      <!-- 空数据模板 -->
      <template #empty>
        <div class="text-center py-12">
          <i class="pi pi-chart-line text-6xl text-gray-300 mb-4 block" />
          <h3 class="text-lg font-medium text-gray-900 mb-2">暂无数据</h3>
          <p class="text-gray-500">请调整筛选条件或检查数据源</p>
        </div>
      </template>
    </DataTable>

    <!-- 自定义分页器 -->
    <div class="flex justify-between items-center mt-4 px-2">
      <div class="text-sm text-gray-600">
        共 {{ totalRecords }} 条记录，每页显示 {{ rowsPerPage }} 条
      </div>

      <Paginator
        :rows="rowsPerPage"
        :totalRecords="totalRecords"
        :first="currentPage * rowsPerPage"
        @page="handlePageChange"
        template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
        currentPageReportTemplate="第 {currentPage} 页，共 {totalPages} 页"
      />
    </div>
  </div>
</template>