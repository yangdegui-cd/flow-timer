<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import PageHeader from '@/views/layer/PageHeader.vue'
import Panel from 'primevue/panel'
import Select from 'primevue/select'
import Calendar from 'primevue/calendar'
import Button from 'primevue/button'
import FloatLabel from 'primevue/floatlabel'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import ProgressSpinner from 'primevue/progressspinner'
import Tag from 'primevue/tag'
import AdsDataApi from '@/api/ads-data-api'
import { format } from 'date-fns'
import useSyncUrlParams from "@/utils/syncUrlParams";
import MetricsSelector from "@/views/_selector/MetricsSelector.vue";
import DimensionSelector from "@/views/_selector/DimensionSelector.vue";
import { ellipsis, formatValue } from '@/utils/format-helpers'
import { useMetricsStore } from "@/stores/metrics"
import { useCommonDataStore } from "@/stores/common-data"

const toast = useToast()
const metricsStore = useMetricsStore()
const commonDataStore = useCommonDataStore()

// 响应式数据
const loading = ref(false)
const results = ref([])
const totalRows = ref(0)

const tableDimensionColumns = ref<any[]>([])
const tableMetricsColumns = ref<any[]>([])

// 筛选器
const filters = reactive({
  project_id: null as number | null,
  platform: '',
  ads_account_id: null as number | null,
  start_date: '',
  end_date: '',
  dimensions: ["date"] as string[],
  metrics: [] as string[],
  page: 1,
  per_page: 50,
  order_by: null,
  order_direction: -1,
})

useSyncUrlParams(filters, {
  numberFields: ["project_id", "ads_account_id", "order_direction"],
  arrayFields: ["dimensions", "metrics"]
})

const selectedDateDates = ref<Date[]>([])
const filterPanelCollapsed = ref(false)

// 平台选项
const platformOptions = [
  { label: 'Facebook', value: 'facebook' },
  { label: 'Google', value: 'google' },
  { label: 'TikTok', value: 'tiktok' }
]

// 初始化默认日期范围
const initDefaultDateRange = () => {
  const startDate = new Date('2025-09-01')
  const endDate = new Date('2025-09-30')
  selectedDateDates.value = [startDate, endDate]
  filters.start_date = format(startDate, 'yyyy-MM-dd')
  filters.end_date = format(endDate, 'yyyy-MM-dd')
}

// 处理日期范围变化
const handleDateChange = () => {
  if (selectedDateDates.value?.length === 2) {
    filters.start_date = format(selectedDateDates.value[0], 'yyyy-MM-dd')
    filters.end_date = format(selectedDateDates.value[1], 'yyyy-MM-dd')
  }
}

// 当项目或平台变化时重新加载账户
const handleProjectOrPlatformChange = async () => {
  filters.ads_account_id = null
  const params: any = {}
  if (filters.project_id) params.project_id = filters.project_id
  if (filters.platform) params.platform = filters.platform
  await commonDataStore.loadAdsAccounts(params)
}

// 查询数据
const queryData = () => {
  if (filters.metrics.length === 0) {
    return toast.add({ severity: 'error', detail: '请至少选择一个指标进行查询', life: 3000 })
  }
  if (filters.dimensions.length === 0) {
    return toast.add({ severity: 'error', detail: '请至少选择一个维度进行查询', life: 3000 })
  }
  calculateDimensionColumns()
  calculateMetricColumns()

  loading.value = true

  const params = JSON.parse(JSON.stringify(filters))

  if (filters.project_id === null) delete (params, "project_id")
  if (filters.platform === null) delete (params, "platform")
  if (filters.ads_account_id === null) delete (params, "ads_account_id")

  AdsDataApi.getAdsData(params).then(response => {
    results.value = response.data || []
    console.log("查询结果", results.value)
    totalRows.value = response.pagination?.total_count
  }).catch(err => {
    console.error('查询数据失败:', err)
    toast.add({ severity: 'error', detail: err.msg ?? '查询数据失败，请稍后重试', life: 3000 })
  }).finally(() => {
    loading.value = false
  })
}

// 获取表格列配置
const calculateDimensionColumns = () => {
  tableDimensionColumns.value = []
  filters.dimensions.forEach((dimName: string) => {
    const dimension = metricsStore.getDimension(dimName)
    console.log("维度名", dimName)
    console.log("维度信息", dimension)
    if (!dimension) return

    const config = dimension.display_config || {}
    const column: any = {
      field: dimName,
      header: dimension.display_name,
      sortable: config.sortable !== false,
      frozen: config.frozen || false
    }
    // 添加宽度
    if (config.width) {
      column.style = { width: `${config.width}px`, minWidth: `${config.width}px` }
    }
    // 添加对齐方式
    if (config.align) {
      column.bodyClass = `text-${config.align}`
      column.headerClass = `text-${config.align}`
    }

    tableDimensionColumns.value.push(column)
  })
}

const calculateMetricColumns = () => {
  tableMetricsColumns.value = []
  filters.metrics.forEach((metricKey: string) => {
    const metric = metricsStore.getMetric(metricKey)
    if (!metric) return

    const config = metric.display_config || {}
    const column: any = {
      field: metricKey,
      header: metric.display_name,
      unit: metric.unit,
      sortable: config.sortable !== false,
      ...config
    }
    // 添加宽度
    if (config.width) {
      column.style = { width: `${config.width}px`, minWidth: `${config.width}px` }
    }

    console.log(column)
    tableMetricsColumns.value.push(column)
  })
}

// 获取时间维度标签
const getTimeDimensionLabel = (dimension: string) => {
  const option = timeDimensionOptions.find(opt => opt.value === dimension)
  return option?.label || dimension
}

// 格式化指标值
const formatMetricValue = (metricData: any) => {
  if (!metricData) return '-'
  if (metricData.error) return metricData.error

  // 如果后端已经格式化，直接使用
  if (metricData.formatted_value) return metricData.formatted_value

  // 否则使用前端格式化
  const metricInfo = metricsStore.getMetric(metricData.key)
  if (metricInfo) {
    return formatValue(metricData.value, metricInfo.display_config, metricInfo.unit)
  }

  return metricData.value || '-'
}

// 获取维度的显示配置
const getDimensionConfig = (dimensionName: string) => {
  const dimension = metricsStore.getDimension(dimensionName)
  return dimension?.display_config || {}
}

// 获取指标的显示配置
const getMetricConfig = (metricKey: string) => {
  const metric = metricsStore.getMetric(metricKey)
  return metric?.display_config || {}
}

// 格式化维度值（支持省略号和美化）
const formatDimensionValue = (value: any, dimensionName: string) => {
  if (value === null || value === undefined) return '-'

  // 特殊维度的美化处理
  let displayValue: string
  switch (dimensionName) {
    case 'project_id':
      displayValue = commonDataStore.getProjectName(Number(value))
      break
    case 'ads_account_id':
      displayValue = commonDataStore.getAdsAccountName(Number(value))
      break
    case 'platform':
      displayValue = commonDataStore.getPlatformName(String(value))
      break
    default:
      displayValue = String(value)
  }

  // 应用省略号配置
  const config = getDimensionConfig(dimensionName)
  if (config.ellipsis && displayValue.length > 30) {
    return ellipsis(displayValue, 30)
  }

  return displayValue
}

// 获取指标颜色样式
const getMetricColorStyle = (color: string) => {
  return {
    borderLeft: `4px solid ${color}`,
    paddingLeft: '8px'
  }
}

// 获取平台图标和样式
const getPlatformInfo = (platform: string) => {
  const platformInfoMap: Record<string, { icon: string; color: string; severity: string }> = {
    facebook: { icon: 'pi pi-facebook', color: '#1877F2', severity: 'info' },
    google: { icon: 'pi pi-google', color: '#4285F4', severity: 'primary' },
    tiktok: { icon: 'pi pi-play', color: '#000000', severity: 'contrast' },
    twitter: { icon: 'pi pi-twitter', color: '#1DA1F2', severity: 'info' },
    instagram: { icon: 'pi pi-instagram', color: '#E4405F', severity: 'danger' },
    linkedin: { icon: 'pi pi-linkedin', color: '#0A66C2', severity: 'info' }
  }

  return platformInfoMap[platform?.toLowerCase()] || {
    icon: 'pi pi-globe',
    color: '#6B7280',
    severity: 'secondary'
  }
}

watch(() => metricsStore.metrics, () => {
  // 如果当前选择的维度不在可选列表中，清除选择
  if (metricsStore.metrics.length > 0) {
    filters.metrics = metricsStore.metrics.map(v => v.key)
    queryData()
  }
}, { immediate: true })

// 初始化
onMounted(() => {
  initDefaultDateRange()
})
</script>

<template>
  <PageHeader title="广告数据分析" description="基于维度和指标的广告数据分析" icon="pi pi-chart-line"/>

  <!-- 筛选条件面板 -->
  <Panel header="筛选条件" :toggleable="true" v-model:collapsed="filterPanelCollapsed" class="m-4">
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-7 gap-4">
      <!-- 项目筛选 -->
      <FloatLabel variant="on">
        <Select
            id="project_filter"
            v-model="filters.project_id"
            :options="commonDataStore.projects"
            optionLabel="name"
            optionValue="id"
            showClear
            size="small"
            @change="handleProjectOrPlatformChange"
            class="w-full"
        />
        <label for="project_filter">项目</label>
      </FloatLabel>

      <!-- 平台筛选 -->
      <FloatLabel variant="on">
        <Select
            id="platform_filter"
            v-model="filters.platform"
            :options="platformOptions"
            showClear
            size="small"
            @change="handleProjectOrPlatformChange"
            class="w-full"
        />
        <label for="platform_filter">平台</label>
      </FloatLabel>

      <!-- 账号筛选 -->
      <FloatLabel variant="on">
        <Select
            id="account_filter"
            v-model="filters.ads_account_id"
            :options="commonDataStore.adsAccounts"
            optionLabel="name"
            optionValue="id"
            showClear
            size="small"
            class="w-full"
        />
        <label for="account_filter">账号</label>
      </FloatLabel>

      <!-- 日期范围 -->
      <FloatLabel variant="on">
        <DatePicker
            id="date_range"
            v-model="selectedDateDates"
            selectionMode="range"
            dateFormat="yy-mm-dd"
            showIcon
            @date-select="handleDateChange"
            size="small"
            class="w-full"
        />
        <label for="date_range">日期范围</label>
      </FloatLabel>

      <div>
        <FloatLabel variant="on">
          <DimensionSelector v-model="filters.dimensions" multiple class="w-full" size="small"/>
          <label for="dimensions">分组维度（可多选）</label>
        </FloatLabel>
      </div>

      <div>
        <MetricsSelector v-model="filters.metrics" multiple class="w-full" size="small"/>
      </div>

      <div class="flex justify-end items-center gap-2">
        <Button
            label="重置"
            icon="pi pi-refresh"
            severity="secondary"
            size="small"
            @click="() => {
              filters.time_dimension = ''
              filters.dimensions = []
              filters.metric_ids = []
              results = []
            }"
        />
        <Button
            label="查询数据"
            size="small"
            icon="pi pi-search"
            @click="queryData"
            :loading="loading"
            severity="primary"
        />
      </div>
    </div>
  </Panel>
  <!-- 结果展示 -->
  <!--    <Panel-->
  <!--        v-if="results.length > 0"-->
  <!--        :header="`分析结果 (${totalRows} 条记录)`"-->
  <!--        :toggleable="true"-->
  <!--        class="m-4"-->
  <!--    >-->
  <!--       无分组 - 显示汇总卡片 -->
  <!--      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">-->
  <!--        <Card-->
  <!--            v-for="metric in (results as MetricResult[])"-->
  <!--            :key="metric.metric_id"-->
  <!--            class="shadow-sm"-->
  <!--        >-->
  <!--          <template #content>-->
  <!--            <div :style="getMetricColorStyle(metric.color)">-->
  <!--              <div class="text-sm text-gray-600 mb-1">{{ metric.display_name }}</div>-->
  <!--              <div class="text-2xl font-bold">-->
  <!--                {{ formatMetricValue(metric) }}-->
  <!--              </div>-->
  <!--              <div class="text-xs text-gray-500 mt-1">{{ metric.key }}</div>-->
  <!--            </div>-->
  <!--          </template>-->
  <!--        </Card>-->
  <!--      </div>-->
  <!--      &lt;!&ndash; 有分组 - 显示数据表格 &ndash;&gt;-->
  <!--      <div>-->
  <!--      </div>-->
  <!--    </Panel>-->
  <div>
    <DataTable
        :value="results"
        :paginator="true"
        :first="(filters.page - 1) * filters.per_page"
        :rows="filters.per_page"
        :totalRecords="totalRows"
        :lazy="true"
        @page="(e) => {
              filters.page = e.page + 1
              filters.per_page = e.rows
              queryData()
            }"
        paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
        :rowsPerPageOptions="[10, 20, 50]"
        currentPageReportTemplate="显示 {first} 到 {last} 条,共 {totalRecords} 条"
        stripedRows
        :loading="loading"
        scrollable
        :sort-order="filters.order_direction"
        :sort-field="filters.order_by"
        @sort="(e) => {
              filters.order_by = e.sortField
              console.log(e.sortOrder)
              filters.order_direction = e.sortOrder
              queryData()
            }"
        show-gridlines
        size="small"
        scrollHeight="600px"
        class="ads-analytics-table m-4"
    >
      <!-- 维度列 -->
      <Column
          v-for="col in tableDimensionColumns"
          :key="col.field"
          :field="col.field"
          :header="col.header"
          :sortable="col.sortable"
          :frozen="col.frozen"
          :style="col.style"
          :class="col.bodyClass"
          :headerClass="col.headerClass"
      >
        <template #body="{ data }">
          <!-- 平台字段 - 使用图标 + Tag -->
          <div v-if="col.field === 'platform'" class="flex items-center gap-2">
            <i :class="getPlatformInfo(data[col.field]).icon"
               :style="{ color: getPlatformInfo(data[col.field]).color }"></i>
            <Tag :value="commonDataStore.getPlatformName(data[col.field])"
                 :severity="getPlatformInfo(data[col.field]).severity as any"/>
          </div>

          <!-- 项目字段 - 使用 Tag -->
          <Tag v-else-if="col.field === 'project_id'"
               :value="commonDataStore.getProjectName(data[col.field])"
               severity="success"
               icon="pi pi-folder"/>

          <!-- 账号字段 - 使用 Tag -->
          <Tag v-else-if="col.field === 'ads_account_id'"
               :value="commonDataStore.getAdsAccountName(data[col.field])"
               severity="warn"
               icon="pi pi-user"/>
          <div v-else-if="['campaign_name', 'ad_set_name', 'ad_name', 'creative_name'].includes(col.field)"
               v-tooltip.top="data[col.field]">
            {{ formatDimensionValue(data[col.field], col.field) }}
          </div>

          <!-- 其他字段 - 普通显示 -->
          <div v-else :title="data[col.field]">
            {{ formatDimensionValue(data[col.field], col.field) }}
          </div>
        </template>
      </Column>

      <!-- 指标列 -->
      <Column
          v-for="col in tableMetricsColumns"
          :key="col.field"
          :field="col.field"
          :sortable="col.sortable"
          :frozen="col.frozen"
          :style="col.style"
          :class="col.bodyClass"
          :headerClass="col.headerClass"
          :bodyClass="`text-${col.align || 'right'}`"
      >
        <template #header="{ data }">
          <div class="metric-value" v-tooltip.top="col.description">
            {{ col.header }}
          </div>
        </template>
        <template #body="{ data }">
              <span v-if="data[col.field]" :style="{color: col.field.endsWith('p') ? '#000' : 'red'}" style="">
                {{ formatValue(data[col.field], col, col.unit) }}
              </span>
          <span v-else>-</span>
        </template>
      </Column>
    </DataTable>
  </div>

  <!-- 空状态 -->
  <div v-if="!loading && results.length === 0"
       class="text-center py-12 text-gray-500 bg-white m-4 rounded-lg">
    <i class="pi pi-chart-bar text-6xl mb-4 text-gray-300"></i>
    <p class="text-xl mb-2">请选择指标后查询数据</p>
    <p class="text-sm text-gray-400">可选择时间维度和属性维度对数据进行分组分析</p>
  </div>

  <!-- 加载状态 -->
  <div v-if="loading" class="flex justify-center items-center py-12 bg-white m-4 rounded-lg">
    <ProgressSpinner/>
  </div>
</template>

<style scoped>
.ads-analytics {
  min-height: 100vh;
  background-color: #f5f5f5;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  background-color: #f8f9fa;
  font-weight: 600;
  white-space: nowrap;
}

/* 表格单元格样式 */
:deep(.ads-analytics-table .p-datatable-tbody > tr > td) {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  padding: 0.65rem;
  font-size: 13px;
}

/* 悬停显示完整内容 */
:deep(.ads-analytics-table th) {
  text-overflow: ellipsis;
  padding: 1rem;
  font-size: 13px;
  background: #f3f4f6;
}


/* 悬停显示完整内容 */
:deep(.ads-analytics-table .p-datatable-tbody > tr > td:hover) {
  overflow: visible;
  white-space: normal;
}

/* 货币和数字右对齐 */
:deep(.ads-analytics-table .metric-value) {
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  font-variant-numeric: tabular-nums;
}
</style>
