<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import PageHeader from '@/views/layer/PageHeader.vue'
import Panel from 'primevue/panel'
import Select from 'primevue/select'
import MultiSelect from 'primevue/multiselect'
import Calendar from 'primevue/calendar'
import Button from 'primevue/button'
import FloatLabel from 'primevue/floatlabel'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'
import Card from 'primevue/card'
import projectApi from '@/api/project-api'
import adsDataApi from '@/api/ads-data-api'
import { useMetricsStore } from '@/stores/metrics'
import type { Metric, GroupedResult, MetricResult } from '@/stores/metrics'
import { format } from 'date-fns'

// Stores
const metricsStore = useMetricsStore()

// 响应式数据
const loading = ref(false)
const projects = ref<any[]>([])
const accounts = ref<any[]>([])
const results = ref<GroupedResult[] | MetricResult[]>([])
const totalRows = ref(0)

// 筛选器
const filters = reactive({
  project_id: null as number | null,
  platform: '',
  ads_account_id: null as number | null,
  start_date: '',
  end_date: '',
  time_dimension: '' as string,
  dimensions: [] as string[],
  metric_ids: [] as number[]
})

const selectedDateDates = ref<Date[]>([])
const filterPanelCollapsed = ref(false)
const dimensionPanelCollapsed = ref(false)

// 时间维度选项（互斥，单选）
const timeDimensionOptions = [
  { label: '季度', value: 'quarter' },
  { label: '月', value: 'month' },
  { label: '周', value: 'week' },
  { label: '日期', value: 'date' },
  { label: '小时', value: 'hour' }
]

// 可多选维度
const dimensionOptions = [
  { label: '项目', value: 'project_id' },
  { label: '平台', value: 'platform' },
  { label: '账号', value: 'ads_account_id' },
  { label: '广告系列', value: 'campaign_name' },
  { label: '广告组', value: 'adset_name' },
  { label: '广告', value: 'ad_name' }
]

// 平台选项
const platformOptions = [
  { label: 'Facebook', value: 'facebook' },
  { label: 'Google', value: 'google' },
  { label: 'TikTok', value: 'tiktok' }
]

// 计算属性：是否有分组
const hasGrouping = computed(() => {
  return filters.time_dimension || filters.dimensions.length > 0
})

// 计算属性：选中的指标
const selectedMetrics = computed(() => {
  return metricsStore.getMetricsByIds(filters.metric_ids)
})

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

// 加载项目列表
const loadProjects = async () => {
  try {
    projects.value = await projectApi.list()
  } catch (error) {
    console.error('加载项目列表失败:', error)
  }
}

// 加载账户列表
const loadAccounts = async () => {
  try {
    const params: any = {}
    if (filters.project_id) params.project_id = filters.project_id
    if (filters.platform) params.platform = filters.platform
    accounts.value = await adsDataApi.getAccounts(params)
  } catch (error) {
    console.error('加载账户失败:', error)
  }
}

// 当项目或平台变化时重新加载账户
const handleProjectOrPlatformChange = async () => {
  filters.ads_account_id = null
  await loadAccounts()
}

// 查询数据
const queryData = async () => {
  if (filters.metric_ids.length === 0) {
    alert('请至少选择一个指标')
    return
  }

  loading.value = true
  try {
    const params: any = {
      metric_ids: filters.metric_ids,
      start_date: filters.start_date,
      end_date: filters.end_date
    }

    if (filters.project_id) params.project_id = filters.project_id
    if (filters.platform) params.platform = filters.platform
    if (filters.ads_account_id) params.ads_account_id = filters.ads_account_id
    if (filters.time_dimension) params.time_dimension = filters.time_dimension
    if (filters.dimensions.length > 0) params.dimensions = filters.dimensions

    const response = await metricsStore.calculateMetrics(params)
    results.value = response.results || []
    totalRows.value = response.total_rows || results.value.length
  } catch (error: any) {
    console.error('查询数据失败:', error)
    alert(error.response?.data?.error || metricsStore.error || '查询失败')
  } finally {
    loading.value = false
  }
}

// 获取表格列配置
const getTableColumns = () => {
  const columns: any[] = []

  // 添加时间维度列
  if (filters.time_dimension) {
    columns.push({
      field: 'time_value',
      header: getTimeDimensionLabel(filters.time_dimension),
      sortable: true
    })
  }

  // 添加其他维度列
  filters.dimensions.forEach(dim => {
    switch (dim) {
      case 'project_id':
        columns.push({ field: 'project_name', header: '项目', sortable: true })
        break
      case 'platform':
        columns.push({ field: 'platform', header: '平台', sortable: true })
        break
      case 'ads_account_id':
        columns.push({ field: 'ads_account_name', header: '账号', sortable: true })
        break
      case 'campaign_name':
        columns.push({ field: 'campaign_name', header: '广告系列', sortable: true })
        break
      case 'adset_name':
        columns.push({ field: 'adset_name', header: '广告组', sortable: true })
        break
      case 'ad_name':
        columns.push({ field: 'ad_name', header: '广告', sortable: true })
        break
    }
  })

  return columns
}

// 获取时间维度标签
const getTimeDimensionLabel = (dimension: string) => {
  const option = timeDimensionOptions.find(opt => opt.value === dimension)
  return option?.label || dimension
}

// 格式化指标值
const formatMetricValue = (metric: any) => {
  if (metric?.error) return metric.error
  return metric?.formatted_value || metric?.value || '-'
}

// 获取指标颜色样式
const getMetricColorStyle = (color: string) => {
  return {
    borderLeft: `4px solid ${color}`,
    paddingLeft: '8px'
  }
}

// 初始化
onMounted(async () => {
  initDefaultDateRange()
  await Promise.all([
    loadProjects(),
    metricsStore.fetchMetrics()
  ])
})
</script>

<template>
  <div class="ads-analytics">
    <PageHeader title="广告数据分析" subtitle="基于维度和指标的广告数据分析" />

    <!-- 筛选条件面板 -->
    <Panel header="筛选条件" :toggleable="true" v-model:collapsed="filterPanelCollapsed" class="m-4">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- 项目筛选 -->
        <FloatLabel variant="on">
          <Select
            id="project_filter"
            v-model="filters.project_id"
            :options="projects"
            optionLabel="name"
            optionValue="id"
            showClear
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
            :options="accounts"
            optionLabel="name"
            optionValue="id"
            showClear
            class="w-full"
          />
          <label for="account_filter">账号</label>
        </FloatLabel>

        <!-- 日期范围 -->
        <FloatLabel variant="on">
          <Calendar
            id="date_range"
            v-model="selectedDateDates"
            selectionMode="range"
            dateFormat="yy-mm-dd"
            showIcon
            @date-select="handleDateChange"
            class="w-full"
          />
          <label for="date_range">日期范围</label>
        </FloatLabel>
      </div>
    </Panel>

    <!-- 维度和指标配置 -->
    <Panel header="维度和指标配置" :toggleable="true" v-model:collapsed="dimensionPanelCollapsed" class="m-4">
      <div class="space-y-4">
        <!-- 时间维度 -->
        <div>
          <FloatLabel variant="on">
            <Select
              id="time_dimension"
              v-model="filters.time_dimension"
              :options="timeDimensionOptions"
              showClear
              placeholder="选择时间维度（可选）"
              class="w-full"
            />
            <label for="time_dimension">时间维度（互斥，单选）</label>
          </FloatLabel>
          <small class="text-gray-500 ml-2">按季度、月、周、日期或小时分组数据</small>
        </div>

        <!-- 属性维度 -->
        <div>
          <FloatLabel variant="on">
            <MultiSelect
              id="dimensions"
              v-model="filters.dimensions"
              :options="dimensionOptions"
              placeholder="选择分组维度（可选）"
              display="chip"
              class="w-full"
            />
            <label for="dimensions">分组维度（可多选）</label>
          </FloatLabel>
          <small class="text-gray-500 ml-2">可按项目、平台、账号、广告系列、广告组、广告等维度分组</small>
        </div>

        <!-- 指标选择 -->
        <div>
          <FloatLabel variant="on">
            <MultiSelect
              id="metrics"
              v-model="filters.metric_ids"
              :options="metricsStore.metrics"
              optionLabel="name_cn"
              optionValue="id"
              placeholder="选择要计算的指标"
              display="chip"
              :filter="true"
              :filterFields="['name_cn', 'name_en', 'description']"
              class="w-full"
              :maxSelectedLabels="5"
            >
              <template #option="{ option }">
                <div class="flex items-center gap-2">
                  <div
                    class="w-3 h-3 rounded-full"
                    :style="{ backgroundColor: option.color }"
                  ></div>
                  <span>{{ option.name_cn }}</span>
                  <span class="text-xs text-gray-500">({{ option.name_en }})</span>
                  <Tag :value="option.category" size="small" severity="secondary" />
                </div>
              </template>
              <template #optiongroup="{ option }">
                <div class="flex items-center gap-2 font-bold">
                  <i class="pi pi-chart-bar"></i>
                  <span>{{ option }}</span>
                </div>
              </template>
            </MultiSelect>
            <label for="metrics">选择指标（必选，可多选）</label>
          </FloatLabel>
          <small class="text-gray-500 ml-2">支持搜索指标名称、英文名或描述</small>
        </div>

        <!-- 查询按钮 -->
        <div class="flex justify-end gap-2">
          <Button
            label="重置"
            icon="pi pi-refresh"
            severity="secondary"
            @click="() => {
              filters.time_dimension = ''
              filters.dimensions = []
              filters.metric_ids = []
              results = []
            }"
          />
          <Button
            label="查询数据"
            icon="pi pi-search"
            @click="queryData"
            :loading="loading"
            severity="primary"
          />
        </div>
      </div>
    </Panel>

    <!-- 结果展示 -->
    <Panel
      v-if="results.length > 0"
      :header="`分析结果 (${totalRows} 条记录)`"
      :toggleable="true"
      class="m-4"
    >
      <!-- 无分组 - 显示汇总卡片 -->
      <div v-if="!hasGrouping" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card
          v-for="metric in (results as MetricResult[])"
          :key="metric.metric_id"
          class="shadow-sm"
        >
          <template #content>
            <div :style="getMetricColorStyle(metric.color)">
              <div class="text-sm text-gray-600 mb-1">{{ metric.name_cn }}</div>
              <div class="text-2xl font-bold">
                {{ formatMetricValue(metric) }}
              </div>
              <div class="text-xs text-gray-500 mt-1">{{ metric.name_en }}</div>
            </div>
          </template>
        </Card>
      </div>

      <!-- 有分组 - 显示数据表格 -->
      <div v-else>
        <DataTable
          :value="results"
          :paginator="true"
          :rows="25"
          :rowsPerPageOptions="[10, 25, 50, 100]"
          stripedRows
          showGridlines
          :loading="loading"
          scrollable
          scrollHeight="600px"
        >
          <!-- 维度列 -->
          <Column
            v-for="col in getTableColumns()"
            :key="col.field"
            :field="col.field"
            :header="col.header"
            :sortable="col.sortable"
            frozen
          />

          <!-- 指标列 -->
          <Column
            v-for="metric in selectedMetrics"
            :key="metric.id"
            :header="metric.name_cn"
            :sortable="true"
          >
            <template #header>
              <div class="flex items-center gap-2">
                <div
                  class="w-3 h-3 rounded-full"
                  :style="{ backgroundColor: metric.color }"
                ></div>
                <span>{{ metric.name_cn }}</span>
              </div>
            </template>
            <template #body="{ data }">
              <span v-if="data.metrics">
                {{
                  formatMetricValue(
                    data.metrics.find((m: any) => m.metric_id === metric.id)
                  )
                }}
              </span>
            </template>
          </Column>
        </DataTable>
      </div>
    </Panel>

    <!-- 空状态 -->
    <div
      v-if="!loading && results.length === 0"
      class="text-center py-12 text-gray-500 bg-white m-4 rounded-lg"
    >
      <i class="pi pi-chart-bar text-6xl mb-4 text-gray-300"></i>
      <p class="text-xl mb-2">请选择指标后查询数据</p>
      <p class="text-sm text-gray-400">可选择时间维度和属性维度对数据进行分组分析</p>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="flex justify-center items-center py-12 bg-white m-4 rounded-lg">
      <ProgressSpinner />
    </div>
  </div>
</template>

<style scoped>
.ads-analytics {
  min-height: 100vh;
  background-color: #f5f5f5;
}

:deep(.p-card-content) {
  padding: 1rem;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  background-color: #f8f9fa;
  font-weight: 600;
}

:deep(.p-datatable .p-datatable-frozen-column) {
  background-color: #ffffff;
}
</style>
