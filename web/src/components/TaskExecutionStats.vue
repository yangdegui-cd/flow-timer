<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { ApiGetTaskExecutionStats, type TaskExecutionStats } from '@/api/task-execution-api'
import { useToast } from 'primevue/usetoast'

const toast = useToast()

// 数据
const stats = ref<TaskExecutionStats | null>(null)
const loading = ref(false)

// 刷新间隔
let refreshInterval: NodeJS.Timeout | null = null

// 状态颜色映射
const statusColors = {
  pending: '#3b82f6',    // blue
  running: '#f59e0b',    // yellow
  completed: '#10b981',  // green
  failed: '#ef4444',     // red
  cancelled: '#6b7280'   // gray
}

// 状态标签映射
const statusLabels = {
  pending: '待执行',
  running: '执行中',
  completed: '已完成',
  failed: '失败',
  cancelled: '已取消'
}

// 加载统计数据
const loadStats = async () => {
  loading.value = true
  try {
    stats.value = await ApiGetTaskExecutionStats()
  } catch (error: any) {
    console.error('Failed to load stats:', error)
    toast.add({ 
      severity: 'error', 
      summary: '加载统计失败', 
      detail: error.msg || '网络错误', 
      life: 3000 
    })
  } finally {
    loading.value = false
  }
}

// 格式化时长
const formatDuration = (seconds?: number) => {
  if (!seconds) return '-'
  
  if (seconds < 60) {
    return `${Math.round(seconds)}秒`
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.round(seconds % 60)
    return `${minutes}分${remainingSeconds}秒`
  } else {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    return `${hours}时${minutes}分`
  }
}

// 计算成功率
const getSuccessRate = () => {
  if (!stats.value || stats.value.total === 0) return 0
  const completed = stats.value.by_status.completed || 0
  return Math.round((completed / stats.value.total) * 100)
}

// 启动自动刷新
const startAutoRefresh = () => {
  refreshInterval = setInterval(loadStats, 10000) // 每10秒刷新
}

// 停止自动刷新
const stopAutoRefresh = () => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
    refreshInterval = null
  }
}

// 生命周期
onMounted(() => {
  loadStats()
  startAutoRefresh()
})

onUnmounted(() => {
  stopAutoRefresh()
})
</script>

<template>
  <div class="task-execution-stats">
    <!-- 加载状态 -->
    <div v-if="loading && !stats" class="flex justify-center items-center py-8">
      <ProgressSpinner size="50px" strokeWidth="4" />
    </div>

    <!-- 统计内容 -->
    <div v-else-if="stats" class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-4 gap-4">
      <!-- 总体统计卡片 -->
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">总执行次数</p>
            <p class="text-2xl font-bold text-gray-900">{{ stats.total.toLocaleString() }}</p>
          </div>
          <div class="p-3 bg-blue-50 rounded-full">
            <i class="pi pi-chart-bar text-xl text-blue-600"></i>
          </div>
        </div>
        <div class="mt-4">
          <p class="text-xs text-gray-500">最近24小时: {{ stats.recent_24h }}</p>
        </div>
      </div>

      <!-- 成功率卡片 -->
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">成功率</p>
            <p class="text-2xl font-bold text-green-600">{{ getSuccessRate() }}%</p>
          </div>
          <div class="p-3 bg-green-50 rounded-full">
            <i class="pi pi-check-circle text-xl text-green-600"></i>
          </div>
        </div>
        <div class="mt-4">
          <p class="text-xs text-gray-500">
            成功: {{ stats.by_status.completed || 0 }} / 总计: {{ stats.total }}
          </p>
        </div>
      </div>

      <!-- 平均执行时长卡片 -->
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">平均执行时长</p>
            <p class="text-2xl font-bold text-purple-600">
              {{ formatDuration(stats.average_duration_seconds) }}
            </p>
          </div>
          <div class="p-3 bg-purple-50 rounded-full">
            <i class="pi pi-clock text-xl text-purple-600"></i>
          </div>
        </div>
      </div>

      <!-- 队列状态卡片 -->
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Worker状态</p>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-lg font-bold text-gray-900">{{ stats.queue_info.workers }}</span>
              <span class="text-sm text-gray-500">个Worker</span>
            </div>
          </div>
          <div class="p-3 bg-orange-50 rounded-full">
            <i class="pi pi-cog text-xl text-orange-600"></i>
          </div>
        </div>
        <div class="mt-4 space-y-1">
          <p class="text-xs text-gray-500">
            工作中: {{ stats.queue_info.working }}
          </p>
          <p class="text-xs text-gray-500">
            失败任务: {{ stats.queue_info.failed }}
          </p>
        </div>
      </div>
    </div>

    <!-- 状态分布图表 -->
    <div v-if="stats && stats.total > 0" class="mt-6">
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900">状态分布</h3>
          <Button 
            icon="pi pi-refresh" 
            text 
            size="small"
            severity="secondary"
            @click="loadStats"
            :loading="loading" />
        </div>

        <!-- 状态统计列表 -->
        <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
          <div 
            v-for="(count, status) in stats.by_status" 
            :key="status"
            class="text-center p-4 rounded-lg border border-surface">
            <div 
              class="w-12 h-12 rounded-full mx-auto mb-2 flex items-center justify-center"
              :style="{ backgroundColor: `${statusColors[status as keyof typeof statusColors]}20` }">
              <div 
                class="w-6 h-6 rounded-full"
                :style="{ backgroundColor: statusColors[status as keyof typeof statusColors] }">
              </div>
            </div>
            <div class="text-2xl font-bold text-gray-900">{{ count }}</div>
            <div class="text-sm text-gray-500">{{ statusLabels[status as keyof typeof statusLabels] }}</div>
            <div class="text-xs text-gray-400 mt-1">
              {{ Math.round((count / stats.total) * 100) }}%
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 队列信息 -->
    <div v-if="stats?.queue_info?.queues?.length" class="mt-6">
      <div class="bg-white rounded-lg shadow p-6 border border-surface">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">队列状态</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div 
            v-for="queue in stats.queue_info.queues" 
            :key="queue.name"
            class="flex items-center justify-between p-3 border border-surface rounded-lg">
            <div>
              <div class="font-medium text-gray-900">{{ queue.name }}</div>
              <div class="text-sm text-gray-500">队列</div>
            </div>
            <div class="text-right">
              <div class="text-lg font-bold text-gray-900">{{ queue.size }}</div>
              <div class="text-xs text-gray-500">待处理</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="!loading" class="text-center py-8">
      <i class="pi pi-exclamation-triangle text-4xl text-gray-400 mb-4 block"></i>
      <p class="text-gray-500">暂无统计数据</p>
      <Button 
        label="重新加载" 
        icon="pi pi-refresh" 
        severity="secondary" 
        variant="outlined"
        size="small"
        class="mt-4"
        @click="loadStats" />
    </div>
  </div>
</template>

<style scoped lang="scss">
.task-execution-stats {
  .p-progressspinner {
    width: 50px;
    height: 50px;
  }
}
</style>