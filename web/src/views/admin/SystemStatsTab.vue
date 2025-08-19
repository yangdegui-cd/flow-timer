<template>
  <div class="system-stats-tab">
    <div class="space-y-6">
      <!-- 概览统计 -->
      <div>
        <h3 class="text-lg font-semibold text-surface-900 mb-4">系统概览</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card class="stat-card">
            <template #content>
              <div class="flex items-center space-x-4">
                <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                  <i class="pi pi-users text-blue-600 text-xl"></i>
                </div>
                <div>
                  <div class="text-2xl font-bold text-surface-900">{{ stats.total_users }}</div>
                  <div class="text-sm text-surface-500">总用户数</div>
                </div>
              </div>
            </template>
          </Card>

          <Card class="stat-card">
            <template #content>
              <div class="flex items-center space-x-4">
                <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                  <i class="pi pi-user-plus text-green-600 text-xl"></i>
                </div>
                <div>
                  <div class="text-2xl font-bold text-surface-900">{{ stats.active_users }}</div>
                  <div class="text-sm text-surface-500">活跃用户</div>
                </div>
              </div>
            </template>
          </Card>

          <Card class="stat-card">
            <template #content>
              <div class="flex items-center space-x-4">
                <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                  <i class="pi pi-shield text-purple-600 text-xl"></i>
                </div>
                <div>
                  <div class="text-2xl font-bold text-surface-900">{{ stats.total_roles }}</div>
                  <div class="text-sm text-surface-500">系统角色</div>
                </div>
              </div>
            </template>
          </Card>

          <Card class="stat-card">
            <template #content>
              <div class="flex items-center space-x-4">
                <div class="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
                  <i class="pi pi-clock text-orange-600 text-xl"></i>
                </div>
                <div>
                  <div class="text-2xl font-bold text-surface-900">{{ stats.recent_logins }}</div>
                  <div class="text-sm text-surface-500">24小时登录</div>
                </div>
              </div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 用户状态分布 -->
      <div>
        <h3 class="text-lg font-semibold text-surface-900 mb-4">用户状态分布</h3>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <template #content>
              <div class="space-y-4">
                <div class="flex justify-between items-center">
                  <span class="text-sm font-medium">活跃用户</span>
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span class="text-sm">{{ stats.active_users }}</span>
                  </div>
                </div>
                <ProgressBar 
                  :value="(stats.active_users / stats.total_users) * 100" 
                  class="h-2"
                  :show-value="false"
                />

                <div class="flex justify-between items-center">
                  <span class="text-sm font-medium">非活跃用户</span>
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                    <span class="text-sm">{{ stats.inactive_users }}</span>
                  </div>
                </div>
                <ProgressBar 
                  :value="(stats.inactive_users / stats.total_users) * 100" 
                  class="h-2"
                  :show-value="false"
                  severity="warning"
                />

                <div class="flex justify-between items-center">
                  <span class="text-sm font-medium">已禁用用户</span>
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-3 bg-red-500 rounded-full"></div>
                    <span class="text-sm">{{ stats.suspended_users }}</span>
                  </div>
                </div>
                <ProgressBar 
                  :value="(stats.suspended_users / stats.total_users) * 100" 
                  class="h-2"
                  :show-value="false"
                  severity="danger"
                />
              </div>
            </template>
          </Card>

          <Card>
            <template #content>
              <div class="space-y-4">
                <h4 class="font-medium text-surface-900">角色分布</h4>
                <div class="space-y-3">
                  <div 
                    v-for="role in stats.role_distribution" 
                    :key="role.name"
                    class="flex justify-between items-center"
                  >
                    <div class="flex items-center space-x-2">
                      <div 
                        class="w-3 h-3 rounded-full"
                        :class="getRoleColorClass(role.name)"
                      ></div>
                      <span class="text-sm font-medium">{{ role.display_name }}</span>
                    </div>
                    <span class="text-sm">{{ role.user_count }} 用户</span>
                  </div>
                </div>
              </div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 最近活动 -->
      <div>
        <h3 class="text-lg font-semibold text-surface-900 mb-4">最近活动</h3>
        <Card>
          <template #content>
            <div class="space-y-4">
              <div 
                v-for="activity in recentActivities" 
                :key="activity.id"
                class="flex items-center space-x-4 p-3 border border-surface-200 rounded-lg"
              >
                <div 
                  class="w-10 h-10 rounded-full flex items-center justify-center"
                  :class="getActivityColorClass(activity.type)"
                >
                  <i :class="getActivityIcon(activity.type)" class="text-sm"></i>
                </div>
                <div class="flex-1">
                  <div class="font-medium text-surface-900">{{ activity.title }}</div>
                  <div class="text-sm text-surface-500">{{ activity.description }}</div>
                </div>
                <div class="text-sm text-surface-400">
                  {{ formatDateTime(activity.created_at) }}
                </div>
              </div>
              
              <div v-if="recentActivities.length === 0" class="text-center py-8 text-surface-500">
                暂无最近活动记录
              </div>
            </div>
          </template>
        </Card>
      </div>
    </div>

    <!-- 刷新按钮 -->
    <div class="mt-6 flex justify-end">
      <Button 
        @click="refreshStats"
        icon="pi pi-refresh"
        label="刷新数据"
        :loading="loading"
        size="small"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'

import Card from 'primevue/card'
import Button from 'primevue/button'
import ProgressBar from 'primevue/progressbar'

// Services
const toast = useToast()

// Data
const loading = ref(false)

const stats = reactive({
  total_users: 0,
  active_users: 0,
  inactive_users: 0,
  suspended_users: 0,
  total_roles: 0,
  recent_logins: 0,
  role_distribution: [] as Array<{
    name: string
    display_name: string
    user_count: number
  }>
})

const recentActivities = ref<Array<{
  id: string
  type: string
  title: string
  description: string
  created_at: string
}>>([])

// Methods
const refreshStats = async () => {
  loading.value = true
  
  try {
    // 模拟API调用 - 在实际项目中应该调用真实的API
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // 模拟数据
    Object.assign(stats, {
      total_users: 15,
      active_users: 12,
      inactive_users: 2,
      suspended_users: 1,
      total_roles: 4,
      recent_logins: 8,
      role_distribution: [
        { name: 'admin', display_name: '系统管理员', user_count: 2 },
        { name: 'developer', display_name: '开发者', user_count: 6 },
        { name: 'operator', display_name: '操作员', user_count: 4 },
        { name: 'viewer', display_name: '查看者', user_count: 3 }
      ]
    })
    
    recentActivities.value = [
      {
        id: '1',
        type: 'user_created',
        title: '新用户注册',
        description: '用户 "张三" 注册了新账号',
        created_at: new Date(Date.now() - 1000 * 60 * 30).toISOString()
      },
      {
        id: '2',
        type: 'role_updated',
        title: '角色权限更新',
        description: '角色 "开发者" 的权限配置已更新',
        created_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString()
      },
      {
        id: '3',
        type: 'user_login',
        title: '用户登录',
        description: '管理员 "admin" 登录了系统',
        created_at: new Date(Date.now() - 1000 * 60 * 60 * 4).toISOString()
      },
      {
        id: '4',
        type: 'user_disabled',
        title: '用户状态变更',
        description: '用户 "李四" 账号已被禁用',
        created_at: new Date(Date.now() - 1000 * 60 * 60 * 8).toISOString()
      }
    ]
    
    toast.add({
      severity: 'success',
      summary: '数据已刷新',
      detail: '系统统计数据已更新',
      life: 3000
    })
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '刷新失败',
      detail: error.message || '获取统计数据失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Helpers
const getRoleColorClass = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'bg-red-500'
    case 'developer': return 'bg-blue-500'
    case 'operator': return 'bg-orange-500'
    case 'viewer': return 'bg-gray-500'
    default: return 'bg-primary-500'
  }
}

const getActivityColorClass = (type: string) => {
  switch (type) {
    case 'user_created': return 'bg-green-100 text-green-600'
    case 'user_login': return 'bg-blue-100 text-blue-600'
    case 'user_disabled': return 'bg-red-100 text-red-600'
    case 'role_updated': return 'bg-purple-100 text-purple-600'
    default: return 'bg-surface-100 text-surface-600'
  }
}

const getActivityIcon = (type: string) => {
  switch (type) {
    case 'user_created': return 'pi pi-user-plus'
    case 'user_login': return 'pi pi-sign-in'
    case 'user_disabled': return 'pi pi-lock'
    case 'role_updated': return 'pi pi-shield'
    default: return 'pi pi-info-circle'
  }
}

const formatDateTime = (dateString: string) => {
  const now = new Date()
  const date = new Date(dateString)
  const diff = now.getTime() - date.getTime()
  
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 60) {
    return `${minutes} 分钟前`
  } else if (hours < 24) {
    return `${hours} 小时前`
  } else {
    return `${days} 天前`
  }
}

// Lifecycle
onMounted(() => {
  refreshStats()
})
</script>

<style scoped>
.system-stats-tab {
  max-width: 100%;
}

.stat-card {
  transition: transform 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
}
</style>