<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useToast } from "primevue/usetoast";

const toast = useToast();
const loading = ref(false);

// 系统状态
const systemStatus = ref({
  status: 'running',
  uptime: '7天 12小时 35分钟',
  version: 'v1.0.0',
  lastRestart: '2025-01-05 09:30:00'
});

// 实时统计
const realtimeStats = ref({
  runningTasks: 5,
  pendingTasks: 23,
  completedToday: 147,
  failedToday: 3,
  avgExecutionTime: 2.5,
  systemLoad: 45.2
});

// 任务类型分布
const taskTypeData = ref({
  labels: ['一次性任务', '周期性任务', '依赖任务'],
  datasets: [{
    data: [30, 45, 25],
    backgroundColor: ['#3B82F6', '#10B981', '#F59E0B']
  }]
});

// 执行状态统计
const executionStats = ref({
  labels: ['成功', '失败', '执行中', '待执行'],
  datasets: [{
    data: [147, 3, 5, 23],
    backgroundColor: ['#10B981', '#EF4444', '#F59E0B', '#6B7280']
  }]
});

// 最近执行趋势
const executionTrend = ref({
  labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'],
  datasets: [{
    label: '执行次数',
    data: [12, 8, 25, 30, 22, 18],
    borderColor: '#3B82F6',
    backgroundColor: 'rgba(59, 130, 246, 0.1)',
    tension: 0.4
  }]
});

// 系统资源使用
const resourceUsage = ref([
  { name: 'CPU使用率', value: 45.2, max: 100, color: 'bg-blue-500' },
  { name: '内存使用率', value: 68.7, max: 100, color: 'bg-green-500' },
  { name: '磁盘使用率', value: 32.1, max: 100, color: 'bg-yellow-500' }
]);

// 最近错误日志
const recentErrors = ref([
  {
    id: 1,
    time: '2025-01-12 14:30:25',
    level: 'ERROR',
    message: '任务执行超时: task-001 (数据同步任务)',
    details: 'Connection timeout after 30 seconds'
  },
  {
    id: 2,
    time: '2025-01-12 13:45:12',
    level: 'WARN',
    message: '任务重试: task-005 (报告生成)',
    details: 'Retry attempt 2/3'
  },
  {
    id: 3,
    time: '2025-01-12 12:15:08',
    level: 'ERROR',
    message: '流程节点异常: flow-003 节点HTTP_REQUEST',
    details: 'HTTP 500 - Internal Server Error'
  }
]);

const loadMonitoringData = async () => {
  loading.value = true;
  try {
    // 模拟加载监控数据
    await new Promise(resolve => setTimeout(resolve, 1000));
    toast.add({ 
      severity: 'success', 
      summary: '数据更新', 
      detail: '监控数据已更新', 
      life: 2000 
    });
  } catch (error) {
    toast.add({ 
      severity: 'error', 
      summary: '加载失败', 
      detail: '获取监控数据失败', 
      life: 3000 
    });
  } finally {
    loading.value = false;
  }
};

// 获取状态颜色
const getStatusColor = (status: string) => {
  switch (status) {
    case 'running': return 'text-green-600 bg-green-100';
    case 'stopped': return 'text-red-600 bg-red-100';
    case 'maintenance': return 'text-yellow-600 bg-yellow-100';
    default: return 'text-gray-600 bg-gray-100';
  }
};

// 获取日志级别样式
const getLogLevelClass = (level: string) => {
  switch (level) {
    case 'ERROR': return 'text-red-600 bg-red-100';
    case 'WARN': return 'text-yellow-600 bg-yellow-100';
    case 'INFO': return 'text-blue-600 bg-blue-100';
    default: return 'text-gray-600 bg-gray-100';
  }
};

onMounted(() => {
  loadMonitoringData();
  // 定时刷新数据
  setInterval(() => {
    // 更新实时数据
    realtimeStats.value.systemLoad = Math.random() * 100;
  }, 5000);
});
</script>

<template>
  <div class="flex flex-col gap-4 h-full w-full overflow-auto">
    <!-- 系统状态概览 -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
      <Card>
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-sm text-gray-600 mb-1">系统状态</div>
              <div class="flex items-center gap-2">
                <span :class="['px-2 py-1 rounded-full text-xs font-medium', getStatusColor(systemStatus.status)]">
                  {{ systemStatus.status === 'running' ? '运行中' : '已停止' }}
                </span>
              </div>
            </div>
            <i class="pi pi-server text-2xl text-green-500"></i>
          </div>
          <div class="mt-3 text-xs text-gray-500">
            运行时间: {{ systemStatus.uptime }}
          </div>
        </template>
      </Card>

      <Card>
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-blue-600">{{ realtimeStats.runningTasks }}</div>
              <div class="text-sm text-gray-600">运行中任务</div>
            </div>
            <i class="pi pi-play-circle text-2xl text-blue-500"></i>
          </div>
        </template>
      </Card>

      <Card>
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-green-600">{{ realtimeStats.completedToday }}</div>
              <div class="text-sm text-gray-600">今日完成</div>
            </div>
            <i class="pi pi-check-circle text-2xl text-green-500"></i>
          </div>
        </template>
      </Card>

      <Card>
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-red-600">{{ realtimeStats.failedToday }}</div>
              <div class="text-sm text-gray-600">今日失败</div>
            </div>
            <i class="pi pi-times-circle text-2xl text-red-500"></i>
          </div>
        </template>
      </Card>
    </div>

    <!-- 图表区域 -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <!-- 任务类型分布 -->
      <Card>
        <template #header>
          <div class="flex items-center justify-between w-full p-4">
            <h3 class="text-lg font-semibold">任务类型分布</h3>
            <Button icon="pi pi-refresh" text size="small" @click="loadMonitoringData" />
          </div>
        </template>
        <template #content>
          <div class="h-64 flex items-center justify-center">
            <div class="text-center">
              <i class="pi pi-chart-pie text-6xl text-gray-300 mb-4 block"></i>
              <p class="text-gray-500">饼图组件待集成</p>
            </div>
          </div>
        </template>
      </Card>

      <!-- 执行趋势 -->
      <Card>
        <template #header>
          <div class="flex items-center justify-between w-full p-4">
            <h3 class="text-lg font-semibold">执行趋势</h3>
            <Button icon="pi pi-refresh" text size="small" @click="loadMonitoringData" />
          </div>
        </template>
        <template #content>
          <div class="h-64 flex items-center justify-center">
            <div class="text-center">
              <i class="pi pi-chart-line text-6xl text-gray-300 mb-4 block"></i>
              <p class="text-gray-500">图表组件待集成</p>
            </div>
          </div>
        </template>
      </Card>
    </div>

    <!-- 系统资源和错误日志 -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <!-- 系统资源使用 -->
      <Card>
        <template #header>
          <div class="p-4">
            <h3 class="text-lg font-semibold">系统资源使用</h3>
          </div>
        </template>
        <template #content>
          <div class="space-y-4">
            <div v-for="resource in resourceUsage" :key="resource.name" class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="font-medium">{{ resource.name }}</span>
                <span class="text-gray-600">{{ resource.value.toFixed(1) }}%</span>
              </div>
              <div class="w-full bg-gray-200 rounded-full h-2">
                <div 
                  :class="resource.color" 
                  class="h-2 rounded-full transition-all duration-300"
                  :style="{ width: `${resource.value}%` }">
                </div>
              </div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 最近错误日志 -->
      <Card>
        <template #header>
          <div class="flex items-center justify-between w-full p-4">
            <h3 class="text-lg font-semibold">最近错误日志</h3>
            <Button label="查看全部" text size="small" />
          </div>
        </template>
        <template #content>
          <div class="space-y-3 max-h-80 overflow-y-auto">
            <div v-for="error in recentErrors" :key="error.id" 
                 class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
              <span :class="['px-2 py-1 rounded text-xs font-medium', getLogLevelClass(error.level)]">
                {{ error.level }}
              </span>
              <div class="flex-1 min-w-0">
                <div class="text-sm font-medium text-gray-900 truncate">{{ error.message }}</div>
                <div class="text-xs text-gray-500 mt-1">{{ error.time }}</div>
                <div class="text-xs text-gray-600 mt-1">{{ error.details }}</div>
              </div>
            </div>
          </div>
        </template>
      </Card>
    </div>

    <!-- 快速操作 -->
    <Card>
      <template #header>
        <div class="p-4">
          <h3 class="text-lg font-semibold">快速操作</h3>
        </div>
      </template>
      <template #content>
        <div class="flex items-center gap-4">
          <Button icon="pi pi-refresh" label="重新加载数据" severity="secondary" @click="loadMonitoringData" :loading="loading" />
          <Button icon="pi pi-download" label="导出监控报告" severity="secondary" />
          <Button icon="pi pi-cog" label="监控设置" severity="secondary" />
          <Button icon="pi pi-bell" label="告警设置" severity="secondary" />
        </div>
      </template>
    </Card>
  </div>
</template>

<style scoped>

</style>