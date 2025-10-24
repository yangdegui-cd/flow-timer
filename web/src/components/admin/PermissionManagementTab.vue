<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import systemApi from '@/api/system-api'
import userApi from '@/api/user-api'
import type { Permission } from '@/data/types/user-types'
import Card from 'primevue/card'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Select from 'primevue/select'

import CreatePermissionDialog from '@/views/_dialogs/CreatePermissionDialog.vue'
import PermissionModuleDialog from '@/views/_dialogs/PermissionModuleDialog.vue'
import EditPermissionDialog from '@/views/_dialogs/EditPermissionDialog.vue'
import permissionApi from "@/api/permission-api";

// 为兼容性定义SysPermission类型
type SysPermission = Permission & {
  code: string
  is_system: boolean
  is_active: boolean
}

// Emits
const emit = defineEmits<{
  refresh: []
}>()

// Stores & Services
const authStore = useAuthStore()
const confirm = useConfirm()
const toast = useToast()

// Data
const permissions = ref<SysPermission[]>([])
const loading = ref(false)
const syncing = ref(false)
const selectedPermission = ref<SysPermission | null>(null)
const selectedModule = ref<string>('')
const selectedPermissions = ref<SysPermission[]>([])

// Filters
const filters = ref({
  search: '',
  module: '',
  action: ''
})

// Dialogs
const showCreateDialog = ref(false)
const showModuleDialog = ref(false)
const showEditDialog = ref(false)

// Computed
const filteredPermissions = computed(() => {
  let result = permissions.value

  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    result = result.filter(p =>
      p.code.toLowerCase().includes(search) ||
      p.name.toLowerCase().includes(search) ||
      (p.description && p.description.toLowerCase().includes(search))
    )
  }

  if (filters.value.module) {
    result = result.filter(p => p.module === filters.value.module)
  }

  if (filters.value.action) {
    result = result.filter(p => p.action === filters.value.action)
  }

  return result
})

const groupedPermissions = computed(() => {
  const groups: Record<string, SysPermission[]> = {}

  filteredPermissions.value.forEach(permission => {
    if (!groups[permission.module]) {
      groups[permission.module] = []
    }
    groups[permission.module].push(permission)
  })

  // 按权限数量排序模块
  const sortedEntries = Object.entries(groups).sort((a, b) => b[1].length - a[1].length)

  return Object.fromEntries(sortedEntries)
})

const moduleOptions = computed(() => {
  const modules = [...new Set(permissions.value.map(p => p.module))].sort()
  return modules.map(module => ({
    label: getModuleDisplayName(module),
    value: module
  }))
})

const actionOptions = computed(() => {
  const actions = [...new Set(permissions.value.map(p => p.action))].sort()
  return actions.map(action => ({
    label: getActionLabel(action),
    value: action
  }))
})

// Methods
const loadPermissions = () => {
  loading.value = true
  permissionApi.list().then(data => {
    permissions.value = data
  }).catch(error => {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取权限列表失败',
      life: 5000
    })
  }).finally(() => {
    loading.value = false
  })
}

const refreshPermissions = () => {
  loadPermissions()
  emit('refresh')
}

const filterPermissions = () => {
  // 触发计算属性重新计算
}

const syncPermissions = async () => {
  syncing.value = true

  try {
    // Use system API for administrative functions
    const response = await systemApi.post('permissions/sync')

    toast.add({
      severity: 'success',
      summary: '同步成功',
      detail: response.message || '系统权限已同步',
      life: 3000
    })
    refreshPermissions()
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '同步失败',
      detail: error.message || '同步系统权限失败',
      life: 5000
    })
  } finally {
    syncing.value = false
  }
}

// Permission actions
const viewModulePermissions = (moduleName: string, modulePermissions: SysPermission[]) => {
  selectedModule.value = moduleName
  selectedPermissions.value = modulePermissions
  showModuleDialog.value = true
}

const editPermission = (permission: SysPermission) => {
  selectedPermission.value = permission
  showEditDialog.value = true
}

const deletePermission = (permission: SysPermission) => {
  confirm.require({
    message: `确定要删除权限 "${permission.name}" 吗？此操作不可恢复。`,
    header: '删除权限',
    icon: 'pi pi-trash',
    rejectLabel: '取消',
    acceptLabel: '删除',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await systemApi.delete(`permissions/${permission.id}`)
        toast.add({
          severity: 'success',
          summary: '删除成功',
          detail: `权限 "${permission.name}" 已删除`,
          life: 3000
        })
        refreshPermissions()
      } catch (error: any) {
        toast.add({
          severity: 'error',
          summary: '删除失败',
          detail: error.message || '删除权限失败',
          life: 5000
        })
      }
    }
  })
}

const exportModulePermissions = (moduleName: string, modulePermissions: SysPermission[]) => {
  const data = modulePermissions.map(p => ({
    模块: p.module,
    权限代码: p.code,
    权限名称: p.name,
    描述: p.description || '',
    动作类型: p.action,
    系统权限: p.is_system ? '是' : '否',
    状态: p.is_active ? '启用' : '禁用'
  }))

  const csv = [
    Object.keys(data[0]).join(','),
    ...data.map(row => Object.values(row).map(v => `"${v}"`).join(','))
  ].join('\n')

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${getModuleDisplayName(moduleName)}_permissions.csv`
  link.click()
  URL.revokeObjectURL(url)
}

// Helpers
const getModuleDisplayName = (module: string): string => {
  const moduleNames: Record<string, string> = {
    sys_user: '用户管理',
    sys_role: '角色管理',
    sys_permission: '权限管理',
    ft_task: '任务管理',
    ft_flow: '流程管理',
    ft_task_execution: '任务执行',
    catalog: '目录管理',
    space: '空间管理',
    meta_datasource: '数据源',
    meta_host: '主机管理',
    resque_monitor: '监控管理',
    system: '系统管理'
  }
  return moduleNames[module] || module
}

const getModuleColorClass = (module: string): string => {
  const colorMap: Record<string, string> = {
    sys_user: 'bg-blue-500',
    sys_role: 'bg-purple-500',
    sys_permission: 'bg-violet-500',
    ft_task: 'bg-green-500',
    ft_flow: 'bg-orange-500',
    ft_task_execution: 'bg-pink-500',
    catalog: 'bg-yellow-500',
    space: 'bg-teal-500',
    meta_datasource: 'bg-cyan-500',
    meta_host: 'bg-indigo-500',
    resque_monitor: 'bg-gray-500',
    system: 'bg-slate-500'
  }
  return colorMap[module] || 'bg-primary-500'
}

const getModuleIcon = (module: string): string => {
  const iconMap: Record<string, string> = {
    sys_user: 'pi pi-users',
    sys_role: 'pi pi-shield',
    sys_permission: 'pi pi-key',
    ft_task: 'pi pi-cog',
    ft_flow: 'pi pi-sitemap',
    ft_task_execution: 'pi pi-play-circle',
    catalog: 'pi pi-folder',
    space: 'pi pi-th-large',
    meta_datasource: 'pi pi-database',
    meta_host: 'pi pi-server',
    resque_monitor: 'pi pi-chart-line',
    system: 'pi pi-wrench'
  }
  return iconMap[module] || 'pi pi-circle'
}

const getActionLabel = (action: string): string => {
  const actionLabels: Record<string, string> = {
    read: '读取',
    write: '写入',
    view: '查看',
    create: '创建',
    update: '更新',
    delete: '删除',
    execute: '执行',
    manage: '管理',
    assign: '分配',
    backup: '备份',
    config: '配置',
    logs: '日志',
    monitor: '监控',
    publish: '发布',
    retry: '重试',
    stop: '停止'
  }
  return actionLabels[action] || action
}

const getActionSeverity = (action: string): string => {
  const severityMap: Record<string, string> = {
    read: 'info',
    write: 'warning',
    view: 'info',
    create: 'success',
    update: 'warning',
    delete: 'danger',
    execute: 'danger',
    manage: 'warning',
    assign: 'warning',
    backup: 'secondary',
    config: 'warning',
    logs: 'info',
    monitor: 'info',
    publish: 'success',
    retry: 'warning',
    stop: 'danger'
  }
  return severityMap[action] || 'secondary'
}

// Lifecycle
onMounted(() => {
  loadPermissions()
})
</script>

<template>
  <div class="permission-management-tab">
    <!-- 操作栏 -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
      <div>
        <h2 class="text-xl font-semibold text-surface-900">权限列表</h2>
        <p class="text-surface-600 text-sm mt-1">管理系统权限和访问控制</p>
      </div>

      <div class="flex items-center space-x-3">
        <Button
          @click="syncPermissions"
          icon="pi pi-refresh"
          label="同步权限"
          severity="secondary"
          size="small"
          v-if="authStore.hasPermission('manage_system')"
          :loading="syncing"
        />
        <Button
          @click="showCreateDialog = true"
          icon="pi pi-plus"
          label="新增权限"
          size="small"
          v-if="authStore.hasPermission('manage_system')"
        />
      </div>
    </div>

    <!-- 筛选工具栏 -->
    <div class="bg-surface-0 p-4 rounded-lg shadow-sm mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-sm font-medium text-surface-700 mb-2">搜索</label>
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText
              v-model="filters.search"
              placeholder="搜索权限代码、名称或描述"
              @input="filterPermissions"
              size="small"
              class="w-full"
            />
          </IconField>
        </div>

        <div>
          <label class="block text-sm font-medium text-surface-700 mb-2">模块</label>
          <Select
            v-model="filters.module"
            :options="moduleOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择模块"
            @change="filterPermissions"
            size="small"
            class="w-full"
            showClear
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-surface-700 mb-2">动作类型</label>
          <Select
            v-model="filters.action"
            :options="actionOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择动作类型"
            @change="filterPermissions"
            size="small"
            class="w-full"
            showClear
          />
        </div>
      </div>
    </div>

    <!-- 权限模块卡片 -->
    <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
      <Card
        v-for="(modulePermissions, moduleName) in groupedPermissions"
        :key="moduleName"
        class="permission-module-card hover:shadow-lg transition-shadow"
      >
        <template #header>
          <div class="p-6 pb-0">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center space-x-3">
                <div
                  class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg"
                  :class="getModuleColorClass(moduleName)"
                >
                  <i :class="getModuleIcon(moduleName)"></i>
                </div>
                <div>
                  <h3 class="font-semibold text-lg text-surface-900">{{ getModuleDisplayName(moduleName) }}</h3>
                  <p class="text-sm text-surface-500">{{ modulePermissions.length }} 个权限</p>
                </div>
              </div>

              <Tag
                :value="`${modulePermissions.filter(p => p.is_system).length} 系统`"
                severity="info"
                size="small"
              />
            </div>
          </div>
        </template>

        <template #content>
          <div class="space-y-3">
            <!-- 动作类型统计 -->
            <div class="grid grid-cols-3 gap-2 text-center">
              <div class="bg-blue-50 p-2 rounded">
                <div class="text-sm font-bold text-primary-600">
                  {{ modulePermissions.filter(p => ['read', 'view'].includes(p.action)).length }}
                </div>
                <div class="text-xs text-primary-500">读取</div>
              </div>
              <div class="bg-green-50 p-2 rounded">
                <div class="text-sm font-bold text-green-600">
                  {{ modulePermissions.filter(p => ['create', 'update', 'write'].includes(p.action)).length }}
                </div>
                <div class="text-xs text-green-500">写入</div>
              </div>
              <div class="bg-red-50 p-2 rounded">
                <div class="text-sm font-bold text-red-600">
                  {{ modulePermissions.filter(p => ['delete', 'execute'].includes(p.action)).length }}
                </div>
                <div class="text-xs text-red-500">执行</div>
              </div>
            </div>

            <!-- 权限列表预览 -->
            <div>
              <div class="text-sm font-medium text-surface-700 mb-2">权限预览</div>
              <div class="space-y-1 max-h-32 overflow-y-auto">
                <div
                  v-for="permission in modulePermissions.slice(0, 6)"
                  :key="permission.id"
                  class="flex items-center justify-between text-xs bg-surface-50 p-2 rounded"
                >
                  <span class="font-mono text-surface-700 truncate">{{ permission.code }}</span>
                  <Tag
                    :value="getActionLabel(permission.action)"
                    size="small"
                    :severity="getActionSeverity(permission.action)"
                  />
                </div>
                <div
                  v-if="modulePermissions.length > 6"
                  class="text-center text-xs text-surface-500 py-1"
                >
                  还有 {{ modulePermissions.length - 6 }} 个权限...
                </div>
              </div>
            </div>
          </div>
        </template>

        <template #footer>
          <div class="flex justify-end space-x-2">
            <Button
              @click="viewModulePermissions(moduleName, modulePermissions)"
              icon="pi pi-list"
              size="small"
              text
              rounded
              tooltip="查看所有权限"
            />

            <Button
              @click="exportModulePermissions(moduleName, modulePermissions)"
              icon="pi pi-download"
              size="small"
              text
              rounded
              tooltip="导出权限"
              v-if="authStore.hasPermission('manage_system')"
            />
          </div>
        </template>
      </Card>

      <!-- 空状态 -->
      <div v-if="Object.keys(groupedPermissions).length === 0 && !loading" class="col-span-full">
        <Card class="text-center py-12">
          <template #content>
            <i class="pi pi-shield text-4xl text-surface-400 mb-4 block"></i>
            <p class="text-surface-500 text-lg">暂无权限数据</p>
          </template>
        </Card>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <ProgressSpinner size="50" strokeWidth="4" />
    </div>

    <!-- 对话框组件 -->
    <CreatePermissionDialog
      v-model:visible="showCreateDialog"
      @success="refreshPermissions"
    />

    <PermissionModuleDialog
      v-model:visible="showModuleDialog"
      :module-name="selectedModule"
      :permissions="selectedPermissions"
      @edit="editPermission"
      @delete="deletePermission"
    />

    <EditPermissionDialog
      v-model:visible="showEditDialog"
      :permission="selectedPermission"
      @success="refreshPermissions"
    />
  </div>
</template>

<style scoped>
.permission-management-tab {
  max-width: 100%;
}

.permission-module-card {
  transition: all 0.2s ease;
}

.permission-module-card:hover {
  transform: translateY(-2px);
}
</style>
