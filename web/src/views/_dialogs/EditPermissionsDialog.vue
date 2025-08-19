<template>
  <Dialog 
    v-model:visible="visible" 
    modal 
    header="编辑权限" 
    class="w-full max-w-2xl"
  >
    <div v-if="role" class="space-y-4">
      <div class="flex items-center space-x-3 p-4 bg-surface-50 rounded-lg">
        <div 
          class="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold"
          :class="getRoleColorClass(role.name)"
        >
          {{ role.display_name.charAt(0) }}
        </div>
        <div>
          <h3 class="font-semibold text-lg">{{ role.display_name }}</h3>
          <p class="text-sm text-surface-500">{{ role.name }}</p>
        </div>
        <Tag 
          v-if="role.system_role"
          value="系统角色"
          severity="info"
          size="small"
        />
      </div>

      <!-- 权限配置 -->
      <div>
        <div class="flex justify-between items-center mb-4">
          <label class="text-sm font-medium text-surface-700">权限配置</label>
          <div class="space-x-2">
            <Button 
              label="全选" 
              @click="selectAllPermissions"
              size="small"
              text
            />
            <Button 
              label="清空" 
              @click="clearAllPermissions"
              size="small"
              text
            />
          </div>
        </div>
        
        <div class="border border-surface-200 rounded-lg p-4 max-h-96 overflow-y-auto">
          <div class="space-y-4">
            <div v-for="(group, groupName) in permissionGroups" :key="groupName">
              <div class="flex items-center justify-between mb-3">
                <div class="font-medium text-surface-700">{{ groupName }}</div>
                <div class="text-sm text-surface-500">
                  {{ getGroupSelectedCount(group) }} / {{ group.length }}
                </div>
              </div>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-2 ml-4">
                <div 
                  v-for="permission in group" 
                  :key="permission.key"
                  class="flex items-center space-x-2"
                >
                  <Checkbox 
                    :id="`edit-permission-${permission.key}`"
                    v-model="selectedPermissions" 
                    :value="permission.key"
                    binary
                  />
                  <label :for="`edit-permission-${permission.key}`" class="text-sm cursor-pointer flex-1">
                    {{ permission.label }}
                  </label>
                  <small v-if="permission.description" class="text-xs text-surface-400">
                    {{ permission.description }}
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 统计信息 -->
      <div class="bg-surface-50 p-4 rounded-lg">
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <div class="text-lg font-bold text-primary-600">{{ selectedPermissions.length }}</div>
            <div class="text-sm text-surface-500">已选择权限</div>
          </div>
          <div>
            <div class="text-lg font-bold text-secondary-600">{{ totalPermissions }}</div>
            <div class="text-sm text-surface-500">总权限数</div>
          </div>
          <div>
            <div class="text-lg font-bold text-green-600">{{ coverage }}%</div>
            <div class="text-sm text-surface-500">权限覆盖率</div>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end space-x-2">
        <Button 
          label="取消" 
          @click="visible = false"
          text
        />
        <Button 
          label="保存" 
          @click="handleUpdatePermissions"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import RoleApi, { type Role } from '@/api/role-api'

import Dialog from 'primevue/dialog'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'
import Tag from 'primevue/tag'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  role: Role | null
}>()

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const selectedPermissions = ref<string[]>([])

// 权限分组
const permissionGroups = {
  '用户管理': [
    { key: 'manage_users', label: '管理用户', description: '创建、编辑、删除用户' },
    { key: 'manage_roles', label: '管理角色', description: '创建、编辑、删除角色' }
  ],
  '任务管理': [
    { key: 'view_tasks', label: '查看任务', description: '查看任务列表和详情' },
    { key: 'create_tasks', label: '创建任务', description: '创建新任务' },
    { key: 'edit_tasks', label: '编辑任务', description: '修改任务配置' },
    { key: 'delete_tasks', label: '删除任务', description: '删除任务' },
    { key: 'manage_tasks', label: '完全管理任务', description: '包含所有任务相关权限' }
  ],
  '流程管理': [
    { key: 'view_flows', label: '查看流程', description: '查看流程列表和详情' },
    { key: 'create_flows', label: '创建流程', description: '创建新流程' },
    { key: 'edit_flows', label: '编辑流程', description: '修改流程配置' },
    { key: 'delete_flows', label: '删除流程', description: '删除流程' },
    { key: 'manage_flows', label: '完全管理流程', description: '包含所有流程相关权限' }
  ],
  '执行管理': [
    { key: 'view_executions', label: '查看执行记录', description: '查看任务执行历史' },
    { key: 'manage_executions', label: '管理执行', description: '控制任务执行' }
  ],
  '系统管理': [
    { key: 'view_resque_monitor', label: '查看队列监控', description: '监控任务队列状态' },
    { key: 'manage_system', label: '系统管理', description: '系统级别的管理权限' }
  ]
}

// Computed
const totalPermissions = computed(() => {
  return Object.values(permissionGroups).reduce((sum, group) => sum + group.length, 0)
})

const coverage = computed(() => {
  return totalPermissions.value > 0 ? Math.round((selectedPermissions.value.length / totalPermissions.value) * 100) : 0
})

// Methods
const getRoleColorClass = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'bg-red-500'
    case 'developer': return 'bg-blue-500'
    case 'operator': return 'bg-orange-500'
    case 'viewer': return 'bg-gray-500'
    default: return 'bg-primary-500'
  }
}

const getGroupSelectedCount = (group: any[]) => {
  return group.filter(permission => selectedPermissions.value.includes(permission.key)).length
}

const selectAllPermissions = () => {
  selectedPermissions.value = Object.values(permissionGroups)
    .flat()
    .map(permission => permission.key)
}

const clearAllPermissions = () => {
  selectedPermissions.value = []
}

const handleUpdatePermissions = async () => {
  if (!props.role) return
  
  loading.value = true
  
  try {
    const response = await RoleApi.updatePermissions(props.role.id, {
      permissions: selectedPermissions.value
    })
    
    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '权限更新成功',
        detail: response.data.message,
        life: 3000
      })
      
      visible.value = false
      emit('success')
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '权限更新失败',
      detail: error.message || '更新角色权限失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Watch
watch(() => props.role, (newRole) => {
  if (newRole) {
    selectedPermissions.value = [...newRole.permissions]
  }
}, { immediate: true })
</script>