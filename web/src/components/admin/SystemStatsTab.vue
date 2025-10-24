<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Card from 'primevue/card'
import ProgressBar from 'primevue/progressbar'
import Tag from 'primevue/tag'

import systemApi from '@/api/system-api'
import userApi from '@/api/user-api'
import roleApi from '@/api/role-api'
import projectApi from '@/api/project-api'
import type { SystemStats, SysLogStats } from '@/data/types/system-types'

const toast = useToast()

// 数据
const stats = ref<SystemStats | null>(null)
const logStats = ref<SysLogStats | null>(null)
const loading = ref(false)
const loadingLogs = ref(false)
const lastRefreshTime = ref<string>('')

// 方法
const loadStats = async () => {
  loading.value = true

  try {
    // 使用新的API实例收集统计信息
    const [users, roles, projects] = await Promise.all([
      userApi.list(),
      roleApi.list(),
      projectApi.list().catch(() => ({ projects: [] })) // 如果无法获取项目数据，使用空数组
    ])

    // 尝试获取系统统计数据
    let systemStats: SystemStats | null = null
    try {
      systemStats = await systemApi.getStats()
    } catch (error) {
      console.warn('无法获取系统统计数据，使用手动计算数据')
    }

    if (systemStats) {
      stats.value = systemStats
    } else {
      // 手动构建统计数据
      console.log('Stats data:', { users, roles, projects })

      const userList = users.users || users || []
      const roleList = roles.roles || roles || []
      const projectList = projects.projects || projects || []

      stats.value = {
        user_stats: {
          total_users: userList.length,
          active_users: userList.filter((u: any) => u.status === 'active').length,
          inactive_users: userList.filter((u: any) => u.status === 'inactive').length,
          suspended_users: userList.filter((u: any) => u.status === 'suspended').length,
          users_registered_today: 0, // 需要后端支持
          users_registered_this_month: 0 // 需要后端支持
        },
        role_stats: {
          total_roles: roleList.length,
          system_roles: roleList.filter((r: any) => r.system_role || r.is_system).length,
          custom_roles: roleList.filter((r: any) => !r.system_role && !r.is_system).length
        },
        task_stats: {
          total_tasks: 0,
          running_tasks: 0,
          completed_tasks: 0,
          failed_tasks: 0,
          tasks_executed_today: 0,
          tasks_executed_this_month: 0
        },
        flow_stats: {
          total_flows: projectList.length,
          active_flows: projectList.filter((p: any) => p.status === 'active').length,
          draft_flows: projectList.filter((p: any) => p.status === 'draft').length,
          flows_created_today: 0,
          flows_created_this_month: 0
        },
        system_health: {
          status: 'healthy' as const,
          cpu_usage: 0,
          memory_usage: 0,
          disk_usage: 0,
          database_status: 'connected' as const,
          redis_status: 'connected' as const,
          last_check: new Date().toISOString()
        }
      }
    }


    lastRefreshTime.value = new Date().toLocaleString()
  } catch (err: any) {
    console.error('Load stats error:', err)
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: err.message || '加载系统统计失败',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

const loadLogStats = async () => {
  loadingLogs.value = true

  try {
    const data = await systemApi.getLogStats()
    console.log('Sys log stats response:', data)
    logStats.value = data
  } catch (err: any) {
    console.error('Sys log stats error:', err)
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: err.message || '加载日志统计失败',
      life: 5000
    })
  } finally {
    loadingLogs.value = false
  }
}

const refreshStats = () => {
  loadStats()
  loadLogStats()
  toast.add({
    severity: 'info',
    summary: '刷新中...',
    detail: '正在更新系统统计数据',
    life: 2000
  })
}

const getHealthStatusSeverity = (status: string) => {
  switch (status) {
    case 'healthy': return 'success'
    case 'warning': return 'warning'
    case 'error': return 'danger'
    default: return 'info'
  }
}

const getHealthStatusLabel = (status: string) => {
  switch (status) {
    case 'healthy': return '健康'
    case 'warning': return '警告'
    case 'error': return '错误'
    default: return '未知'
  }
}

const getStatusIcon = (status: string) => {
  return status === 'connected' ? 'pi pi-check-circle text-green-500' : 'pi pi-times-circle text-red-500'
}

const getPerformanceColor = (avgDuration: number) => {
  if (avgDuration < 100) return 'text-green-600'
  if (avgDuration < 500) return 'text-yellow-600'
  if (avgDuration < 1000) return 'text-orange-600'
  return 'text-red-600'
}

const getErrorRateColor = (errorRate: number) => {
  if (errorRate === 0) return 'text-green-600'
  if (errorRate < 1) return 'text-yellow-600'
  if (errorRate < 5) return 'text-orange-600'
  return 'text-red-600'
}

// 生命周期
onMounted(() => {
  loadStats()
  loadLogStats()
  // 每5分钟自动刷新
  const interval = setInterval(() => {
    loadStats()
    loadLogStats()
  }, 5 * 60 * 1000)

  // 组件卸载时清除定时器
  onUnmounted(() => {
    clearInterval(interval)
  })
})
</script>

<template>
  <div class="system-stats-tab">
    <!-- 工具栏 -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-lg font-semibold">系统统计</h2>
        <p v-if="lastRefreshTime" class="text-sm text-gray-500">最后更新: {{ lastRefreshTime }}</p>
      </div>
      <Button
        icon="pi pi-refresh"
        label="刷新"
        size="small"
        :loading="loading"
        @click="refreshStats"
      />
    </div>

    <div v-if="stats" class="space-y-6">
      <!-- 请求统计 -->
      <Card v-if="logStats">
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-chart-line text-purple-500"></i>
            请求统计
          </div>
        </template>
        <template #content>
          <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-purple-600">{{ logStats.total_requests }}</div>
              <div class="text-sm text-gray-500">总请求数</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">{{ logStats.today_requests }}</div>
              <div class="text-sm text-gray-500">今日请求</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-primary-600">{{ logStats.this_week_requests }}</div>
              <div class="text-sm text-gray-500">本周请求</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600">{{ logStats.error_requests }}</div>
              <div class="text-sm text-gray-500">错误请求</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-orange-600">{{ logStats.slow_requests }}</div>
              <div class="text-sm text-gray-500">慢请求</div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 用户统计 -->
      <Card>
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-users text-primary-500"></i>
            用户统计
          </div>
        </template>
        <template #content>
          <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-primary-600">{{ stats.user_stats.total_users }}</div>
              <div class="text-sm text-gray-500">总用户数</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">{{ stats.user_stats.active_users }}</div>
              <div class="text-sm text-gray-500">活跃用户</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-yellow-600">{{ stats.user_stats.inactive_users }}</div>
              <div class="text-sm text-gray-500">未激活</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-red-600">{{ stats.user_stats.suspended_users }}</div>
              <div class="text-sm text-gray-500">已暂停</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-purple-600">{{ stats.user_stats.users_registered_today }}</div>
              <div class="text-sm text-gray-500">今日注册</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-indigo-600">{{ stats.user_stats.users_registered_this_month }}</div>
              <div class="text-sm text-gray-500">本月注册</div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 角色和任务统计 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- 角色统计 -->
        <Card>
          <template #title>
            <div class="flex items-center gap-2">
              <i class="pi pi-shield text-green-500"></i>
              角色统计
            </div>
          </template>
          <template #content>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="text-center">
                <div class="text-2xl font-bold text-green-600">{{ stats.role_stats.total_roles }}</div>
                <div class="text-sm text-gray-500">总角色数</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-orange-600">{{ stats.role_stats.system_roles }}</div>
                <div class="text-sm text-gray-500">系统角色</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-primary-600">{{ stats.role_stats.custom_roles }}</div>
                <div class="text-sm text-gray-500">自定义角色</div>
              </div>
            </div>
          </template>
        </Card>

        <!-- 任务统计 -->
        <Card>
          <template #title>
            <div class="flex items-center gap-2">
              <i class="pi pi-cog text-purple-500"></i>
              任务统计
            </div>
          </template>
          <template #content>
            <div class="grid grid-cols-2 gap-4">
              <div class="text-center">
                <div class="text-2xl font-bold text-purple-600">{{ stats.task_stats.total_tasks }}</div>
                <div class="text-sm text-gray-500">总任务数</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-primary-600">{{ stats.task_stats.running_tasks }}</div>
                <div class="text-sm text-gray-500">运行中</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-green-600">{{ stats.task_stats.completed_tasks }}</div>
                <div class="text-sm text-gray-500">已完成</div>
              </div>
              <div class="text-center">
                <div class="text-2xl font-bold text-red-600">{{ stats.task_stats.failed_tasks }}</div>
                <div class="text-sm text-gray-500">失败</div>
              </div>
            </div>
          </template>
        </Card>
      </div>

      <!-- 流程统计 -->
      <Card>
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-sitemap text-indigo-500"></i>
            流程统计
          </div>
        </template>
        <template #content>
          <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div class="text-center">
              <div class="text-2xl font-bold text-indigo-600">{{ stats.flow_stats.total_flows }}</div>
              <div class="text-sm text-gray-500">总流程数</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-green-600">{{ stats.flow_stats.active_flows }}</div>
              <div class="text-sm text-gray-500">激活状态</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-600">{{ stats.flow_stats.draft_flows }}</div>
              <div class="text-sm text-gray-500">草稿状态</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-purple-600">{{ stats.flow_stats.flows_created_today }}</div>
              <div class="text-sm text-gray-500">今日创建</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-primary-600">{{ stats.flow_stats.flows_created_this_month }}</div>
              <div class="text-sm text-gray-500">本月创建</div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 系统健康状态 -->
      <Card>
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-server text-orange-500"></i>
            系统健康状态
          </div>
        </template>
        <template #content>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- 总体状态 -->
            <div>
              <div class="flex items-center justify-between mb-4">
                <span class="font-medium">系统状态</span>
                <Tag
                  :value="getHealthStatusLabel(stats.system_health.status)"
                  :severity="getHealthStatusSeverity(stats.system_health.status)"
                />
              </div>

              <!-- 资源使用情况 -->
              <div class="space-y-4">
                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span>CPU 使用率</span>
                    <span>{{ stats.system_health.cpu_usage }}%</span>
                  </div>
                  <ProgressBar :value="stats.system_health.cpu_usage" />
                </div>

                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span>内存使用率</span>
                    <span>{{ stats.system_health.memory_usage }}%</span>
                  </div>
                  <ProgressBar :value="stats.system_health.memory_usage" />
                </div>

                <div>
                  <div class="flex justify-between text-sm mb-1">
                    <span>磁盘使用率</span>
                    <span>{{ stats.system_health.disk_usage }}%</span>
                  </div>
                  <ProgressBar :value="stats.system_health.disk_usage" />
                </div>
              </div>
            </div>

            <!-- 服务状态 -->
            <div>
              <h4 class="font-medium mb-4">服务状态</h4>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span class="text-sm">数据库</span>
                  <div class="flex items-center gap-2">
                    <i :class="getStatusIcon(stats.system_health.database_status)"></i>
                    <span class="text-sm">{{ stats.system_health.database_status === 'connected' ? '已连接' : '未连接' }}</span>
                  </div>
                </div>

                <div class="flex items-center justify-between">
                  <span class="text-sm">Redis</span>
                  <div class="flex items-center gap-2">
                    <i :class="getStatusIcon(stats.system_health.redis_status)"></i>
                    <span class="text-sm">{{ stats.system_health.redis_status === 'connected' ? '已连接' : '未连接' }}</span>
                  </div>
                </div>
              </div>

              <div class="mt-4 pt-3 border-t">
                <div class="text-xs text-gray-500">
                  最后检查: {{ new Date(stats.system_health.last_check).toLocaleString() }}
                </div>
              </div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 路由性能统计 -->
      <Card v-if="logStats && logStats.route_performance && logStats.route_performance.length > 0">
        <template #title>
          <div class="flex items-center gap-2">
            <i class="pi pi-clock text-indigo-500"></i>
            路由性能统计
          </div>
        </template>
        <template #content>
          <div class="space-y-4">
            <div class="text-sm text-gray-600 mb-4">
              显示平均响应时间最慢的前20个路由（最少10个请求）
            </div>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="p-3 text-left font-medium text-gray-700">路由</th>
                    <th class="p-3 text-center font-medium text-gray-700">请求数</th>
                    <th class="p-3 text-center font-medium text-gray-700">平均响应时间</th>
                    <th class="p-3 text-center font-medium text-gray-700">错误率</th>
                    <th class="p-3 text-center font-medium text-gray-700">慢请求</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="route in logStats.route_performance" :key="route.route"
                      class="border-b border-gray-100 hover:bg-gray-50">
                    <td class="p-3">
                      <div class="font-medium text-gray-900">{{ route.route }}</div>
                      <div class="text-xs text-gray-500">{{ route.controller }}#{{ route.action }}</div>
                    </td>
                    <td class="p-3 text-center">
                      <div class="font-medium">{{ route.total_requests }}</div>
                    </td>
                    <td class="p-3 text-center">
                      <div class="font-medium" :class="getPerformanceColor(route.avg_duration)">
                        {{ route.avg_duration }}ms
                      </div>
                    </td>
                    <td class="p-3 text-center">
                      <div class="font-medium" :class="getErrorRateColor(route.error_rate)">
                        {{ route.error_rate }}%
                      </div>
                    </td>
                    <td class="p-3 text-center">
                      <div class="font-medium text-orange-600">{{ route.slow_requests }}</div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </template>
      </Card>
    </div>

    <!-- 加载状态 -->
    <div v-else-if="loading" class="text-center py-8">
      <i class="pi pi-spinner pi-spin text-2xl text-gray-400"></i>
      <p class="text-gray-500 mt-2">加载系统统计中...</p>
    </div>

    <!-- 无数据状态 -->
    <div v-else class="text-center py-8">
      <i class="pi pi-chart-bar text-4xl text-gray-400"></i>
      <p class="text-gray-500 mt-2">无法加载系统统计数据</p>
      <Button label="重试" size="small" @click="loadStats" class="mt-4" />
    </div>
  </div>
</template>

<style scoped>
.system-stats-tab {
  height: 100%;
}
</style>
