<template>
  <Dialog 
    v-model:visible="visible" 
    modal 
    header="用户详情" 
    class="w-full max-w-2xl"
  >
    <div v-if="user" class="space-y-6">
      <!-- 基本信息 -->
      <div class="flex items-center space-x-4">
        <Avatar 
          :label="user.avatar_url ? undefined : user.name.charAt(0)"
          :image="user.avatar_url"
          shape="circle"
          size="xlarge"
          class="bg-primary-100 text-primary-600"
        />
        <div>
          <h3 class="text-xl font-semibold text-surface-900">{{ user.name }}</h3>
          <p class="text-surface-600">{{ user.email }}</p>
          <Tag 
            :value="getStatusLabel(user.status)"
            :severity="getStatusSeverity(user.status)"
            class="mt-2"
          />
        </div>
      </div>

      <Divider />

      <!-- 角色信息 -->
      <div>
        <h4 class="font-semibold text-surface-900 mb-3">角色</h4>
        <div class="flex flex-wrap gap-2">
          <Tag 
            v-for="role in user.roles" 
            :key="role.name"
            :value="role.display_name"
            :severity="getRoleSeverity(role.name)"
          />
        </div>
      </div>

      <!-- 权限信息 -->
      <div>
        <h4 class="font-semibold text-surface-900 mb-3">权限</h4>
        <div class="grid grid-cols-2 gap-2">
          <Tag 
            v-for="permission in user.permissions" 
            :key="permission"
            :value="getPermissionLabel(permission)"
            size="small"
            severity="secondary"
          />
        </div>
      </div>

      <!-- OAuth账号 -->
      <div v-if="user.oauth_providers.length > 0">
        <h4 class="font-semibold text-surface-900 mb-3">关联账号</h4>
        <div class="space-y-2">
          <div 
            v-for="oauth in user.oauth_providers" 
            :key="oauth.provider"
            class="flex items-center space-x-3 p-3 bg-surface-50 rounded-lg"
          >
            <i :class="getOAuthIcon(oauth.provider)" class="text-lg"></i>
            <div>
              <div class="font-medium">{{ oauth.provider_name }}</div>
              <div class="text-sm text-surface-500">
                连接时间: {{ formatDateTime(oauth.connected_at) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 登录信息 -->
      <div>
        <h4 class="font-semibold text-surface-900 mb-3">登录信息</h4>
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-surface-500">最后登录:</span>
            <div v-if="user.last_login_at" class="font-medium">
              {{ formatDateTime(user.last_login_at) }}
            </div>
            <div v-else class="text-surface-400">从未登录</div>
          </div>
          <div>
            <span class="text-surface-500">注册时间:</span>
            <div class="font-medium">{{ formatDateTime(user.created_at) }}</div>
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
import type { User } from '@/api/auth-api'

import Dialog from 'primevue/dialog'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import Divider from 'primevue/divider'
import Button from 'primevue/button'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
defineProps<{
  user: User | null
}>()

// Helpers
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

const getRoleSeverity = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'danger'
    case 'developer': return 'info'
    case 'operator': return 'warning'
    default: return 'secondary'
  }
}

const getPermissionLabel = (permission: string) => {
  const labels: Record<string, string> = {
    'manage_users': '管理用户',
    'manage_roles': '管理角色',
    'manage_tasks': '管理任务',
    'manage_flows': '管理流程',
    'manage_executions': '管理执行',
    'view_resque_monitor': '查看队列监控',
    'manage_system': '系统管理',
    'view_tasks': '查看任务',
    'create_tasks': '创建任务',
    'edit_tasks': '编辑任务',
    'delete_tasks': '删除任务',
    'view_flows': '查看流程',
    'create_flows': '创建流程',
    'edit_flows': '编辑流程',
    'delete_flows': '删除流程',
    'view_executions': '查看执行记录'
  }
  return labels[permission] || permission
}

const getOAuthIcon = (provider: string) => {
  switch (provider) {
    case 'github': return 'pi pi-github'
    case 'wechat': return 'pi pi-comments'
    default: return 'pi pi-link'
  }
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}
</script>