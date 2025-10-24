<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import { actionCableService } from '@/services/actioncable'
import resqueMonitorApi from '@/api/resque-monitor-api'
import type {
  ResqueStats,
  ResqueQueue,
  ResqueWorker,
  ResqueFailedJob,
  ResqueScheduledJobs,
  ResqueDelayedJob
} from '@/data/types/resque-types'
import PageHeader from '@/views/layer/PageHeader.vue'

const toast = useToast()

// 当前激活的tab
const activeTab = ref('overview')

// 数据状态
const loading = ref(false)
const stats = ref<ResqueStats | null>(null)
const queues = ref<ResqueQueue[]>([])
const workers = ref<ResqueWorker[]>([])
const failedJobs = ref<ResqueFailedJob[]>([])
const failedJobsTotal = ref(0)
const scheduledJobs = ref<ResqueScheduledJobs | null>(null)
const delayedJobs = ref<ResqueDelayedJob[]>([])
const delayedJobsTotal = ref(0)

// ActionCable连接状态
const lastUpdateTime = ref<Date | null>(null)
const subscription = ref<any>(null)

// 计算属性 - 从全局服务获取连接状态
const connectionState = computed(() => actionCableService.getConnectionState())
const isConnected = computed(() => actionCableService.isConnected())

// 选中的队列详情
const selectedQueue = ref<ResqueQueue | null>(null)
const showQueueDialog = ref(false)

// 选中的失败任务详情
const selectedFailedJob = ref<ResqueFailedJob | null>(null)
const showFailedJobDialog = ref(false)

// tab选项
const tabs = [
  { key: 'overview', label: '总览', icon: 'pi-chart-bar' },
  { key: 'queues', label: '队列', icon: 'pi-list' },
  { key: 'workers', label: 'Workers', icon: 'pi-users' },
  { key: 'failed', label: '失败任务', icon: 'pi-exclamation-triangle' },
  { key: 'scheduled', label: '定时任务', icon: 'pi-calendar' },
  { key: 'delayed', label: '延迟任务', icon: 'pi-clock' }
]

// ActionCable相关函数
const subscribeToResqueMonitor = () => {
  if (subscription.value) {
    return // 已经订阅
  }

  subscription.value = actionCableService.subscribe(
    'ResqueMonitorChannel',
    {},
    {
      connected() {
        console.log('ResqueMonitor频道连接成功')

        toast.add({
          severity: 'success',
          summary: 'Resque监控连接成功',
          detail: '实时监控已启用',
          life: 3000
        })

        // 请求初始数据
        actionCableService.perform('ResqueMonitorChannel', 'subscribe', {
          tabs: ['stats', 'queues', 'workers', 'failed', 'scheduled', 'delayed']
        })
      },

      disconnected() {
        console.log('ResqueMonitor频道连接断开')

        toast.add({
          severity: 'warn',
          summary: 'Resque监控连接断开',
          detail: '实时监控已暂停',
          life: 3000
        })
      },

      rejected() {
        console.log('ResqueMonitor频道连接被拒绝')

        toast.add({
          severity: 'error',
          summary: 'Resque监控连接被拒绝',
          detail: '请检查服务器配置',
          life: 5000
        })

        // 回退到轮询模式
        fallbackToPolling()
      },

      received(data: any) {
        handleActionCableMessage(data)
        lastUpdateTime.value = new Date()
      }
    }
  )
}

// 处理ActionCable消息
const handleActionCableMessage = (data: any) => {
  switch (data.type) {
    case 'stats':
      stats.value = data.payload
      break
    case 'queues':
      queues.value = data.payload
      break
    case 'workers':
      workers.value = data.payload
      break
    case 'failed_jobs':
      failedJobs.value = data.payload.jobs
      failedJobsTotal.value = data.payload.total
      break
    case 'scheduled_jobs':
      scheduledJobs.value = data.payload
      break
    case 'delayed_jobs':
      delayedJobs.value = data.payload.jobs
      delayedJobsTotal.value = data.payload.total
      break
    case 'update':
      // 增量更新
      if (data.payload.stats) stats.value = data.payload.stats
      if (data.payload.queues) queues.value = data.payload.queues
      if (data.payload.workers) workers.value = data.payload.workers
      if (data.payload.failed_jobs) {
        failedJobs.value = data.payload.failed_jobs.jobs
        failedJobsTotal.value = data.payload.failed_jobs.total
      }
      if (data.payload.scheduled_jobs) scheduledJobs.value = data.payload.scheduled_jobs
      if (data.payload.delayed_jobs) {
        delayedJobs.value = data.payload.delayed_jobs.jobs
        delayedJobsTotal.value = data.payload.delayed_jobs.total
      }
      break
    case 'error':
      console.error('ActionCable服务器错误:', data.payload)
      toast.add({
        severity: 'error',
        summary: '服务器错误',
        detail: data.payload.message || '未知错误',
        life: 5000
      })
      break
    default:
      console.log('未知的ActionCable消息类型:', data.type)
  }
}

// 发送ActionCable消息
const sendMessage = (action: string, data: any = {}) => {
  actionCableService.perform('ResqueMonitorChannel', action, data)
}

// 取消订阅
const unsubscribeFromResqueMonitor = () => {
  if (subscription.value) {
    actionCableService.unsubscribe('ResqueMonitorChannel')
    subscription.value = null
  }
}

// 回退到轮询模式
const fallbackToPolling = () => {
  console.log('ActionCable不可用，回退到轮询模式')
  fetchAllData()
}

// 获取统计信息
const fetchStats = async () => {
  try {
    stats.value = await resqueMonitorApi.getStats()
  } catch (error) {
    console.error('获取统计信息失败:', error)
  }
}

// 获取队列信息
const fetchQueues = async () => {
  try {
    queues.value = await resqueMonitorApi.getQueues()
  } catch (error) {
    console.error('获取队列信息失败:', error)
  }
}

// 获取Worker信息
const fetchWorkers = async () => {
  try {
    workers.value = await resqueMonitorApi.getWorkers()
  } catch (error) {
    console.error('获取Worker信息失败:', error)
  }
}

// 获取失败任务
const fetchFailedJobs = async () => {
  try {
    const response = await resqueMonitorApi.getFailedJobs(0, 50)
    failedJobs.value = response.jobs
    failedJobsTotal.value = response.total
  } catch (error) {
    console.error('获取失败任务失败:', error)
  }
}

// 获取定时任务
const fetchScheduledJobs = async () => {
  try {
    scheduledJobs.value = await resqueMonitorApi.getScheduledJobs()
  } catch (error) {
    console.error('获取定时任务失败:', error)
  }
}

// 获取延迟任务
const fetchDelayedJobs = async () => {
  try {
    const response = await resqueMonitorApi.getDelayedJobs(0, 20)
    delayedJobs.value = response.jobs
    delayedJobsTotal.value = response.total
  } catch (error) {
    console.error('获取延迟任务失败:', error)
  }
}

// 获取所有数据
const fetchAllData = async () => {
  loading.value = true
  try {
    await Promise.all([
      fetchStats(),
      fetchQueues(),
      fetchWorkers(),
      fetchFailedJobs(),
      fetchScheduledJobs(),
      fetchDelayedJobs()
    ])
    lastUpdateTime.value = new Date()
  } finally {
    loading.value = false
  }
}

// 重试失败任务
const retryFailedJob = async (job: ResqueFailedJob, index: number) => {
  try {
    await resqueMonitorApi.retryFailedJob(index)
    toast.add({
      severity: 'success',
      summary: '任务重试成功',
      detail: `任务 ${job.payload.class} 已重新加入队列`,
      life: 3000
    })
    await fetchFailedJobs()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '重试失败',
      detail: error.msg || '重试任务时发生错误',
      life: 3000
    })
  }
}

// 清空所有失败任务
const clearAllFailedJobs = async () => {
  try {
    await resqueMonitorApi.clearFailedJobs()
    toast.add({
      severity: 'success',
      summary: '清空成功',
      detail: '所有失败任务已清除',
      life: 3000
    })
    await fetchFailedJobs()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '清空失败',
      detail: error.msg || '清空失败任务时发生错误',
      life: 3000
    })
  }
}

// 重新排队所有失败任务
const requeueAllFailedJobs = async () => {
  try {
    await resqueMonitorApi.requeueAllFailedJobs()
    toast.add({
      severity: 'success',
      summary: '重新排队成功',
      detail: '所有失败任务已重新加入队列',
      life: 3000
    })
    await fetchFailedJobs()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '重新排队失败',
      detail: error.msg || '重新排队失败任务时发生错误',
      life: 3000
    })
  }
}

// 删除单个失败任务
const removeFailedJob = async (job: ResqueFailedJob) => {
  try {
    await resqueMonitorApi.removeFailedJob(job.index)
    toast.add({
      severity: 'success',
      summary: '删除成功',
      detail: `任务 ${job.payload.class} 已删除`,
      life: 3000
    })
    await fetchFailedJobs()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '删除失败',
      detail: error.msg || '删除失败任务时发生错误',
      life: 3000
    })
  }
}

// 清空所有延迟任务
const clearAllDelayedJobs = async () => {
  try {
    await resqueMonitorApi.clearDelayedJobs()
    toast.add({
      severity: 'success',
      summary: '清空成功',
      detail: '所有延迟任务已清除',
      life: 3000
    })
    await fetchDelayedJobs()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '清空失败',
      detail: error.msg || '清空延迟任务时发生错误',
      life: 3000
    })
  }
}

// 清空队列
const clearQueue = async (queueName: string) => {
  try {
    await resqueMonitorApi.clearQueue(queueName)
    toast.add({
      severity: 'success',
      summary: '队列清空成功',
      detail: `队列 ${queueName} 已清空`,
      life: 3000
    })
    await fetchQueues()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '清空失败',
      detail: error.msg || '清空队列时发生错误',
      life: 3000
    })
  }
}

// 删除队列
const removeQueue = async (queueName: string) => {
  try {
    await resqueMonitorApi.removeQueue(queueName)
    toast.add({
      severity: 'success',
      summary: '队列删除成功',
      detail: `队列 ${queueName} 已删除`,
      life: 3000
    })
    await fetchQueues()
    await fetchStats()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '删除失败',
      detail: error.msg || '删除队列时发生错误',
      life: 3000
    })
  }
}

// 查看队列详情
const viewQueueDetails = (queue: ResqueQueue) => {
  selectedQueue.value = queue
  showQueueDialog.value = true
}

// 查看失败任务详情
const viewFailedJobDetails = (job: ResqueFailedJob) => {
  selectedFailedJob.value = job
  showFailedJobDialog.value = true
}

// 格式化JSON显示
const formatJson = (data: any) => {
  if (!data) return '-'
  if (typeof data === 'string') return data
  return JSON.stringify(data, null, 2)
}

// 格式化日期
const formatDate = (date?: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

// 获取Worker状态显示
const getWorkerStatus = (state: string) => {
  switch (state) {
    case 'working':
      return { label: '工作中', severity: 'success' }
    case 'idle':
      return { label: '空闲', severity: 'info' }
    default:
      return { label: state, severity: 'secondary' }
  }
}

// 切换连接模式
const toggleConnection = () => {
  if (isConnected.value && subscription.value) {
    unsubscribeFromResqueMonitor()
    toast.add({
      severity: 'info',
      summary: 'Resque监控已断开',
      detail: '切换到手动刷新模式',
      life: 3000
    })
  } else {
    subscribeToResqueMonitor()
  }
}

// 手动刷新
const manualRefresh = () => {
  if (isConnected.value && subscription.value) {
    sendMessage('refresh')
  } else {
    fetchAllData()
  }
}

// 获取连接状态显示
const getConnectionStatusInfo = () => {
  if (!connectionState.value.connected) {
    if (connectionState.value.connecting) {
      return {
        label: 'ActionCable连接中...',
        icon: 'pi-circle',
        color: 'text-yellow-500 animate-pulse',
        description: '正在建立连接'
      }
    } else if (connectionState.value.error) {
      return {
        label: 'ActionCable连接错误',
        icon: 'pi-circle',
        color: 'text-red-500',
        description: connectionState.value.error
      }
    } else {
      return {
        label: 'ActionCable已断开',
        icon: 'pi-circle',
        color: 'text-gray-500',
        description: '手动刷新模式'
      }
    }
  }

  // ActionCable已连接，检查是否订阅了Resque监控
  if (subscription.value) {
    return {
      label: 'Resque实时监控',
      icon: 'pi-circle',
      color: 'text-green-500',
      description: '实时监控活跃'
    }
  } else {
    return {
      label: 'ActionCable已连接',
      icon: 'pi-circle',
      color: 'text-primary-500',
      description: '未订阅监控频道'
    }
  }
}

// 查看延迟任务详情
const selectedDelayedJob = ref<ResqueDelayedJob | null>(null)
const showDelayedJobDialog = ref(false)

const viewDelayedJobDetails = (job: ResqueDelayedJob) => {
  selectedDelayedJob.value = job
  showDelayedJobDialog.value = true
}

// 删除延迟任务组
const removeDelayedJobGroup = async (delayedJob: ResqueDelayedJob) => {
  try {
    // 这里需要根据实际的API来实现
    toast.add({
      severity: 'info',
      summary: '功能提示',
      detail: '此功能需要根据具体的延迟任务删除API来实现',
      life: 3000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '删除失败',
      detail: error.msg || '删除延迟任务时发生错误',
      life: 3000
    })
  }
}

// 组件挂载时初始化
onMounted(() => {
  // 直接尝试订阅频道，ActionCable会在连接建立后自动连接频道
  subscribeToResqueMonitor()

  // 如果1秒后还没有订阅成功，使用轮询模式获取初始数据
  setTimeout(() => {
    if (!subscription.value || !isConnected.value) {
      console.log('ActionCable连接可能有问题，使用轮询模式获取初始数据')
      fallbackToPolling()
    }
  }, 1000)
})

// 组件卸载时清理
onUnmounted(() => {
  unsubscribeFromResqueMonitor()
})
</script>

<template>
  <div class="h-full flex flex-col bg-gray-50 w-full">
    <!-- 页面头部 -->
    <PageHeader
      title="Resque 监控面板"
      description="实时监控 Resque 队列系统状态和性能指标"
      icon="pi pi-server"
      icon-color="text-primary-600"
    >
      <template #actions>
        <!-- 连接控制 -->
        <div class="flex items-center gap-2">
          <Button
            icon="pi pi-refresh"
            size="small"
            outlined
            @click="manualRefresh"
            :loading="loading"
            v-tooltip="'手动刷新'"/>
          <Button
            :icon="subscription ? 'pi pi-wifi' : 'pi pi-globe'"
            size="small"
            :severity="subscription ? 'success' : 'secondary'"
            outlined
            @click="toggleConnection"
            v-tooltip="subscription ? '断开Resque监控' : '启用Resque监控'"/>
        </div>

        <!-- 连接状态指示 -->
        <div class="flex items-center gap-4">
          <!-- WebSocket状态 -->
          <div class="flex items-center gap-2">
            <i :class="`pi ${getConnectionStatusInfo().icon} ${getConnectionStatusInfo().color} text-sm`"></i>
            <div class="text-sm">
              <div class="text-gray-700 font-medium">{{ getConnectionStatusInfo().label }}</div>
              <div class="text-gray-500 text-xs">{{ getConnectionStatusInfo().description }}</div>
            </div>
          </div>

          <!-- 最后更新时间 -->
          <div v-if="lastUpdateTime" class="text-xs text-gray-500">
            <div>最后更新:</div>
            <div>{{ lastUpdateTime.toLocaleTimeString() }}</div>
          </div>
        </div>
      </template>
    </PageHeader>

    <!-- Tab导航 -->
    <div class="bg-white border-b border-surface px-6">
      <nav class="flex space-x-8">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          @click="activeTab = tab.key"
          :class="[
            'flex items-center gap-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors',
            activeTab === tab.key
              ? 'border-primary-500 text-primary-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          ]">
          <i :class="`pi ${tab.icon}`"></i>
          {{ tab.label }}
        </button>
      </nav>
    </div>

    <!-- Tab内容 -->
    <div class="flex-1 overflow-hidden">
      <!-- 总览页面 -->
      <div v-if="activeTab === 'overview'" class="p-6 h-full overflow-auto">
        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <div v-else-if="stats" class="space-y-6">
          <!-- 核心统计卡片 -->
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
            <Card class="bg-blue-50 border-blue-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-check-circle text-primary-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-primary-700">{{ stats.overview.processed }}</div>
                  <div class="text-sm text-primary-600">已处理</div>
                </div>
              </template>
            </Card>

            <Card class="bg-red-50 border-red-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-times-circle text-red-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-red-700">{{ stats.overview.failed }}</div>
                  <div class="text-sm text-red-600">失败</div>
                </div>
              </template>
            </Card>

            <Card class="bg-yellow-50 border-yellow-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-clock text-yellow-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-yellow-700">{{ stats.overview.pending }}</div>
                  <div class="text-sm text-yellow-600">等待中</div>
                </div>
              </template>
            </Card>

            <Card class="bg-green-50 border-green-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-list text-green-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-green-700">{{ stats.overview.queues }}</div>
                  <div class="text-sm text-green-600">队列数</div>
                </div>
              </template>
            </Card>

            <Card class="bg-purple-50 border-purple-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-users text-purple-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-purple-700">{{ stats.overview.workers }}</div>
                  <div class="text-sm text-purple-600">总 Workers</div>
                </div>
              </template>
            </Card>

            <Card class="bg-indigo-50 border-indigo-200">
              <template #content>
                <div class="text-center">
                  <i class="pi pi-cog text-indigo-600 text-2xl mb-2 block"></i>
                  <div class="text-2xl font-bold text-indigo-700">{{ stats.overview.working }}</div>
                  <div class="text-sm text-indigo-600">工作中</div>
                </div>
              </template>
            </Card>
          </div>

          <!-- Redis 信息 -->
          <Card>
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-database text-red-500"></i>
                Redis 信息
              </div>
            </template>
            <template #content>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <span class="text-gray-600">版本:</span>
                  <span class="ml-2 font-medium">{{ stats.redis_info.redis_version }}</span>
                </div>
                <div>
                  <span class="text-gray-600">已用内存:</span>
                  <span class="ml-2 font-medium">{{ stats.redis_info.used_memory_human }}</span>
                </div>
                <div>
                  <span class="text-gray-600">连接数:</span>
                  <span class="ml-2 font-medium">{{ stats.redis_info.connected_clients }}</span>
                </div>
                <div>
                  <span class="text-gray-600">运行时间:</span>
                  <span class="ml-2 font-medium">{{ Math.floor(stats.redis_info.uptime_in_seconds / 86400) }} 天</span>
                </div>
              </div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 队列页面 -->
      <div v-else-if="activeTab === 'queues'" class="p-6 h-full overflow-auto">
        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <DataTable v-else :value="queues" stripedRows>
          <template #empty>
            <div class="text-center py-8">
              <i class="pi pi-inbox text-4xl text-gray-400 mb-4 block"></i>
              <p class="text-gray-500">暂无队列</p>
            </div>
          </template>

          <Column field="name" header="队列名称">
            <template #body="{ data }">
              <div class="flex items-center gap-2">
                <i class="pi pi-list"></i>
                <strong>{{ data.name }}</strong>
              </div>
            </template>
          </Column>

          <Column field="size" header="任务数量">
            <template #body="{ data }">
              <Tag :value="data.size" :severity="data.size > 0 ? 'info' : 'secondary'" />
            </template>
          </Column>

          <Column header="操作">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button
                  icon="pi pi-eye"
                  size="small"
                  outlined
                  @click="viewQueueDetails(data)"
                  v-tooltip="'查看详情'" />
                <Button
                  icon="pi pi-trash"
                  size="small"
                  outlined
                  severity="warning"
                  @click="clearQueue(data.name)"
                  v-tooltip="'清空队列'"
                  :disabled="data.size === 0" />
                <Button
                  icon="pi pi-times"
                  size="small"
                  outlined
                  severity="danger"
                  @click="removeQueue(data.name)"
                  v-tooltip="'删除队列'" />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- Workers页面 -->
      <div v-else-if="activeTab === 'workers'" class="p-6 h-full overflow-auto">
        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <DataTable v-else :value="workers" stripedRows>
          <template #empty>
            <div class="text-center py-8">
              <i class="pi pi-users text-4xl text-gray-400 mb-4 block"></i>
              <p class="text-gray-500">暂无 Worker</p>
            </div>
          </template>

          <Column field="id" header="Worker ID">
            <template #body="{ data }">
              <code class="text-sm">{{ data.id }}</code>
            </template>
          </Column>

          <Column field="state" header="状态">
            <template #body="{ data }">
              <Tag
                :value="getWorkerStatus(data.state).label"
                :severity="getWorkerStatus(data.state).severity" />
            </template>
          </Column>

          <Column field="processed" header="已处理" />

          <Column field="failed" header="失败数" />

          <Column field="current_job" header="当前任务">
            <template #body="{ data }">
              <div v-if="data.current_job">
                <code class="text-sm">{{ data.current_job.class }}</code>
              </div>
              <span v-else class="text-gray-400">无</span>
            </template>
          </Column>

          <Column field="queues" header="监听队列">
            <template #body="{ data }">
              <div class="flex flex-wrap gap-1">
                <Tag v-for="queue in data.queues" :key="queue" :value="queue" size="small" />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- 失败任务页面 -->
      <div v-else-if="activeTab === 'failed'" class="p-6 h-full overflow-auto">
        <div class="mb-4 flex justify-between items-center">
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-semibold">失败任务</h3>
            <Tag :value="failedJobsTotal" severity="danger" />
          </div>
          <div class="flex gap-2">
            <Button
              label="重新排队所有"
              icon="pi pi-replay"
              severity="warning"
              outlined
              @click="requeueAllFailedJobs"
              :disabled="failedJobsTotal === 0" />
            <Button
              label="清空所有"
              icon="pi pi-trash"
              severity="danger"
              outlined
              @click="clearAllFailedJobs"
              :disabled="failedJobsTotal === 0" />
          </div>
        </div>

        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <DataTable v-else :value="failedJobs" stripedRows>
          <template #empty>
            <div class="text-center py-8">
              <i class="pi pi-check-circle text-4xl text-green-400 mb-4 block"></i>
              <p class="text-green-600">暂无失败任务</p>
            </div>
          </template>

          <Column field="failed_at" header="失败时间">
            <template #body="{ data }">
              <span class="text-sm">{{ formatDate(data.failed_at) }}</span>
            </template>
          </Column>

          <Column field="payload.class" header="任务类">
            <template #body="{ data }">
              <code class="text-sm">{{ data.payload.class }}</code>
            </template>
          </Column>

          <Column field="queue" header="队列" />

          <Column field="exception" header="异常类型">
            <template #body="{ data }">
              <Tag :value="data.exception" severity="danger" />
            </template>
          </Column>

          <Column header="操作">
            <template #body="{ data, index }">
              <div class="flex gap-2">
                <Button
                  icon="pi pi-eye"
                  size="small"
                  outlined
                  @click="viewFailedJobDetails(data)"
                  v-tooltip="'查看详情'" />
                <Button
                  icon="pi pi-replay"
                  size="small"
                  outlined
                  severity="warning"
                  @click="retryFailedJob(data, index)"
                  v-tooltip="'重试'" />
                <Button
                  icon="pi pi-times"
                  size="small"
                  outlined
                  severity="danger"
                  @click="removeFailedJob(data)"
                  v-tooltip="'删除'" />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>

      <!-- 定时任务页面 -->
      <div v-else-if="activeTab === 'scheduled'" class="p-6 h-full overflow-auto">
        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <div v-else-if="scheduledJobs" class="space-y-6">
          <!-- Scheduler 状态 -->
          <Card>
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-calendar text-purple-500"></i>
                Scheduler 状态
              </div>
            </template>
            <template #content>
              <div v-if="scheduledJobs.scheduler_info.supported" class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <span class="text-gray-600">状态:</span>
                  <Tag :value="scheduledJobs.scheduler_info.enabled ? '运行中' : '已停止'"
                       :severity="scheduledJobs.scheduler_info.enabled ? 'success' : 'danger'"
                       class="ml-2" />
                </div>
                <div>
                  <span class="text-gray-600">已启动:</span>
                  <Tag :value="scheduledJobs.scheduler_info.started ? '是' : '否'"
                       :severity="scheduledJobs.scheduler_info.started ? 'success' : 'secondary'"
                       class="ml-2" />
                </div>
                <div>
                  <span class="text-gray-600">延迟任务数:</span>
                  <span class="ml-2 font-medium">{{ scheduledJobs.delayed_jobs_count }}</span>
                </div>
                <div>
                  <span class="text-gray-600">定时任务数:</span>
                  <span class="ml-2 font-medium">{{ Object.keys(scheduledJobs.scheduled_jobs).length }}</span>
                </div>
              </div>
              <div v-else class="text-center py-8">
                <i class="pi pi-info-circle text-4xl text-gray-400 mb-4 block"></i>
                <p class="text-gray-500">resque-scheduler 未安装或未启用</p>
              </div>
            </template>
          </Card>

          <!-- 定时任务列表 -->
          <Card v-if="scheduledJobs.scheduler_info.supported">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-clock text-primary-500"></i>
                定时任务配置
              </div>
            </template>
            <template #content>
              <div v-if="Object.keys(scheduledJobs.scheduled_jobs).length === 0" class="text-center py-8">
                <i class="pi pi-calendar text-4xl text-gray-400 mb-4 block"></i>
                <p class="text-gray-500">暂无定时任务配置</p>
              </div>
              <div v-else class="space-y-4">
                <div v-for="(job, name) in scheduledJobs.scheduled_jobs" :key="name"
                     class="p-4 border border-gray-200 rounded-lg">
                  <div class="flex items-center justify-between mb-2">
                    <h4 class="font-semibold">{{ name }}</h4>
                    <Tag :value="job.class" severity="info" />
                  </div>
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="text-gray-600">Cron:</span>
                      <code class="ml-2">{{ job.cron || job.every || '-' }}</code>
                    </div>
                    <div>
                      <span class="text-gray-600">队列:</span>
                      <span class="ml-2">{{ job.queue || 'default' }}</span>
                    </div>
                    <div v-if="job.description" class="col-span-2">
                      <span class="text-gray-600">描述:</span>
                      <span class="ml-2">{{ job.description }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 延迟任务页面 -->
      <div v-else-if="activeTab === 'delayed'" class="p-6 h-full overflow-auto">
        <div class="mb-4 flex justify-between items-center">
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-semibold">延迟任务</h3>
            <Tag :value="delayedJobsTotal" severity="info" />
          </div>
          <Button
            label="清空所有"
            icon="pi pi-trash"
            severity="danger"
            outlined
            @click="clearAllDelayedJobs"
            :disabled="delayedJobsTotal === 0" />
        </div>

        <div v-if="loading" class="flex items-center justify-center h-full">
          <ProgressSpinner />
        </div>
        <div v-else-if="scheduledJobs && !scheduledJobs.scheduler_info.supported" class="text-center py-8">
          <i class="pi pi-info-circle text-4xl text-gray-400 mb-4 block"></i>
          <p class="text-gray-500">resque-scheduler 未安装或未启用</p>
        </div>
        <DataTable v-else :value="delayedJobs" stripedRows>
          <template #empty>
            <div class="text-center py-8">
              <i class="pi pi-check-circle text-4xl text-green-400 mb-4 block"></i>
              <p class="text-green-600">暂无延迟任务</p>
            </div>
          </template>

          <Column field="formatted_time" header="执行时间">
            <template #body="{ data }">
              <span class="text-sm font-mono">{{ data.formatted_time }}</span>
            </template>
          </Column>

          <Column field="jobs" header="任务数量">
            <template #body="{ data }">
              <Tag :value="data.jobs.length" severity="info" />
            </template>
          </Column>

          <Column field="jobs" header="任务详情">
            <template #body="{ data }">
              <div class="space-y-1">
                <div v-for="(job, index) in data.jobs.slice(0, 2)" :key="index" class="text-sm">
                  <code>{{ job.class }}</code>
                  <span class="text-gray-500 ml-2">
                    ({{ job.args ? job.args.length : 0 }} 参数)
                  </span>
                </div>
                <div v-if="data.jobs.length > 2" class="text-xs text-gray-500">
                  ... 还有 {{ data.jobs.length - 2 }} 个任务
                </div>
              </div>
            </template>
          </Column>

          <Column header="操作">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button
                  icon="pi pi-eye"
                  size="small"
                  outlined
                  @click="viewDelayedJobDetails(data)"
                  v-tooltip="'查看详情'" />
                <Button
                  icon="pi pi-times"
                  size="small"
                  outlined
                  severity="danger"
                  @click="removeDelayedJobGroup(data)"
                  v-tooltip="'删除这个时间点的所有任务'" />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- 队列详情对话框 -->
    <Dialog
      v-model:visible="showQueueDialog"
      header="队列详情"
      modal
      :style="{ width: '80vw' }"
      :maximizable="true">

      <div v-if="selectedQueue" class="space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold">{{ selectedQueue.name }}</h3>
          <Tag :value="`${selectedQueue.size} 个任务`" severity="info" />
        </div>

        <DataTable :value="selectedQueue.jobs" stripedRows>
          <template #empty>
            <div class="text-center py-4">
              <p class="text-gray-500">队列为空</p>
            </div>
          </template>

          <Column field="class" header="任务类">
            <template #body="{ data }">
              <code class="text-sm">{{ data.class }}</code>
            </template>
          </Column>

          <Column field="args" header="参数">
            <template #body="{ data }">
              <code class="text-xs">{{ JSON.stringify(data.args).substring(0, 50) }}...</code>
            </template>
          </Column>

          <Column field="created_at" header="创建时间">
            <template #body="{ data }">
              <span class="text-sm">{{ formatDate(data.created_at) }}</span>
            </template>
          </Column>
        </DataTable>
      </div>
    </Dialog>

    <!-- 失败任务详情对话框 -->
    <Dialog
      v-model:visible="showFailedJobDialog"
      header="失败任务详情"
      modal
      :style="{ width: '80vw' }"
      :maximizable="true">

      <div v-if="selectedFailedJob" class="space-y-6">
        <!-- 基本信息 -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">任务类</label>
            <code class="block p-2 bg-gray-100 rounded text-sm">{{ selectedFailedJob.payload.class }}</code>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">队列</label>
            <span class="block p-2 bg-gray-100 rounded text-sm">{{ selectedFailedJob.queue }}</span>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">失败时间</label>
            <span class="block p-2 bg-gray-100 rounded text-sm">{{ formatDate(selectedFailedJob.failed_at) }}</span>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Worker</label>
            <code class="block p-2 bg-gray-100 rounded text-sm">{{ selectedFailedJob.worker }}</code>
          </div>
        </div>

        <!-- 任务参数 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">任务参数</label>
          <pre class="bg-gray-100 rounded p-3 text-sm overflow-auto max-h-48">{{ formatJson(selectedFailedJob.payload.args) }}</pre>
        </div>

        <!-- 错误信息 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">错误信息</label>
          <div class="bg-red-50 border border-red-200 rounded p-3">
            <div class="text-sm text-red-700 mb-2">
              <strong>{{ selectedFailedJob.exception }}:</strong> {{ selectedFailedJob.error }}
            </div>
          </div>
        </div>

        <!-- 堆栈跟踪 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">堆栈跟踪</label>
          <pre class="bg-gray-100 rounded p-3 text-xs overflow-auto max-h-64">{{ selectedFailedJob.backtrace.join('\n') }}</pre>
        </div>
      </div>
    </Dialog>

    <!-- 延迟任务详情对话框 -->
    <Dialog
      v-model:visible="showDelayedJobDialog"
      header="延迟任务详情"
      modal
      :style="{ width: '80vw' }"
      :maximizable="true">

      <div v-if="selectedDelayedJob" class="space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold">执行时间: {{ selectedDelayedJob.formatted_time }}</h3>
          <Tag :value="`${selectedDelayedJob.jobs.length} 个任务`" severity="info" />
        </div>

        <DataTable :value="selectedDelayedJob.jobs" stripedRows>
          <template #empty>
            <div class="text-center py-4">
              <p class="text-gray-500">无任务</p>
            </div>
          </template>

          <Column field="class" header="任务类">
            <template #body="{ data }">
              <code class="text-sm">{{ data.class }}</code>
            </template>
          </Column>

          <Column field="args" header="参数">
            <template #body="{ data }">
              <div class="text-xs">
                <code v-if="data.args && data.args.length > 0">
                  {{ JSON.stringify(data.args).substring(0, 100) }}
                  <span v-if="JSON.stringify(data.args).length > 100">...</span>
                </code>
                <span v-else class="text-gray-400">无参数</span>
              </div>
            </template>
          </Column>

          <Column field="queue" header="队列">
            <template #body="{ data }">
              <span class="text-sm">{{ data.queue || 'default' }}</span>
            </template>
          </Column>
        </DataTable>
      </div>
    </Dialog>
  </div>
</template>

<style scoped lang="scss">
.transition-colors {
  transition-property: color, border-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}
</style>
