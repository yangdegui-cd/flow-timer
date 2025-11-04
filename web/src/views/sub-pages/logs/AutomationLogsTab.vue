<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import Panel from 'primevue/panel'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Dialog from 'primevue/dialog'
import Select from 'primevue/select'
import Calendar from 'primevue/calendar'
import InputText from 'primevue/inputtext'
import FloatLabel from 'primevue/floatlabel'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import automationLogApi, { type AutomationLog } from '@/api/automation-log-api'
import projectApi from '@/api/project-api'
import { format } from 'date-fns'
import useSyncUrlParams from "@/utils/syncUrlParams"
import { actionOptions, getActionLabel, getActionSeverity } from '@/data/options/automation-actions'
import AutomationLogDetail from "@/views/_details/AutomationLogDetail.vue";

const props = defineProps<{
  projectId?: number
}>()

const toast = useToast()
const loading = ref(false)
const logs = ref<AutomationLog[]>([])
const projects = ref<any[]>([])
const selectedDateRange = ref<Date[]>([])
const filterPanelCollapsed = ref(false)

const pagination = ref({
  current_page: 1,
  per_page: 20,
  total: 0,
  total_pages: 0
})

// 动态计算表格滚动高度
const tableScrollHeight = computed(() => {
  // 筛选面板折叠时的高度约为60px,展开时约为200px
  const filterPanelHeight = filterPanelCollapsed.value ? 20 : 65
  // 页面头部、边距等固定高度约为250px
  const fixedHeight = 250
  return `calc(100vh - ${fixedHeight + filterPanelHeight}px)`
})

const filters = ref({
  project_id: null as number | null,
  action_type: '',
  status: '',
  start_date: '',
  end_date: '',
  search: ''
})

useSyncUrlParams(filters, {numberFields: ["project_id"]})

const actionTypeOptions = [
  { label: '项目编辑', value: '项目编辑' },
  { label: '规则触发', value: '规则触发' },
  { label: '定时任务', value: '定时任务' },
  { label: '调整广告投放', value: '调整广告投放' }
]

const statusOptions = [
  { label: '成功', value: 'success' },
  { label: '失败', value: 'failed' }
]

const detailDialogVisible = ref(false)
const selectedLog = ref<AutomationLog | null>(null)

// 加载项目列表
const loadProjects = async () => {
  try {
    projects.value = await projectApi.list()
  } catch (error: any) {
    console.error('加载项目列表失败:', error)
  }
}

// 处理日期范围变化
const handleDateChange = () => {
  if (selectedDateRange.value?.length === 2) {
    filters.value.start_date = format(selectedDateRange.value[0], 'yyyy-MM-dd')
    filters.value.end_date = format(selectedDateRange.value[1], 'yyyy-MM-dd')
    loadLogs()
  }
}

// 初始化默认日期范围(最近2天)
const initDefaultDateRange = () => {
  const today = new Date()
  const twoDaysAgo = new Date()
  twoDaysAgo.setDate(today.getDate() - 2)

  selectedDateRange.value = [twoDaysAgo, today]
  filters.value.start_date = format(twoDaysAgo, 'yyyy-MM-dd')
  filters.value.end_date = format(today, 'yyyy-MM-dd')
}

// 加载日志列表
const loadLogs = async () => {
  loading.value = true
  try {
    const params: any = {
      page: pagination.value.current_page,
      per_page: pagination.value.per_page
    }

    // 如果传入了 projectId 属性,使用属性值;否则使用筛选器中的值
    const targetProjectId = props.projectId || filters.value.project_id

    if (filters.value.action_type) params.action_type = filters.value.action_type
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.start_date) params.start_date = filters.value.start_date
    if (filters.value.end_date) params.end_date = filters.value.end_date
    if (filters.value.search) params.search = filters.value.search

    // 如果有项目ID,调用项目日志API;否则调用全局日志API
    let response
    if (props.projectId) {
      // 从项目详情页调用,使用项目级API
      response = await automationLogApi.getProjectLogs(props.projectId, params)
    } else {
      // 从全局日志页调用,使用全局API,并传递项目筛选
      if (filters.value.project_id) {
        params.project_id_filter = filters.value.project_id
      }
      response = await automationLogApi.getAllLogs(params)
    }

    logs.value = response.logs
    pagination.value = response.pagination
  } catch (error: any) {
    console.error('加载日志失败:', error)
    toast.add({
      severity: 'error',
      summary: '错误',
      detail: error?.data?.msg ?? '加载日志失败',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

// 重置筛选条件
const resetFilters = () => {
  filters.value = {
    project_id: null,
    action_type: '',
    status: '',
    start_date: '',
    end_date: '',
    search: ''
  }
  initDefaultDateRange()
  pagination.value.current_page = 1
  loadLogs()
}

// 移除单个筛选条件
const removeFilter = (filterKey: string) => {
  if (filterKey === 'date_range') {
    filters.value.start_date = ''
    filters.value.end_date = ''
    selectedDateRange.value = []
  } else if (filterKey === 'project_id') {
    filters.value.project_id = null
  } else {
    filters.value[filterKey as keyof typeof filters.value] = '' as any
  }
  pagination.value.current_page = 1
  loadLogs()
}

// 获取项目名称
const getProjectName = (projectId: number | null) => {
  if (!projectId) return ''
  const project = projects.value.find(p => p.id === projectId)
  return project?.name || projectId
}

// 获取操作类型名称
const getActionTypeName = (actionType: string) => {
  const option = actionTypeOptions.find(o => o.value === actionType)
  return option?.label || actionType
}

// 获取状态名称
const getStatusName = (status: string) => {
  const option = statusOptions.find(o => o.value === status)
  return option?.label || status
}

// 分页变化
const onPageChange = (event: any) => {
  pagination.value.current_page = event.page + 1
  pagination.value.per_page = event.rows
  loadLogs()
}

// 查看详情
const viewDetail = (log: AutomationLog) => {
  selectedLog.value = log
  detailDialogVisible.value = true
}

// 获取操作类型严重程度
const getActionTypeSeverity = (actionType: string) => {
  const severityMap: Record<string, any> = {
    项目编辑: 'info',
    规则触发: 'success',
    定时任务: 'warning',
    调整广告投放: 'danger'
  }
  return severityMap[actionType] || 'info'
}

// 格式化日期时间
const formatDateTime = (dateStr: string) => {
  return format(new Date(dateStr), 'yyyy-MM-dd HH:mm:ss')
}

// 处理筛选面板折叠/展开
const onFilterPanelToggle = () => {
  // 面板状态变化会自动触发 tableScrollHeight 的重新计算
}

onMounted(async () => {
  // 如果没有传入projectId,加载项目列表
  if (!props.projectId) {
    await loadProjects()
  }

  // 初始化默认日期范围
  initDefaultDateRange()

  // 加载日志
  loadLogs()
})
</script>
<template>
  <div class="automation-logs-tab">
    <!-- 筛选区域 -->
    <Panel
        class="mb-2"
        :toggleable="true"
        v-model:collapsed="filterPanelCollapsed"
        @toggle="onFilterPanelToggle"
    >
      <template #header>
        <div class="flex items-center gap-2 flex-wrap">
          <span class="font-semibold">数据筛选</span>
          <!-- 筛选条件 Tags -->
          <template v-if="filterPanelCollapsed">
            <Tag
                v-if="filters.project_id"
                :value="`项目: ${getProjectName(filters.project_id)}`"
                severity="info"
                @click.stop="removeFilter('project_id')"
                class="cursor-pointer hover:bg-blue-200"
            >
              <template #default>
                <span>项目: {{ getProjectName(filters.project_id) }}</span>
                <i class="pi pi-times ml-1"></i>
              </template>
            </Tag>
            <Tag
                v-if="filters.action_type"
                :value="`操作类型: ${getActionTypeName(filters.action_type)}`"
                severity="info"
                @click.stop="removeFilter('action_type')"
                class="cursor-pointer hover:bg-blue-200"
            >
              <template #default>
                <span>操作类型: {{ getActionTypeName(filters.action_type) }}</span>
                <i class="pi pi-times ml-1"></i>
              </template>
            </Tag>
            <Tag
                v-if="filters.status"
                :value="`状态: ${getStatusName(filters.status)}`"
                severity="info"
                @click.stop="removeFilter('status')"
                class="cursor-pointer hover:bg-blue-200"
            >
              <template #default>
                <span>状态: {{ getStatusName(filters.status) }}</span>
                <i class="pi pi-times ml-1"></i>
              </template>
            </Tag>
            <Tag
                v-if="filters.start_date && filters.end_date"
                :value="`日期: ${filters.start_date} ~ ${filters.end_date}`"
                severity="info"
                @click.stop="removeFilter('date_range')"
                class="cursor-pointer hover:bg-blue-200"
            >
              <template #default>
                <span>日期: {{ filters.start_date }} ~ {{ filters.end_date }}</span>
                <i class="pi pi-times ml-1"></i>
              </template>
            </Tag>
            <Tag
                v-if="filters.search"
                :value="`搜索: ${filters.search}`"
                severity="info"
                @click.stop="removeFilter('search')"
                class="cursor-pointer hover:bg-blue-200"
            >
              <template #default>
                <span>搜索: {{ filters.search }}</span>
                <i class="pi pi-times ml-1"></i>
              </template>
            </Tag>
          </template>

        </div>
      </template>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4">
        <!-- 项目筛选 -->
        <FloatLabel v-if="!projectId" variant="on">
          <Select
              id="project_filter"
              v-model="filters.project_id"
              :options="projects"
              optionLabel="name"
              optionValue="id"
              showClear
              @change="loadLogs"
              size="small"
              class="w-full"
          >
            <template #option="slotProps">
              <div class="flex items-center">
                <i class="pi pi-folder text-blue-600 mr-2"></i>
                <span>{{ slotProps.option.name }}</span>
              </div>
            </template>
          </Select>
          <label for="project_filter">项目</label>
        </FloatLabel>

        <!-- 操作类型筛选 -->
        <FloatLabel variant="on">
          <Select
              id="action_type_filter"
              v-model="filters.action_type"
              :options="actionTypeOptions"
              optionLabel="label"
              optionValue="value"
              showClear
              @change="loadLogs"
              size="small"
              class="w-full"
          />
          <label for="action_type_filter">操作类型</label>
        </FloatLabel>

        <!-- 状态筛选 -->
        <FloatLabel variant="on">
          <Select
              id="status_filter"
              v-model="filters.status"
              :options="statusOptions"
              optionLabel="label"
              optionValue="value"
              showClear
              @change="loadLogs"
              size="small"
              class="w-full"
          />
          <label for="status_filter">状态</label>
        </FloatLabel>

        <!-- 日期范围 -->
        <FloatLabel variant="on">
          <Calendar
              id="date_range_filter"
              v-model="selectedDateRange"
              selectionMode="range"
              :manualInput="false"
              @date-select="handleDateChange"
              dateFormat="yy-mm-dd"
              showIcon
              size="small"
              class="w-full"
          />
          <label for="date_range_filter">日期范围</label>
        </FloatLabel>

        <!-- 搜索 -->
        <FloatLabel variant="on">
          <IconField>
            <InputIcon class="pi pi-search" />
            <InputText
                id="search_filter"
                v-model="filters.search"
                @keyup.enter="loadLogs"
                size="small"
                class="w-full"
            />
          </IconField>
          <label for="search_filter">搜索</label>
        </FloatLabel>

        <div class="flex justify-end items-end gap-4">
          <Button label="查询" icon="pi pi-search" @click="loadLogs" size="small"/>
          <Button
              label="重置"
              icon="pi pi-refresh"
              severity="secondary"
              outlined
              @click="resetFilters"
              size="small"
          />
        </div>
      </div>

    </Panel>

    <div class="logs-card border-surface-200 border rounded h-full">
      <DataTable
          :value="logs"
          :loading="loading"
          stripedRows
          :paginator="true"
          :rows="pagination.per_page"
          :totalRecords="pagination.total"
          :lazy="true"
          @page="onPageChange"
          paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
          :rowsPerPageOptions="[10, 20, 50]"
          currentPageReportTemplate="显示 {first} 到 {last} 条,共 {totalRecords} 条"
          :scrollable="true"
          :scrollHeight="tableScrollHeight"
          size="small"
          class="compact-table"
      >
        <!-- 项目列(仅全局查询时显示) -->
        <Column v-if="!projectId" field="project" header="项目" :sortable="false" style="width: 120px">
          <template #body="{ data }">
            <div v-if="data.project" class="flex items-center gap-1">
              <i class="pi pi-folder text-blue-600 text-xs"></i>
              <span class="text-sm">{{ data.project.name }}</span>
            </div>
            <span v-else class="text-muted text-sm">-</span>
          </template>
        </Column>

        <Column field="action_type" header="操作类型" :sortable="false" style="width: 100px">
          <template #body="{ data }">
            <Tag :value="data.action_type" :severity="getActionTypeSeverity(data.action_type)" size="small"/>
          </template>
        </Column>

        <Column field="display_name" header="操作描述" :sortable="false" style="min-width: 150px; max-width: 300px">
          <template #body="{ data }">
            <div class="action-desc text-sm" v-tooltip.top="data.display_name">
              {{ data.display_name }}
            </div>
          </template>
        </Column>

        <Column field="rule_name" header="触发规则" :sortable="false" style="width: 100px">
          <template #body="{ data }">
            <Tag
                v-if="data.remark?.action"
                :value="getActionLabel(data.remark.action)"
                :severity="getActionSeverity(data.remark.action)"
                size="small"
            />
            <span v-else class="text-sm text-muted">-</span>
          </template>
        </Column>

        <Column field="status" header="状态" :sortable="false" style="width: 80px">
          <template #body="{ data }">
            <Tag
                :value="data.display_status"
                :severity="data.status === 'success' ? 'success' : 'danger'"
                :icon="data.status === 'success' ? 'pi pi-check' : 'pi pi-times'"
                size="small"
            />
          </template>
        </Column>

        <Column field="duration" header="耗时" :sortable="false" style="width: 70px">
          <template #body="{ data }">
            <span v-if="data.duration_in_seconds" class="text-sm">{{ data.duration_in_seconds }}s</span>
            <span v-else class="text-sm text-muted">-</span>
          </template>
        </Column>

        <Column field="sys_user" header="操作人" :sortable="false" style="width: 100px">
          <template #body="{ data }">
            <div v-if="data.sys_user" class="user-info-compact">
              <span class="text-sm">{{ data.sys_user.name }}</span>
            </div>
            <span v-else class="text-muted text-sm">系统</span>
          </template>
        </Column>

        <Column field="created_at" header="创建时间" :sortable="false" style="width: 150px">
          <template #body="{ data }">
            <span class="text-sm whitespace-nowrap">{{ formatDateTime(data.created_at) }}</span>
          </template>
        </Column>

        <Column header="操作" :sortable="false" style="width: 60px">
          <template #body="{ data }">
            <Button
                icon="pi pi-eye"
                text
                rounded
                severity="info"
                size="small"
                @click="viewDetail(data)"
                v-tooltip.top="'查看详情'"
            />
          </template>
        </Column>

        <template #empty>
          <div class="empty-state">
            <i class="pi pi-inbox text-5xl text-cyan-100"></i>
            <p>暂无日志数据</p>
          </div>
        </template>
      </DataTable>
    </div>
    <!-- 日志列表 -->


    <!-- 详情对话框 -->
    <Dialog
        v-model:visible="detailDialogVisible"
        modal
        :header="selectedLog?.display_name"
        :style="{ width: '800px' }"
        class="compact-dialog"
    >
      <AutomationLogDetail v-if="selectedLog" :log="selectedLog" />
    </Dialog>
  </div>
</template>

<style scoped lang="scss">
.automation-logs-tab {
  padding: 0;
}

// 紧凑表格样式
:deep(.compact-table) {
  // 减少表格单元格padding
  .p-datatable-tbody > tr > td {
    padding: 0.5rem 0.75rem;
  }

  .p-datatable-thead > tr > th {
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
  }

  // 减少分页器padding
  .p-paginator {
    padding: 0.5rem;
  }

  // 优化Tag组件间距
  .p-tag {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
  }

  // 优化按钮大小
  .p-button {
    width: 2rem;
    height: 2rem;
  }
}

.logs-card {
  .user-info-compact {
    display: flex;
    align-items: center;
    white-space: nowrap;
  }

  .text-muted {
    color: var(--text-color-secondary);
    font-style: italic;
  }

  .action-desc {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    line-height: 1.5;
    cursor: help;
  }

  .rule-name {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    cursor: help;
  }

  .empty-state {
    text-align: center;
    padding: 2rem;

    p {
      margin-top: 0.5rem;
      color: var(--text-color-secondary);
      font-size: 0.875rem;
    }
  }
}

// 文本尺寸工具类
.text-xs {
  font-size: 0.75rem;
}

.text-sm {
  font-size: 0.875rem;
}

// 文本换行控制
.whitespace-nowrap {
  white-space: nowrap;
}

.log-detail {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;

  // 行容器
  .detail-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;

    // 如果只有2个项目，使用2列
    &:has(.detail-card:nth-child(2):last-child) {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  // 统一的详情卡片样式
  .detail-card {
    background: var(--surface-0);
    border: 1px solid var(--surface-200);
    border-radius: 6px;
    overflow: hidden;

    .card-header {
      display: flex;
      align-items: center;
      padding: 0.5rem 0.75rem;
      background: var(--surface-100);
      font-size: 0.8rem;
      font-weight: 600;
      color: var(--text-color-secondary);
      border-bottom: 1px solid var(--surface-200);
    }

    .card-content {
      padding: 0.75rem;
      font-size: 0.875rem;
      color: var(--text-color);
      line-height: 1.5;
    }

    // JSON内容区域
    .json-content {
      background: #282c34;
      padding: 0;

      .json-code {
        padding: 1rem;
        margin: 0;
        font-size: 0.75rem;
        line-height: 1.5;
        overflow-x: auto;
        max-height: 400px;
        font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', 'source-code-pro', monospace;

        // JSON语法高亮颜色
        color: #ffffff;

        // 关键字颜色
        ::selection {
          background: rgba(255, 255, 255, 0.1);
        }
      }
    }
  }
}

// 紧凑对话框样式
:deep(.compact-dialog) {
  .p-dialog-content {
    padding: 1rem;
  }

  .p-dialog-header {
    padding: 1rem;
  }
}

// Tailwind工具类
.font-semibold {
  font-weight: 600;
}

.mb-2 {
  margin-bottom: 0.5rem;
}

.mb-3 {
  margin-bottom: 0.75rem;
}

.mr-1 {
  margin-right: 0.25rem;
}

.mr-2 {
  margin-right: 0.5rem;
}
</style>
