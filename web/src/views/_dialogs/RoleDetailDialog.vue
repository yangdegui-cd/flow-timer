<template>
  <Dialog 
    v-model:visible="visible" 
    modal 
    header="角色详情" 
    class="w-full max-w-3xl"
  >
    <div v-if="role" class="space-y-6">
      <!-- 角色基本信息 -->
      <div class="flex items-center space-x-4">
        <div 
          class="w-16 h-16 rounded-full flex items-center justify-center text-white font-bold text-xl"
          :class="getRoleColorClass(role.name)"
        >
          {{ role.display_name.charAt(0) }}
        </div>
        <div class="flex-1">
          <div class="flex items-center space-x-3 mb-2">
            <h3 class="text-2xl font-semibold text-surface-900">{{ role.display_name }}</h3>
            <Tag 
              v-if="role.system_role"
              value="系统角色"
              severity="info"
            />
          </div>
          <p class="text-surface-600">{{ role.name }}</p>
          <p v-if="role.description" class="text-surface-500 mt-2">{{ role.description }}</p>
        </div>
      </div>

      <Divider />

      <!-- 统计信息 -->
      <div>
        <h4 class="font-semibold text-surface-900 mb-3">统计信息</h4>
        <div class="grid grid-cols-3 gap-4">
          <Card class="text-center">
            <template #content>
              <div class="text-2xl font-bold text-primary-600 mb-1">{{ role.user_count }}</div>
              <div class="text-sm text-surface-500">拥有此角色的用户</div>
            </template>
          </Card>
          <Card class="text-center">
            <template #content>
              <div class="text-2xl font-bold text-secondary-600 mb-1">{{ role.permissions.length }}</div>
              <div class="text-sm text-surface-500">权限数量</div>
            </template>
          </Card>
          <Card class="text-center">
            <template #content>
              <div class="text-2xl font-bold text-green-600 mb-1">{{ permissionCoverage }}%</div>
              <div class="text-sm text-surface-500">权限覆盖率</div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 权限详情 -->
      <div>
        <h4 class="font-semibold text-surface-900 mb-3">权限详情</h4>
        <div class="space-y-4">
          <div v-for="(group, groupName) in groupedPermissions" :key="groupName">
            <div class="flex items-center justify-between mb-2">
              <div class="font-medium text-surface-700">{{ groupName }}</div>
              <div class="text-sm text-surface-500">
                {{ group.length }} 个权限
              </div>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
              <Tag 
                v-for="permission in group" 
                :key="permission.key"
                :value="permission.label"
                severity="secondary"
                size="small"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- 拥有此角色的用户（如果有） -->
      <div v-if="role.users && role.users.length > 0">
        <h4 class="font-semibold text-surface-900 mb-3">拥有此角色的用户</h4>
        <div class="max-h-32 overflow-y-auto">
          <div class="space-y-2">
            <div 
              v-for="user in role.users" 
              :key="user.id"
              class="flex items-center space-x-3 p-2 bg-surface-50 rounded-lg"
            >
              <Avatar 
                :label="user.avatar_url ? undefined : user.name.charAt(0)"
                :image="user.avatar_url"
                size="small"
                shape="circle"
                class="bg-primary-100 text-primary-600"
              />
              <div class="flex-1">
                <div class="font-medium">{{ user.name }}</div>
                <div class="text-sm text-surface-500">{{ user.email }}</div>
              </div>
              <Tag 
                :value="getStatusLabel(user.status)"
                :severity="getStatusSeverity(user.status)"
                size="small"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- 角色历史信息 -->
      <div class="bg-surface-50 p-4 rounded-lg">
        <h4 class="font-semibold text-surface-900 mb-3">角色信息</h4>
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-surface-500">创建时间:</span>
            <div class="font-medium">{{ formatDateTime(role.created_at) }}</div>
          </div>
          <div>
            <span class="text-surface-500">最后更新:</span>
            <div class="font-medium">{{ formatDateTime(role.updated_at) }}</div>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end">
        <Button 
          label="关闭" 
          @click="visible = false"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Role } from '@/api/role-api'

import Dialog from 'primevue/dialog'
import Card from 'primevue/card'
import Tag from 'primevue/tag'
import Avatar from 'primevue/avatar'
import Divider from 'primevue/divider'
import Button from 'primevue/button'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  role: Role | null
}>()

// 权限分组定义
const permissionGroups = {
  '用户管理': [
    { key: 'manage_users', label: '管理用户' },
    { key: 'manage_roles', label: '管理角色' }
  ],
  '任务管理': [
    { key: 'view_tasks', label: '查看任务' },
    { key: 'create_tasks', label: '创建任务' },
    { key: 'edit_tasks', label: '编辑任务' },
    { key: 'delete_tasks', label: '删除任务' },
    { key: 'manage_tasks', label: '完全管理任务' }
  ],
  '流程管理': [
    { key: 'view_flows', label: '查看流程' },
    { key: 'create_flows', label: '创建流程' },
    { key: 'edit_flows', label: '编辑流程' },
    { key: 'delete_flows', label: '删除流程' },
    { key: 'manage_flows', label: '完全管理流程' }
  ],
  '执行管理': [
    { key: 'view_executions', label: '查看执行记录' },
    { key: 'manage_executions', label: '管理执行' }
  ],
  '系统管理': [
    { key: 'view_resque_monitor', label: '查看队列监控' },
    { key: 'manage_system', label: '系统管理' }
  ]
}

// Computed
const groupedPermissions = computed(() => {
  if (!props.role) return {}
  
  const grouped: Record<string, any[]> = {}
  
  Object.entries(permissionGroups).forEach(([groupName, permissions]) => {
    const rolePermissions = permissions.filter(p => 
      props.role!.permissions.includes(p.key)
    )
    if (rolePermissions.length > 0) {
      grouped[groupName] = rolePermissions
    }
  })
  
  return grouped
})

const permissionCoverage = computed(() => {
  if (!props.role) return 0
  const totalPermissions = Object.values(permissionGroups).flat().length
  return Math.round((props.role.permissions.length / totalPermissions) * 100)
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

const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'active': return 'success'
    case 'inactive': return 'warning'
    case 'suspended': return 'danger'
    default: return 'secondary'
  }
}

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'active': return '活跃'
    case 'inactive': return '非活跃'
    case 'suspended': return '已禁用'
    default: return status
  }
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}
</script>