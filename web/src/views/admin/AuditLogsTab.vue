<template>
  <div class="audit-logs-tab">
    <!-- 筛选器 -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
      <div>
        <h2 class="text-xl font-semibold text-surface-900">审计日志</h2>
        <p class="text-surface-600 text-sm mt-1">系统操作记录和安全审计</p>
      </div>
      
      <div class="flex items-center space-x-3">
        <Dropdown
          v-model="filters.action_type"
          :options="actionTypeOptions"
          optionLabel="label"
          optionValue="value"
          placeholder="操作类型"
          @change="loadLogs"
          class="w-40"
          showClear
        />
        
        <Dropdown
          v-model="filters.level"
          :options="levelOptions"
          optionLabel="label"
          optionValue="value"
          placeholder="日志级别"
          @change="loadLogs"
          class="w-32"
          showClear
        />
        
        <Calendar 
          v-model="filters.date_range"
          selectionMode="range"
          :manualInput="false"
          placeholder="选择日期范围"
          @date-select="loadLogs"
          class="w-64"
        />
        
        <Button 
          @click="refreshLogs"
          icon="pi pi-refresh"
          tooltip="刷新日志"
          size="small"
        />
      </div>
    </div>

    <!-- 日志表格 -->
    <DataTable 
      :value="logs" 
      :loading="loading"
      paginator 
      :rows="20"
      dataKey="id"
      stripedRows
      showGridlines
      class="audit-table"
    >
      <Column field="timestamp" header="时间" sortable class="w-44">
        <template #body="{ data }">
          <div class="font-mono text-sm">
            {{ formatDateTime(data.timestamp) }}
          </div>
        </template>
      </Column>
      
      <Column field="level" header="级别" class="w-20">
        <template #body="{ data }">
          <Tag 
            :value="data.level"
            :severity="getLevelSeverity(data.level)"
            size="small"
          />
        </template>
      </Column>
      
      <Column field="action_type" header="操作类型" class="w-32">
        <template #body="{ data }">
          <div class="flex items-center space-x-2">
            <i :class="getActionIcon(data.action_type)" class="text-sm"></i>
            <span class="text-sm">{{ getActionLabel(data.action_type) }}</span>
          </div>
        </template>
      </Column>
      
      <Column field="user" header="操作用户" class="w-40">
        <template #body="{ data }">
          <div v-if="data.user" class="flex items-center space-x-2">
            <Avatar 
              :label="data.user.avatar_url ? undefined : data.user.name.charAt(0)"
              :image="data.user.avatar_url"
              shape="circle"
              size="small"
              class="bg-primary-100 text-primary-600"
            />
            <div>
              <div class="text-sm font-medium">{{ data.user.name }}</div>
              <div class="text-xs text-surface-500">{{ data.user.email }}</div>
            </div>
          </div>
          <span v-else class="text-sm text-surface-400">系统操作</span>
        </template>
      </Column>
      
      <Column field="description" header="操作描述">
        <template #body="{ data }">
          <div class="text-sm">{{ data.description }}</div>
          <div v-if="data.target_type && data.target_id" class="text-xs text-surface-500 mt-1">
            目标: {{ data.target_type }}#{{ data.target_id }}
          </div>
        </template>
      </Column>
      
      <Column field="ip_address" header="IP地址" class="w-32">
        <template #body="{ data }">
          <span class="font-mono text-sm">{{ data.ip_address || '-' }}</span>
        </template>
      </Column>
      
      <Column header="操作" class="w-24">
        <template #body="{ data }">
          <Button 
            @click="viewLogDetail(data)"
            icon="pi pi-eye"
            size="small"
            text
            rounded
            tooltip="查看详情"
          />
        </template>
      </Column>
    </DataTable>

    <!-- 日志详情对话框 -->
    <Dialog 
      v-model:visible="showDetailDialog" 
      modal 
      header="日志详情" 
      class="w-full max-w-2xl"
    >
      <div v-if="selectedLog" class="space-y-4">
        <!-- 基本信息 -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-surface-700">时间</label>
            <div class="font-mono text-sm">{{ formatDateTime(selectedLog.timestamp) }}</div>
          </div>
          <div>
            <label class="text-sm font-medium text-surface-700">级别</label>
            <div>
              <Tag 
                :value="selectedLog.level"
                :severity="getLevelSeverity(selectedLog.level)"
                size="small"
              />
            </div>
          </div>
          <div>
            <label class="text-sm font-medium text-surface-700">操作类型</label>
            <div class="text-sm">{{ getActionLabel(selectedLog.action_type) }}</div>
          </div>
          <div>
            <label class="text-sm font-medium text-surface-700">IP地址</label>
            <div class="font-mono text-sm">{{ selectedLog.ip_address || '-' }}</div>
          </div>
        </div>

        <Divider />

        <!-- 操作描述 -->
        <div>
          <label class="text-sm font-medium text-surface-700">操作描述</label>
          <div class="text-sm mt-1">{{ selectedLog.description }}</div>
        </div>

        <!-- 详细数据 -->
        <div v-if="selectedLog.details">
          <label class="text-sm font-medium text-surface-700">详细数据</label>
          <pre class="bg-surface-100 p-3 rounded-lg text-xs overflow-auto mt-1">{{ JSON.stringify(selectedLog.details, null, 2) }}</pre>
        </div>

        <!-- 用户信息 -->
        <div v-if="selectedLog.user">
          <label class="text-sm font-medium text-surface-700">操作用户</label>
          <div class="flex items-center space-x-3 mt-1">
            <Avatar 
              :label="selectedLog.user.avatar_url ? undefined : selectedLog.user.name.charAt(0)"
              :image="selectedLog.user.avatar_url"
              shape="circle"
              class="bg-primary-100 text-primary-600"
            />
            <div>
              <div class="font-medium">{{ selectedLog.user.name }}</div>
              <div class="text-sm text-surface-500">{{ selectedLog.user.email }}</div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <Button 
          label="关闭" 
          @click="showDetailDialog = false"
        />
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'

import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import Dialog from 'primevue/dialog'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import Divider from 'primevue/divider'

// Services
const toast = useToast()

// Data
const loading = ref(false)
const showDetailDialog = ref(false)

const logs = ref<Array<any>>([])
const selectedLog = ref<any>(null)

const filters = reactive({
  action_type: '',
  level: '',
  date_range: null as Date[] | null
})

// Options
const actionTypeOptions = [
  { label: '用户登录', value: 'user_login' },
  { label: '用户注册', value: 'user_register' },
  { label: '用户更新', value: 'user_update' },
  { label: '用户删除', value: 'user_delete' },
  { label: '角色创建', value: 'role_create' },
  { label: '角色更新', value: 'role_update' },
  { label: '角色删除', value: 'role_delete' },
  { label: '权限变更', value: 'permission_change' },
  { label: '系统配置', value: 'system_config' }
]

const levelOptions = [
  { label: 'INFO', value: 'info' },
  { label: 'WARN', value: 'warn' },
  { label: 'ERROR', value: 'error' },
  { label: 'DEBUG', value: 'debug' }
]

// Methods
const loadLogs = async () => {
  loading.value = true
  
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 800))
    
    // 模拟数据
    logs.value = [
      {
        id: '1',
        timestamp: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
        level: 'info',
        action_type: 'user_login',
        description: '管理员登录系统',
        user: {
          name: '系统管理员',
          email: 'admin@flow-timer.com',
          avatar_url: null
        },
        ip_address: '192.168.1.100',
        target_type: null,
        target_id: null,
        details: {
          user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
          login_method: 'email_password'
        }
      },
      {
        id: '2',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
        level: 'warn',
        action_type: 'user_update',
        description: '用户状态变更为禁用',
        user: {
          name: '系统管理员',
          email: 'admin@flow-timer.com',
          avatar_url: null
        },
        ip_address: '192.168.1.100',
        target_type: 'User',
        target_id: '5',
        details: {
          old_status: 'active',
          new_status: 'suspended',
          reason: '违反使用规则'
        }
      },
      {
        id: '3',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString(),
        level: 'info',
        action_type: 'role_create',
        description: '创建新角色',
        user: {
          name: '系统管理员',
          email: 'admin@flow-timer.com',
          avatar_url: null
        },
        ip_address: '192.168.1.100',
        target_type: 'Role',
        target_id: '5',
        details: {
          role_name: 'tester',
          role_display_name: '测试员',
          permissions: ['view_tasks', 'create_tasks']
        }
      },
      {
        id: '4',
        timestamp: new Date(Date.now() - 1000 * 60 * 60 * 8).toISOString(),
        level: 'error',
        action_type: 'user_login',
        description: '用户登录失败 - 密码错误',
        user: null,
        ip_address: '192.168.1.200',
        target_type: null,
        target_id: null,
        details: {
          email: 'test@example.com',
          failure_reason: 'invalid_password',
          attempt_count: 3
        }
      }
    ]
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取日志数据失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

const refreshLogs = () => {
  loadLogs()
}

const viewLogDetail = (log: any) => {
  selectedLog.value = log
  showDetailDialog.value = true
}

// Helpers
const getLevelSeverity = (level: string) => {
  switch (level.toLowerCase()) {
    case 'error': return 'danger'
    case 'warn': return 'warning'
    case 'info': return 'info'
    case 'debug': return 'secondary'
    default: return 'secondary'
  }
}

const getActionIcon = (actionType: string) => {
  switch (actionType) {
    case 'user_login': return 'pi pi-sign-in'
    case 'user_register': return 'pi pi-user-plus'
    case 'user_update': return 'pi pi-user-edit'
    case 'user_delete': return 'pi pi-user-minus'
    case 'role_create': return 'pi pi-plus-circle'
    case 'role_update': return 'pi pi-pencil'
    case 'role_delete': return 'pi pi-trash'
    case 'permission_change': return 'pi pi-shield'
    case 'system_config': return 'pi pi-cog'
    default: return 'pi pi-info-circle'
  }
}

const getActionLabel = (actionType: string) => {
  const labels: Record<string, string> = {
    'user_login': '用户登录',
    'user_register': '用户注册',
    'user_update': '用户更新',
    'user_delete': '用户删除',
    'role_create': '角色创建',
    'role_update': '角色更新',
    'role_delete': '角色删除',
    'permission_change': '权限变更',
    'system_config': '系统配置'
  }
  return labels[actionType] || actionType
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

// Lifecycle
onMounted(() => {
  loadLogs()
})
</script>

<style scoped>
.audit-logs-tab {
  max-width: 100%;
}

:deep(.audit-table) {
  .p-datatable-thead > tr > th {
    background: var(--p-surface-50);
    color: var(--p-text-color);
    border-color: var(--p-surface-200);
  }
}
</style>