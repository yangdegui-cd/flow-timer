<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import systemApi from '@/api/system-api'
import roleApi from '@/api/role-api'
import type { SysPermission, SysRole } from '@/data/types/system-types'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Select from 'primevue/select'
import PickList from 'primevue/picklist'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  role: SysRole | null
}>()

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const availablePermissions = ref<SysPermission[]>([])
const selectedPermissions = ref<SysPermission[]>([])
const originalPermissionIds = ref<number[]>([])
const searchQuery = ref('')
const selectedModule = ref('')

// Computed
const permissionLists = computed({
  get: () => [filteredAvailablePermissions.value, selectedPermissions.value],
  set: (value) => {
    selectedPermissions.value = value[1] || []
  }
})

const filteredAvailablePermissions = computed(() => {
  let result = availablePermissions.value.filter(p =>
    !selectedPermissions.value.some(sp => sp.id === p.id)
  )

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(p =>
      p.code.toLowerCase().includes(query) ||
      p.name.toLowerCase().includes(query) ||
      (p.description && p.description.toLowerCase().includes(query))
    )
  }

  if (selectedModule.value) {
    result = result.filter(p => p.module === selectedModule.value)
  }

  return result.sort((a, b) => a.code.localeCompare(b.code))
})

const moduleOptions = computed(() => {
  const modules = [...new Set(availablePermissions.value.map(p => p.module))].sort()
  return modules.map(module => ({
    label: getModuleLabel(module),
    value: module
  }))
})

const readPermissionsCount = computed(() =>
  selectedPermissions.value.filter(p => ['read', 'view'].includes(p.action)).length
)

const writePermissionsCount = computed(() =>
  selectedPermissions.value.filter(p => ['create', 'update', 'write'].includes(p.action)).length
)

const executePermissionsCount = computed(() =>
  selectedPermissions.value.filter(p => ['delete', 'execute'].includes(p.action)).length
)

const moduleCount = computed(() =>
  new Set(selectedPermissions.value.map(p => p.module)).size
)

const hasChanges = computed(() => {
  const currentIds = selectedPermissions.value.map(p => p.id).sort()
  return JSON.stringify(currentIds) !== JSON.stringify(originalPermissionIds.value.sort())
})

// Methods
const loadPermissions = () => {
  systemApi.list('sys_permission').then(data => {
    availablePermissions.value = data.permissions || data || []
  }).catch(error => {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取权限列表失败',
      life: 5000
    })
  })
}

const loadRolePermissions = (roleId: number) => {
  // 尝试直接从角色对象获取权限
  if (props.role && props.role.permissions && Array.isArray(props.role.permissions)) {
    console.log('Loading permissions from role object:', props.role.permissions)
    selectedPermissions.value = props.role.permissions
    originalPermissionIds.value = selectedPermissions.value.map(p => p.id)
    return
  }

  // 如果角色对象没有权限信息，则通过API获取
  console.log('Loading permissions via API for role:', roleId)
  systemApi.get(`sys_role/${roleId}/permissions`).then(data => {
    console.log('API returned permissions:', data)
    selectedPermissions.value = data.permissions || data || []
    originalPermissionIds.value = selectedPermissions.value.map(p => p.id)
  }).catch(error => {
    console.warn('Failed to load role permissions, using fallback:', error.message)
    selectedPermissions.value = []
    originalPermissionIds.value = []
  })
}

const selectAllFiltered = () => {
  const toAdd = filteredAvailablePermissions.value.filter(p =>
    !selectedPermissions.value.some(sp => sp.id === p.id)
  )
  selectedPermissions.value = [...selectedPermissions.value, ...toAdd]
}

const selectByModule = () => {
  if (!selectedModule.value) return

  const modulePermissions = availablePermissions.value.filter(p =>
    p.module === selectedModule.value && !selectedPermissions.value.some(sp => sp.id === p.id)
  )
  selectedPermissions.value = [...selectedPermissions.value, ...modulePermissions]
}

const removeAllPermissions = () => {
  selectedPermissions.value = []
}

const removeByModule = () => {
  if (!selectedModule.value) return

  selectedPermissions.value = selectedPermissions.value.filter(p => p.module !== selectedModule.value)
}

const getRoleColorClass = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'bg-red-500'
    case 'developer': return 'bg-blue-500'
    case 'operator': return 'bg-orange-500'
    case 'viewer': return 'bg-gray-500'
    default: return 'bg-primary-500'
  }
}

const getModuleLabel = (module: string): string => {
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

const handleUpdatePermissions = () => {
  if (!props.role) return

  loading.value = true
  const permissionIds = selectedPermissions.value.map(p => p.id)

  systemApi.put(`sys_role/${props.role.id}/assign_permissions`, {
    permission_ids: permissionIds
  }).then(data => {
    toast.add({
      severity: 'success',
      summary: '权限更新成功',
      detail: `已为角色分配 ${permissionIds.length} 个权限`,
      life: 3000
    })

    originalPermissionIds.value = permissionIds
    emit('success')
    visible.value = false
  }).catch(error => {
    toast.add({
      severity: 'error',
      summary: '权限更新失败',
      detail: error.message || '更新角色权限失败',
      life: 5000
    })
  }).finally(() => {
    loading.value = false
  })
}

const handleCancel = () => {
  visible.value = false
  // 恢复原始权限
  if (props.role) {
    loadRolePermissions(props.role.id)
  }
}

// Watchers
watch(visible, (newVal) => {
  if (newVal) {
    searchQuery.value = ''
    selectedModule.value = ''
    loadPermissions()
    if (props.role) {
      loadRolePermissions(props.role.id)
    }
  }
})

watch(() => props.role, (newRole) => {
  if (newRole && visible.value) {
    console.log('Role changed, reloading permissions for:', newRole)
    loadRolePermissions(newRole.id)
  }
}, { immediate: true })

// Lifecycle
onMounted(() => {
  loadPermissions()
})
</script>

<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="编辑权限"
    class="w-full max-w-6xl max-h-[100vh]"
    :closable="true"
    :draggable="false"
  >
    <div v-if="role" class="space-y-6">
      <!-- 角色信息 -->
      <div class="flex items-center space-x-3 p-4 bg-surface-50 rounded-lg">
        <div
          class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold"
          :class="getRoleColorClass(role.name)"
        >
          {{ role.display_name?.charAt(0) || role.name.charAt(0) }}
        </div>
        <div class="flex-1">
          <h3 class="font-semibold text-lg">{{ role.display_name || role.name }}</h3>
          <p class="text-sm text-surface-500">{{ role.description || role.name }}</p>
        </div>
        <div class="text-right text-sm text-surface-600">
          <div>当前权限: {{ selectedPermissions.length }}</div>
          <div>可用权限: {{ availablePermissions.length }}</div>
        </div>
      </div>

      <!-- 搜索和筛选 -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-surface-700 mb-2">搜索权限</label>
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText
              v-model="searchQuery"
              placeholder="搜索权限代码或名称..."
              size="small"
              class="w-full"
            />
          </IconField>
        </div>
        <div>
          <label class="block text-sm font-medium text-surface-700 mb-2">按模块筛选</label>
          <Select
            v-model="selectedModule"
            :options="moduleOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择模块"
            size="small"
            class="w-full"
            showClear
          />
        </div>
      </div>

      <!-- 权限选择器 -->
      <div class="permission-picker">
        <PickList
          v-model="permissionLists"
          :meta-key-selection="false"
          :breakpoint="'1400px'"
          :list-style="{height: '100%', maxHeight: '400px'}"
          class="permission-picklist"
        >
          <template #sourceheader>
            <div class="font-semibold p-4 bg-surface-100 flex items-center justify-between">
              <span>可分配权限</span>
              <Tag
                :value="filteredAvailablePermissions.length.toString()"
                severity="info"
                size="small"
              />
              <div class="flex space-x-2">
                <Button
                    @click="selectAllFiltered"
                    icon="pi pi-plus"
                    label="全部添加"
                    size="small"
                    text
                    :disabled="filteredAvailablePermissions.length === 0"
                />
                <Button
                    @click="selectByModule"
                    icon="pi pi-tags"
                    label="按模块添加"
                    size="small"
                    text
                    :disabled="!selectedModule"
                />
              </div>
            </div>

          </template>

          <template #targetheader>
            <div class="font-semibold p-4 bg-surface-100 flex items-center justify-between">
              <div>
                <span>已分配权限</span>
                <Tag
                    :value="selectedPermissions.length.toString()"
                    severity="success"
                    size="small"
                />
              </div>
              <div class="flex space-x-2">
                <Button
                    @click="removeAllPermissions"
                    icon="pi pi-minus"
                    label="全部移除"
                    size="small"
                    text
                    severity="danger"
                    :disabled="selectedPermissions.length === 0"
                />
                <Button
                    @click="removeByModule"
                    icon="pi pi-filter-slash"
                    label="按模块移除"
                    size="small"
                    text
                    severity="danger"
                    :disabled="!selectedModule || selectedPermissions.length === 0"
                />
              </div>
            </div>
          </template>

          <template #item="{ item }">
            <div class="p-3 hover:bg-surface-50 border-b border-surface-200 w-full h-full">
              <div class="flex items-center justify-between w-full">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center space-x-2">
                    <code class="text-xs bg-surface-200 px-2 py-1 rounded font-mono text-surface-700 truncate">
                      {{ item.code }}
                    </code>
                    <Tag
                      :value="getActionLabel(item.action)"
                      :severity="getActionSeverity(item.action)"
                      size="small"
                    />
                  </div>
                  <h4 class="font-medium text-surface-900 mt-1 truncate">{{ item.name }}</h4>
                </div>
                <div class="flex flex-col items-end space-y-1 ml-3">
                  <Tag
                    :value="getModuleLabel(item.module)"
                    :severity="item.is_system ? 'info' : 'secondary'"
                    size="small"
                  />
                  <div class="text-xs text-surface-500">
                    {{ item.is_system ? '系统' : '自定义' }}
                  </div>
                </div>
              </div>
            </div>
          </template>
        </PickList>
      </div>

      <!-- 权限统计 -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="bg-blue-50 p-4 rounded-lg text-center">
          <div class="text-2xl font-bold text-primary-600">{{ readPermissionsCount }}</div>
          <div class="text-sm text-primary-700">读取权限</div>
        </div>
        <div class="bg-green-50 p-4 rounded-lg text-center">
          <div class="text-2xl font-bold text-green-600">{{ writePermissionsCount }}</div>
          <div class="text-sm text-green-700">写入权限</div>
        </div>
        <div class="bg-red-50 p-4 rounded-lg text-center">
          <div class="text-2xl font-bold text-red-600">{{ executePermissionsCount }}</div>
          <div class="text-sm text-red-700">执行权限</div>
        </div>
        <div class="bg-purple-50 p-4 rounded-lg text-center">
          <div class="text-2xl font-bold text-purple-600">{{ moduleCount }}</div>
          <div class="text-sm text-purple-700">涉及模块</div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <div class="text-sm text-surface-600">
          总权限数: {{ availablePermissions.length }} | 已选择: {{ selectedPermissions.length }}
          ({{ Math.round((selectedPermissions.length / Math.max(availablePermissions.length, 1)) * 100) }}%)
        </div>
        <div class="flex space-x-2">
          <Button
            label="取消"
            @click="handleCancel"
            severity="secondary"
            size="small"
            :disabled="loading"
          />
          <Button
            label="保存权限"
            @click="handleUpdatePermissions"
            size="small"
            :loading="loading"
            :disabled="!hasChanges"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
.permission-picker :deep(.p-picklist) {
  grid-template-columns: 1fr auto 1fr;
  min-height: 500px;
}

.permission-picker :deep(.p-picklist-list) {
  height: 500px;
  overflow-y: auto;
  border: 1px solid var(--surface-300);
  border-radius: 8px;
}

.permission-picker :deep(.p-picklist-buttons) {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem 0;
}

.permission-picker :deep(.p-picklist-buttons .p-button) {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
}

.permission-item {
  transition: all 0.2s ease;
  cursor: pointer;
}

.permission-item:hover {
  background-color: var(--surface-100) !important;
}

.permission-item:last-child {
  border-bottom: none;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

:deep(.p-dialog-header) {
  padding: 1.5rem 1.5rem 0;
}

:deep(.p-dialog-content) {
  padding: 1.5rem;
  overflow: visible;
}

:deep(.p-dialog-footer) {
  padding: 0 1.5rem 1.5rem;
}

@media (max-width: 1400px) {
  .permission-picker :deep(.p-picklist) {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .permission-picker :deep(.p-picklist-buttons) {
    flex-direction: row;
    justify-content: center;
    padding: 0.5rem 0;
  }
}
</style>
