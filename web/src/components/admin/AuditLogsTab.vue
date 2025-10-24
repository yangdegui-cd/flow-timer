<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import Dialog from 'primevue/dialog'
import Tag from 'primevue/tag'

import systemApi from '@/api/system-api'
import type { SysLog, SysLogListParams, SysLogListResponse } from '@/data/types/system-types'

const toast = useToast()

// 数据
const sysLogs = ref<SysLog[]>([])
const loading = ref(false)
const totalRecords = ref(0)
const first = ref(0)
const rows = ref(20)

// 筛选
const showFilterDialog = ref(false)
const filterParams = ref<SysLogListParams>({
  page: 1,
  per_page: 20
})

// 筛选选项
const controllerOptions = [
  { label: '全部控制器', value: '' },
  { label: '用户管理', value: 'sys_user' },
  { label: '角色管理', value: 'sys_role' },
  { label: '权限管理', value: 'sys_permission' },
  { label: '认证', value: 'auth' },
  { label: '系统日志', value: 'sys_logs' }
]

const actionOptions = [
  { label: '全部操作', value: '' },
  { label: '列表', value: 'index' },
  { label: '详情', value: 'show' },
  { label: '创建', value: 'create' },
  { label: '更新', value: 'update' },
  { label: '删除', value: 'destroy' },
  { label: '登录', value: 'login' },
  { label: '登出', value: 'logout' }
]

const methodOptions = [
  { label: '全部方法', value: '' },
  { label: 'GET', value: 'GET' },
  { label: 'POST', value: 'POST' },
  { label: 'PUT', value: 'PUT' },
  { label: 'PATCH', value: 'PATCH' },
  { label: 'DELETE', value: 'DELETE' }
]

const statusOptions = [
  { label: '全部状态', value: '' },
  { label: '成功 (200)', value: '200' },
  { label: '创建 (201)', value: '201' },
  { label: '无内容 (204)', value: '204' },
  { label: '客户端错误 (400)', value: '400' },
  { label: '未授权 (401)', value: '401' },
  { label: '禁止访问 (403)', value: '403' },
  { label: '未找到 (404)', value: '404' },
  { label: '服务器错误 (500)', value: '500' }
]

// 方法
const loadSysLogs = async () => {
  loading.value = true

  const params = {
    ...filterParams.value,
    page: Math.floor(first.value / rows.value) + 1,
    per_page: rows.value
  }
  systemApi.list(params).then((data: SysLogListResponse) => {
    sysLogs.value = data.logs
    totalRecords.value = data.pagination.total_count
  }).catch((err: any) => {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: err.message || '加载系统日志失败',
      life: 3000
    })
  }).finally(() => {
    loading.value = false
  })
}

const onPageChange = (event: any) => {
  first.value = event.first
  rows.value = event.rows
  loadSysLogs()
}

const applyFilter = () => {
  first.value = 0
  loadSysLogs()
  showFilterDialog.value = false
  toast.add({
    severity: 'success',
    summary: '筛选已应用',
    detail: '系统日志筛选条件已更新',
    life: 3000
  })
}

const clearFilter = () => {
  filterParams.value = {
    page: 1,
    per_page: 20
  }
  first.value = 0
  loadSysLogs()
  showFilterDialog.value = false
  toast.add({
    severity: 'info',
    summary: '筛选已清除',
    detail: '所有筛选条件已重置',
    life: 3000
  })
}

const exportLogs = async () => {
  toast.add({
    severity: 'info',
    summary: '导出功能',
    detail: '日志导出功能待开发',
    life: 3000
  })
}

const getActionSeverity = (action: string) => {
  switch (action) {
    case 'create': return 'success'
    case 'update': return 'info'
    case 'destroy': return 'danger'
    case 'index': return 'secondary'
    case 'show': return 'secondary'
    case 'login': return 'info'
    case 'logout': return 'secondary'
    default: return 'info'
  }
}

const getActionLabel = (action: string) => {
  switch (action) {
    case 'create': return '创建'
    case 'update': return '更新'
    case 'destroy': return '删除'
    case 'index': return '列表'
    case 'show': return '详情'
    case 'login': return '登录'
    case 'logout': return '登出'
    default: return action
  }
}

const getStatusSeverity = (statusCode: number) => {
  if (statusCode >= 200 && statusCode < 300) return 'success'
  if (statusCode >= 300 && statusCode < 400) return 'info'
  if (statusCode >= 400 && statusCode < 500) return 'warning'
  if (statusCode >= 500) return 'danger'
  return 'secondary'
}

const formatDuration = (duration: number) => {
  if (duration < 1000) return `${duration}ms`
  return `${(duration / 1000).toFixed(2)}s`
}

// 生命周期
onMounted(() => {
  loadSysLogs()
})
</script>

<template>
  <div class="audit-logs-tab">
    <!-- 工具栏 -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-4">
        <h2 class="text-lg font-semibold">系统日志</h2>
        <Button
          icon="pi pi-refresh"
          label="刷新"
          size="small"
          :loading="loading"
          @click="loadSysLogs"
        />
      </div>
      <div class="flex gap-2">
        <Button icon="pi pi-filter" label="筛选" size="small" outlined @click="showFilterDialog = true" />
        <Button icon="pi pi-download" label="导出" size="small" @click="exportLogs" />
      </div>
    </div>

    <!-- 系统日志表格 -->
    <DataTable
      :value="sysLogs"
      :loading="loading"
      :paginator="true"
      :rows="rows"
      :totalRecords="totalRecords"
      :lazy="true"
      paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
      currentPageReportTemplate="{first} 到 {last} 共 {totalRecords} 条"
      :rowsPerPageOptions="[10, 20, 50, 100]"
      dataKey="id"
      responsiveLayout="scroll"
      @page="onPageChange"
    >
      <Column field="id" header="ID" style="width: 80px" />
      <Column field="request_time" header="请求时间" style="width: 160px">
        <template #body="{ data }">
          {{ new Date(data.request_time).toLocaleString() }}
        </template>
      </Column>
      <Column field="user" header="用户" style="width: 120px">
        <template #body="{ data }">
          <div v-if="data.user">
            <div class="font-medium">{{ data.user.name }}</div>
            <div class="text-xs text-gray-500">{{ data.user.email }}</div>
          </div>
          <span v-else class="text-gray-400">未知</span>
        </template>
      </Column>
      <Column field="request_method" header="方法" style="width: 80px">
        <template #body="{ data }">
          <Tag :value="data.request_method"
               :severity="data.request_method === 'GET' ? 'secondary' : data.request_method === 'POST' ? 'success' : 'info'"
               size="small" />
        </template>
      </Column>
      <Column field="controller_name" header="控制器" style="width: 120px" />
      <Column field="action_name" header="操作" style="width: 100px">
        <template #body="{ data }">
          <Tag :value="getActionLabel(data.action_name)" :severity="getActionSeverity(data.action_name)" size="small" />
        </template>
      </Column>
      <Column field="status_code" header="状态码" style="width: 80px">
        <template #body="{ data }">
          <Tag :value="data.status_code" :severity="getStatusSeverity(data.status_code)" size="small" />
        </template>
      </Column>
      <Column field="duration" header="耗时" style="width: 100px">
        <template #body="{ data }">
          <span :class="data.slow ? 'text-red-600 font-medium' : data.duration > 500 ? 'text-orange-600' : 'text-green-600'">
            {{ formatDuration(data.duration) }}
          </span>
        </template>
      </Column>
      <Column field="ip_address" header="IP地址" style="width: 120px" />
      <Column field="request_url" header="请求路径" style="min-width: 200px">
        <template #body="{ data }">
          <div class="text-sm font-mono truncate" :title="data.request_url">
            {{ data.request_url }}
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- 筛选对话框 -->
    <Dialog v-model:visible="showFilterDialog" header="筛选系统日志" modal style="width: 700px">
      <div class="grid grid-cols-1 gap-4">
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium mb-2">用户ID</label>
            <InputText v-model="filterParams.user_id" class="w-full" size="small" placeholder="输入用户ID" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-2">控制器</label>
            <Dropdown
              v-model="filterParams.controller_name"
              :options="controllerOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择控制器"
              class="w-full"
              size="small"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-2">操作</label>
            <Dropdown
              v-model="filterParams.action_name"
              :options="actionOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择操作"
              class="w-full"
              size="small"
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-2">请求方法</label>
            <Dropdown
              v-model="filterParams.request_method"
              :options="methodOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择请求方法"
              class="w-full"
              size="small"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-2">状态码</label>
            <Dropdown
              v-model="filterParams.status_code"
              :options="statusOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择状态码"
              class="w-full"
              size="small"
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium mb-2">开始日期</label>
            <Calendar
              v-model="filterParams.start_date"
              placeholder="选择开始日期"
              class="w-full"
              size="small"
              dateFormat="yy-mm-dd"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-2">结束日期</label>
            <Calendar
              v-model="filterParams.end_date"
              placeholder="选择结束日期"
              class="w-full"
              size="small"
              dateFormat="yy-mm-dd"
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="flex items-center">
            <input type="checkbox" v-model="filterParams.errors_only" id="errors_only" class="mr-2" />
            <label for="errors_only" class="text-sm">只显示错误请求</label>
          </div>
          <div class="flex items-center">
            <input type="checkbox" v-model="filterParams.slow_requests" id="slow_requests" class="mr-2" />
            <label for="slow_requests" class="text-sm">只显示慢请求</label>
          </div>
        </div>
      </div>

      <template #footer>
        <Button label="清除筛选" icon="pi pi-times" text size="small" @click="clearFilter" />
        <Button label="应用筛选" icon="pi pi-check" size="small" @click="applyFilter" />
      </template>
    </Dialog>

    <!-- 空状态 -->
    <div v-if="!loading && sysLogs.length === 0" class="text-center py-8">
      <i class="pi pi-file-edit text-4xl text-gray-400"></i>
      <p class="text-gray-500 mt-2">暂无系统日志数据</p>
      <Button label="刷新" size="small" @click="loadSysLogs" class="mt-4" />
    </div>
  </div>
</template>

<style scoped>
.audit-logs-tab {
  height: 100%;
}
</style>
