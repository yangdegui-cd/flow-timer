<template>
  <div class="automation-logs-tab">
    <!-- 筛选区域 -->
    <Card class="filter-card">
      <template #content>
        <div class="filter-container">
          <div class="filter-row">
            <div class="filter-item">
              <label>操作类型</label>
              <Dropdown
                v-model="filters.action_type"
                :options="actionTypeOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="全部类型"
                showClear
                @change="loadLogs"
              />
            </div>

            <div class="filter-item">
              <label>状态</label>
              <Dropdown
                v-model="filters.status"
                :options="statusOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="全部状态"
                showClear
                @change="loadLogs"
              />
            </div>

            <div class="filter-item">
              <label>开始日期</label>
              <Calendar
                v-model="filters.start_date"
                dateFormat="yy-mm-dd"
                placeholder="选择开始日期"
                showIcon
                @date-select="loadLogs"
              />
            </div>

            <div class="filter-item">
              <label>结束日期</label>
              <Calendar
                v-model="filters.end_date"
                dateFormat="yy-mm-dd"
                placeholder="选择结束日期"
                showIcon
                @date-select="loadLogs"
              />
            </div>
          </div>

          <div class="filter-row">
            <div class="filter-item search-item">
              <label>搜索</label>
              <InputText
                v-model="filters.search"
                placeholder="搜索操作内容..."
                @keyup.enter="loadLogs"
              />
            </div>

            <div class="filter-actions">
              <Button label="查询" icon="pi pi-search" @click="loadLogs" />
              <Button
                label="重置"
                icon="pi pi-refresh"
                severity="secondary"
                outlined
                @click="resetFilters"
              />
            </div>
          </div>
        </div>
      </template>
    </Card>

    <!-- 日志列表 -->
    <Card class="logs-card">
      <template #content>
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
        >
          <Column field="id" header="ID" :sortable="false" style="width: 80px" />

          <Column field="action_type" header="操作类型" :sortable="false" style="width: 120px">
            <template #body="{ data }">
              <Tag :value="data.action_type" :severity="getActionTypeSeverity(data.action_type)" />
            </template>
          </Column>

          <Column field="display_name" header="操作描述" :sortable="false">
            <template #body="{ data }">
              <div class="action-desc">
                {{ data.display_name }}
              </div>
            </template>
          </Column>

          <Column field="status" header="状态" :sortable="false" style="width: 100px">
            <template #body="{ data }">
              <Tag
                :value="data.display_status"
                :severity="data.status === 'success' ? 'success' : 'danger'"
                :icon="data.status === 'success' ? 'pi pi-check' : 'pi pi-times'"
              />
            </template>
          </Column>

          <Column field="duration" header="耗时" :sortable="false" style="width: 100px">
            <template #body="{ data }">
              <span v-if="data.duration_in_seconds">{{ data.duration_in_seconds }}s</span>
              <span v-else>-</span>
            </template>
          </Column>

          <Column field="sys_user" header="操作人" :sortable="false" style="width: 150px">
            <template #body="{ data }">
              <div v-if="data.sys_user" class="user-info">
                <Avatar :label="data.sys_user.initials" size="small" shape="circle" />
                <span class="user-name">{{ data.sys_user.name }}</span>
              </div>
              <span v-else class="text-muted">系统</span>
            </template>
          </Column>

          <Column field="created_at" header="创建时间" :sortable="false" style="width: 180px">
            <template #body="{ data }">
              {{ formatDateTime(data.created_at) }}
            </template>
          </Column>

          <Column header="操作" :sortable="false" style="width: 100px">
            <template #body="{ data }">
              <Button
                icon="pi pi-eye"
                text
                rounded
                severity="info"
                @click="viewDetail(data)"
                v-tooltip.top="'查看详情'"
              />
            </template>
          </Column>

          <template #empty>
            <div class="empty-state">
              <i class="pi pi-inbox" style="font-size: 3rem; color: var(--text-color-secondary)"></i>
              <p>暂无日志数据</p>
            </div>
          </template>
        </DataTable>
      </template>
    </Card>

    <!-- 详情对话框 -->
    <Dialog
      v-model:visible="detailDialogVisible"
      modal
      :header="selectedLog?.display_name"
      :style="{ width: '800px' }"
    >
      <div v-if="selectedLog" class="log-detail">
        <div class="detail-section">
          <h4>基本信息</h4>
          <div class="detail-grid">
            <div class="detail-item">
              <label>ID</label>
              <span>{{ selectedLog.id }}</span>
            </div>
            <div class="detail-item">
              <label>操作类型</label>
              <Tag :value="selectedLog.action_type" :severity="getActionTypeSeverity(selectedLog.action_type)" />
            </div>
            <div class="detail-item">
              <label>状态</label>
              <Tag
                :value="selectedLog.display_status"
                :severity="selectedLog.status === 'success' ? 'success' : 'danger'"
              />
            </div>
            <div class="detail-item">
              <label>耗时</label>
              <span>{{ selectedLog.duration_in_seconds ? `${selectedLog.duration_in_seconds}s` : '-' }}</span>
            </div>
            <div class="detail-item">
              <label>操作人</label>
              <span>{{ selectedLog.sys_user?.name || '系统' }}</span>
            </div>
            <div class="detail-item">
              <label>创建时间</label>
              <span>{{ formatDateTime(selectedLog.created_at) }}</span>
            </div>
          </div>
        </div>

        <div class="detail-section">
          <h4>操作描述</h4>
          <p>{{ selectedLog.action }}</p>
        </div>

        <div class="detail-section">
          <h4>详细信息 (Remark)</h4>
          <pre class="remark-content">{{ JSON.stringify(selectedLog.remark, null, 2) }}</pre>
        </div>
      </div>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import Card from 'primevue/card'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Avatar from 'primevue/avatar'
import Dialog from 'primevue/dialog'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import InputText from 'primevue/inputtext'
import automationLogApi, { type AutomationLog } from '@/api/automation-log-api'
import { format } from 'date-fns'

const props = defineProps<{
  projectId: number
}>()

const toast = useToast()
const loading = ref(false)
const logs = ref<AutomationLog[]>([])

const pagination = ref({
  current_page: 1,
  per_page: 20,
  total: 0,
  total_pages: 0
})

const filters = ref({
  action_type: '',
  status: '',
  start_date: null as Date | null,
  end_date: null as Date | null,
  search: ''
})

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

// 加载日志列表
const loadLogs = async () => {
  loading.value = true
  try {
    const params: any = {
      page: pagination.value.current_page,
      per_page: pagination.value.per_page
    }

    if (filters.value.action_type) params.action_type = filters.value.action_type
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.start_date) params.start_date = format(filters.value.start_date, 'yyyy-MM-dd')
    if (filters.value.end_date) params.end_date = format(filters.value.end_date, 'yyyy-MM-dd')
    if (filters.value.search) params.search = filters.value.search

    const response = await automationLogApi.getProjectLogs(props.projectId, params)
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
    action_type: '',
    status: '',
    start_date: null,
    end_date: null,
    search: ''
  }
  pagination.value.current_page = 1
  loadLogs()
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

onMounted(() => {
  loadLogs()
})
</script>

<style scoped lang="scss">
.automation-logs-tab {
  padding: 0;
}

.filter-card {
  margin-bottom: 1.5rem;
}

.filter-container {
  display: flex;
  flex-direction: column;
  gap: 1rem;

  .filter-row {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    align-items: flex-end;

    .filter-item {
      flex: 1;
      min-width: 200px;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;

      label {
        font-size: 0.875rem;
        font-weight: 500;
        color: var(--text-color-secondary);
      }

      &.search-item {
        flex: 2;
      }
    }

    .filter-actions {
      display: flex;
      gap: 0.5rem;
    }
  }
}

.logs-card {
  .user-info {
    display: flex;
    align-items: center;
    gap: 0.5rem;

    .user-name {
      font-size: 0.875rem;
    }
  }

  .text-muted {
    color: var(--text-color-secondary);
    font-style: italic;
  }

  .action-desc {
    max-width: 300px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .empty-state {
    text-align: center;
    padding: 3rem;

    p {
      margin-top: 1rem;
      color: var(--text-color-secondary);
    }
  }
}

.log-detail {
  .detail-section {
    margin-bottom: 1.5rem;

    h4 {
      margin-bottom: 1rem;
      color: var(--text-color);
      font-size: 1rem;
      font-weight: 600;
    }

    .detail-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 1rem;

      .detail-item {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;

        label {
          font-size: 0.875rem;
          color: var(--text-color-secondary);
        }

        span {
          font-size: 0.875rem;
          color: var(--text-color);
        }
      }
    }

    p {
      color: var(--text-color);
      line-height: 1.6;
    }

    .remark-content {
      background: var(--surface-50);
      border: 1px solid var(--surface-200);
      border-radius: 6px;
      padding: 1rem;
      font-size: 0.875rem;
      color: var(--text-color);
      overflow-x: auto;
      max-height: 400px;
    }
  }
}
</style>
