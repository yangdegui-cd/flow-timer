<script setup lang="ts">
import TaskExecList from "@/views/_tables/TaskExecList.vue";
import { onMounted, ref } from 'vue';
import { useToast } from "primevue/usetoast";
import { ApiCancelTaskExecution } from '@/api/task-execution-api';
import { ApiRetryTaskExecution } from '@/api/task-execution-api';
import { ApiList } from "@/api/base-api";

const toast = useToast();
const loading = ref(false);
const executions = ref([]);
const summary = ref({
  totalExecutions: 0,
  successCount: 0,
  failedCount: 0,
  runningCount: 0
});

const filters = ref({
  global: { value: '', matchMode: 'contains' },
  status: { value: null, matchMode: 'equals' },
  taskType: { value: null, matchMode: 'equals' }
});

const statusOptions = [
  { label: '全部', value: null },
  { label: '待执行', value: 'pending' },
  { label: '执行中', value: 'running' },
  { label: '已完成', value: 'completed' },
  { label: '执行失败', value: 'failed' },
  { label: '已取消', value: 'cancelled' }
];

const taskTypeOptions = [
  { label: '全部', value: null },
  { label: '一次性', value: 'disposable' },
  { label: '周期性', value: 'periodic' },
  { label: '依赖性', value: 'dependent' }
];

// 取消执行
const cancelExecution = async (executionId: string) => {
  try {
    const response = await ApiCancelTaskExecution(parseInt(executionId));
    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '取消成功',
        detail: '任务执行已取消',
        life: 3000
      });
      loadExecutions(); // 刷新列表
    } else {
      throw new Error(response.msg || '取消失败');
    }
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '取消失败',
      detail: error.message || '取消执行失败',
      life: 3000
    });
  }
};

// 重试执行
const retryExecution = async (executionId: string) => {
  try {
    const response = await ApiRetryTaskExecution(parseInt(executionId));
    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '重试成功',
        detail: '任务已重新提交执行',
        life: 3000
      });
      loadExecutions(); // 刷新列表
    } else {
      throw new Error(response.msg || '重试失败');
    }
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '重试失败',
      detail: error.message || '重试执行失败',
      life: 3000
    });
  }
};

const loadExecutions = () => {
  loading.value = true;
  ApiList("ft_task_execution").then((res) => {
    executions.value = res.map(item => ({
      id: item.id,
      executionId: item.execution_id,
      taskId: item.ft_task?.task_id || item.task_id,
      taskName: item.ft_task?.task_name || '未知任务',
      taskType: item.ft_task?.task_type,
      flowId: item.ft_task?.flow_id,
      flowName: item.ft_task?.flow_name || '未知流程',
      status: item.status,
      startTime: item.started_at,
      endTime: item.finished_at,
      duration: item.duration_seconds,
      executedBy: item.execution_type || 'system', // 使用execution_type字段
      result: item.result ? (typeof item.result === 'string' ? JSON.parse(item.result) : item.result) : null,
      errorMessage: item.error_message,
      retryCount: 0, // 数据库中暂时没有retry_count字段
      dataQuality: item.data_quality,
      dataTime: item.data_time,
      queue: item.queue,
      systemParams: item.system_params || {},
      customParams: item.custom_params || {},
      resqueJobId: item.resque_job_id
    }));

    // 更新统计数据
    updateSummary();
  }).catch((err) => {
    console.error('加载执行记录失败:', err);
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: err.msg || '获取执行记录失败',
      life: 3000
    });
  }).finally(() => {
    loading.value = false;
  });
};

// 更新统计数据
const updateSummary = () => {
  const total = executions.value.length;
  const completed = executions.value.filter(e => e.status === 'completed').length;
  const failed = executions.value.filter(e => e.status === 'failed').length;
  const running = executions.value.filter(e => e.status === 'running').length;
  const pending = executions.value.filter(e => e.status === 'pending').length;

  summary.value = {
    totalExecutions: total,
    successCount: completed,
    failedCount: failed,
    runningCount: running + pending // 将pending也算在运行中
  };
};

// 点击统计卡片时的筛选操作
const filterByStatus = (status: string | string[] | null) => {
  if (Array.isArray(status)) {
    // 对于数组状态，我们需要特殊处理，这里简化为只取第一个
    filters.value.status.value = status[0];
  } else {
    filters.value.status.value = status;
  }
};

onMounted(() => {
  loadExecutions();
});
</script>

<template>
  <div class="flex flex-col gap-4 h-screen w-full p-4">
    <!-- 统计卡片 -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <Card class="bg-gradient-to-r from-blue-50 to-blue-100 border-blue-200 cursor-pointer hover:shadow-lg transition-all transform hover:scale-105"
            @click="filterByStatus(null)" v-tooltip.top="'点击查看全部'">
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-blue-700">{{ summary.totalExecutions }}</div>
              <div class="text-sm text-blue-600">总执行次数</div>
            </div>
            <i class="pi pi-chart-bar text-3xl text-blue-500"></i>
          </div>
        </template>
      </Card>

      <Card class="bg-gradient-to-r from-green-50 to-green-100 border-green-200 cursor-pointer hover:shadow-lg transition-all transform hover:scale-105"
            @click="filterByStatus('completed')" v-tooltip.top="'点击筛选成功执行'">
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-green-700">{{ summary.successCount }}</div>
              <div class="text-sm text-green-600">成功执行</div>
            </div>
            <i class="pi pi-check-circle text-3xl text-green-500"></i>
          </div>
        </template>
      </Card>

      <Card class="bg-gradient-to-r from-red-50 to-red-100 border-red-200 cursor-pointer hover:shadow-lg transition-all transform hover:scale-105"
            @click="filterByStatus('failed')" v-tooltip.top="'点击筛选执行失败'">
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-red-700">{{ summary.failedCount }}</div>
              <div class="text-sm text-red-600">执行失败</div>
            </div>
            <i class="pi pi-times-circle text-3xl text-red-500"></i>
          </div>
        </template>
      </Card>

      <Card class="bg-gradient-to-r from-orange-50 to-orange-100 border-orange-200 cursor-pointer hover:shadow-lg transition-all transform hover:scale-105"
            @click="filterByStatus(['running', 'pending'])" v-tooltip.top="'点击筛选执行中'">
        <template #content>
          <div class="flex items-center justify-between">
            <div>
              <div class="text-2xl font-bold text-orange-700">{{ summary.runningCount }}</div>
              <div class="text-sm text-orange-600">执行中</div>
            </div>
            <i class="pi pi-spin pi-spinner text-3xl text-orange-500"></i>
          </div>
        </template>
      </Card>
    </div>

    <!-- 筛选器 -->
    <Card>
      <template #content>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <label class="text-sm font-medium">状态:</label>
            <Dropdown
                v-model="filters.status.value"
                :options="statusOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="选择状态"
                class="w-36"
                size="small"/>
          </div>

          <div class="flex items-center gap-2">
            <label class="text-sm font-medium">任务类型:</label>
            <Dropdown
                v-model="filters.taskType.value"
                :options="taskTypeOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="选择类型"
                class="w-36"
                size="small"/>
          </div>

          <div class="flex items-center gap-2">
            <label class="text-sm font-medium">搜索:</label>
            <InputText
                v-model="filters.global.value"
                placeholder="搜索任务或流程..."
                class="w-64"
                size="small"/>
          </div>

          <Button
              icon="pi pi-refresh"
              label="刷新"
              size="small"
              severity="secondary"
              @click="loadExecutions"
              :loading="loading"/>
        </div>
      </template>
    </Card>

    <!-- 执行记录列表 -->
    <div class="flex-1 min-h-0 border border-surface rounded-2xl overflow-hidden">
      <task-exec-list
          :data="executions"
          :loading="loading"
          :filters="filters"
          @retry="retryExecution"
          @cancel="cancelExecution"/>
    </div>
  </div>
</template>

<style scoped>

</style>
