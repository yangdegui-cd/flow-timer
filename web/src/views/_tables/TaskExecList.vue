<script setup lang="ts">
import { nextTick, ref } from 'vue';
import { useToast } from 'primevue/usetoast';
import { VueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import CommonNode from '@/nodes/view/CommonNode.vue';
import { ApiGetTaskExecutionResult } from "@/api/task-execution-api";

const toast = useToast();
const props = defineProps<{
  data: any[],
  loading: boolean,
  filters: any
}>();

const emit = defineEmits<{
  retry: [executionId: string],
  cancel: [executionId: string]
}>();

// Popover 引用
const execution_detail_popover = ref();
// 当前查看的行
const view_row = ref(null);
// 数据质量弹窗
const data_quality_dialog = ref(false);
const data_quality_loading = ref(false);
const execution_result = ref(null);
// Vue Flow 数据
const flow_nodes = ref([]);
const flow_edges = ref([]);

// 格式化时间显示
const formatDateTime = (dateString: string) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString('zh-CN');
};

// 格式化持续时间
const formatDuration = (seconds: number) => {
  if (!seconds) return '-';
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  if (hours > 0) {
    return `${hours}时${minutes}分${secs}秒`;
  } else if (minutes > 0) {
    return `${minutes}分${secs}秒`;
  } else {
    return `${secs}秒`;
  }
};

// 获取状态显示样式
const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'completed':
      return 'success';
    case 'running':
      return 'info';
    case 'failed':
      return 'danger';
    case 'pending':
      return 'secondary';
    case 'cancelled':
      return 'contrast';
    default:
      return 'secondary';
  }
};

// 获取任务类型显示样式
const getTaskTypeSeverity = (taskType: string) => {
  switch (taskType) {
    case 'disposable':
      return 'info';
    case 'periodic':
      return 'success';
    case 'dependent':
      return 'warning';
    default:
      return 'secondary';
  }
};

// 任务类型中文显示
const getTaskTypeLabel = (taskType: string) => {
  switch (taskType) {
    case 'disposable':
      return '一次性';
    case 'periodic':
      return '周期性';
    case 'dependent':
      return '依赖性';
    default:
      return taskType;
  }
};

// 状态中文显示
const getStatusLabel = (status: string) => {
  switch (status) {
    case 'pending':
      return '待执行';
    case 'running':
      return '执行中';
    case 'completed':
      return '已完成';
    case 'failed':
      return '执行失败';
    case 'cancelled':
      return '已取消';
    default:
      return status;
  }
};

// 查看执行详情
const viewDetails = (execution: any) => {
  let detail = `任务: ${execution.taskName}\n流程: ${execution.flowName}\n状态: ${getStatusLabel(execution.status)}`;

  if (execution.errorMessage) {
    detail += `\n错误信息: ${execution.errorMessage}`;
  }

  if (execution.retryCount > 0) {
    detail += `\n重试次数: ${execution.retryCount}`;
  }

  toast.add({
    severity: 'info',
    summary: '执行详情',
    detail: detail,
    life: 8000
  });
};

// 重试执行
const handleRetry = (execution: any) => {
  emit('retry', execution.executionId);
};

// 取消执行
const handleCancel = (execution: any) => {
  emit('cancel', execution.executionId);
};

// 复制ID到剪贴板
const copyToClipboard = (text: string, type: string) => {
  navigator.clipboard.writeText(text).then(() => {
    toast.add({
      severity: 'success',
      summary: '复制成功',
      detail: `${type} 已复制到剪贴板`,
      life: 2000
    });
  });
};

// 获取数据时间的颜色类
const getDataTimeClass = (dataTime: string) => {
  if (!dataTime) return 'text-gray-400';

  const today = new Date().toISOString().split('T')[0];
  const dataDate = dataTime.split(' ')[0] || dataTime.split('T')[0];

  if (dataDate === today) {
    return 'text-green-600 font-semibold'; // 今天 - 绿色加粗
  } else if (dataDate < today) {
    const daysDiff = Math.floor((new Date(today).getTime() - new Date(dataDate).getTime()) / (1000 * 60 * 60 * 24));
    if (daysDiff <= 7) {
      return 'text-orange-600'; // 7天内 - 橙色
    } else {
      return 'text-red-600'; // 超过7天 - 红色
    }
  } else {
    return 'text-blue-600'; // 未来日期 - 蓝色
  }
};

// 显示详情弹窗
const displayPopover = (event, row) => {
  execution_detail_popover.value?.hide();
  if (view_row.value?.id === row.id) {
    view_row.value = null;
  } else {
    view_row.value = row;
    nextTick(() => execution_detail_popover.value?.show(event));
  }
};

// 隐藏弹窗
const hidePopover = () => {
  execution_detail_popover.value?.hide();
  view_row.value = null;
};

// 将执行结果转换为流程图数据
const convertResultToFlow = (result: any) => {
  if (!result) {
    flow_nodes.value = [];
    flow_edges.value = [];
    return;
  }
  flow_nodes.value = result.nodes || [];
  flow_edges.value = result.edges || [];
};

// 查看数据质量
const viewDataQuality = (execution: any) => {
  data_quality_loading.value = true;
  data_quality_dialog.value = true;

  ApiGetTaskExecutionResult(execution.id).then(res => {
    execution_result.value = res
  }).catch(error => {
    execution_result.value = null;
    toast.add({
      severity: 'error',
      summary: '获取执行结果失败',
      detail: error.msg || '无法获取执行结果数据',
      life: 3000
    });
  }).finally(() => {
    convertResultToFlow(execution_result.value);
    data_quality_loading.value = false;
  });
}

</script>

<template>
  <DataTable
      :value="data"
      :loading="loading"
      :globalFilterFields="['taskName', 'flowName', 'status', 'taskType']"
      :filters="filters"
      tableStyle="min-width: 50rem"
      class="w-full h-full execution-table"
      paginator
      :rows="15"
      size="small"
      scrollable
      scrollHeight="calc(100vh - 280px)"
      sortMode="multiple"
      :pt="{
      header: { class: 'bg-white border-b border-gray-200 p-2' },
    }"
      :rowsPerPageOptions="[10, 15, 20, 50]"
      paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
      currentPageReportTemplate="{first} to {last} of {totalRecords}">

    <template #empty>
      <div class="text-center py-8">
        <i class="pi pi-inbox text-4xl text-gray-400 mb-4 block"></i>
        <p class="text-gray-500">暂无执行记录</p>
      </div>
    </template>

    <template #loading>
      <div class="text-center py-8">
        <i class="pi pi-spin pi-spinner text-2xl text-blue-500 mb-2 block"></i>
        <p>加载执行记录中...</p>
      </div>
    </template>

    <!-- 执行信息（合并列） -->
    <Column field="taskName" header="执行信息" sortable style="min-width: 280px">
      <template #body="{ data }">
        <div class="space-y-1 cursor-pointer hover:bg-gray-50 p-2 rounded transition-colors"
             @click="displayPopover($event, data)"
             v-tooltip.top="'点击查看详情'">

          <!-- 执行ID -->
          <div class="flex items-center gap-2">
            <span class="font-mono text-sm bg-blue-100 px-2 py-1 rounded">#{{ data.id }}</span>
            <Tag :value="getStatusLabel(data.status)"
                 :severity="getStatusSeverity(data.status)"
                 class="text-xs"/>
          </div>
        </div>
      </template>
    </Column>

    <!-- 数据时间 -->
    <Column field="dataTime" header="数据时间" sortable style="min-width: 160px">
      <template #body="{ data }">
        <span v-if="data.dataTime" :class="getDataTimeClass(data.dataTime)" class="text-sm font-medium">
          {{ data.dataTime }}
        </span>
        <span v-else class="text-gray-400 text-sm">-</span>
      </template>
    </Column>


    <!-- 开始时间 -->
    <Column field="startTime" header="开始时间" sortable style="min-width: 160px">
      <template #body="{ data }">
        <span class="text-sm">{{ formatDateTime(data.startTime) }}</span>
      </template>
    </Column>

    <!-- 执行时长 -->
    <Column field="duration" header="执行时长" sortable style="min-width: 120px">
      <template #body="{ data }">
        <div class="text-sm">
          <span v-if="data.duration" class="font-medium text-blue-600">
            {{ formatDuration(data.duration) }}
          </span>
          <span v-else-if="data.status === 'running'" class="text-orange-500">
            <i class="pi pi-spin pi-spinner mr-1"></i>运行中
          </span>
          <span v-else class="text-gray-400">-</span>
        </div>
      </template>
    </Column>

    <!-- 结束时间 -->
    <Column field="endTime" header="结束时间" sortable style="min-width: 160px">
      <template #body="{ data }">
        <span v-if="data.endTime" class="text-sm">{{ formatDateTime(data.endTime) }}</span>
        <span v-else class="text-gray-400 text-sm">-</span>
      </template>
    </Column>

    <!-- 执行类型 -->
    <Column field="executedBy" header="执行类型" sortable style="min-width: 100px">
      <template #body="{ data }">
        <div class="flex items-center gap-2">
          <i class="pi pi-cog text-xs text-gray-500"></i>
          <span class="text-sm">{{ data.executedBy }}</span>
        </div>
      </template>
    </Column>

    <!-- 系统参数 -->
    <Column field="systemParams" header="系统参数" style="min-width: 150px">
      <template #body="{ data }">
        <div class="text-sm">
          <span v-if="data.systemParams && Object.keys(data.systemParams).length > 0"
                class="cursor-pointer text-blue-600 hover:text-blue-800 flex items-center gap-1"
                @click="displayPopover($event, data)"
                v-tooltip.top="'点击查看系统参数详情'">
            <i class="pi pi-cog text-xs"></i>
            {{ Object.keys(data.systemParams).length }} 个参数
          </span>
          <span v-else class="text-gray-400">-</span>
        </div>
      </template>
    </Column>

    <!-- 自定义参数 -->
    <Column field="customParams" header="自定义参数" style="min-width: 150px">
      <template #body="{ data }">
        <div class="text-sm">
          <span v-if="data.customParams && Object.keys(data.customParams).length > 0"
                class="cursor-pointer text-purple-600 hover:text-purple-800 flex items-center gap-1"
                @click="displayPopover($event, data)"
                v-tooltip.top="'点击查看自定义参数详情'">
            <i class="pi pi-sliders-h text-xs"></i>
            {{ Object.keys(data.customParams).length }} 个参数
          </span>
          <span v-else class="text-gray-400">-</span>
        </div>
      </template>
    </Column>

    <!-- 数据时间 -->
    <Column field="dataTime" header="数据时间" sortable style="min-width: 160px" v-if="false">
      <template #body="{ data }">
        <span class="text-sm" v-if="data.dataTime">{{ formatDateTime(data.dataTime) }}</span>
        <span v-else class="text-gray-400 text-sm">-</span>
      </template>
    </Column>

    <!-- 执行结果 -->
    <Column field="result" header="执行结果" style="min-width: 150px">
      <template #body="{ data }">
        <div v-if="data.status === 'failed' && data.errorMessage" class="text-xs">
          <div class="text-red-600 truncate max-w-32" :title="data.errorMessage">
            错误: {{ data.errorMessage }}
          </div>
        </div>
        <div v-else-if="data.result" class="text-xs">
          <div v-if="data.result.source_files_count" class="text-gray-600">
            源文件: {{ data.result.source_files_count }}个
          </div>
          <div v-if="data.result.processed_files" class="text-green-600">
            处理: {{
              Array.isArray(data.result.processed_files) ? data.result.processed_files.length : data.result.processed_files
            }}个
          </div>
          <div v-if="data.result.transfer_results" class="text-blue-600">
            传输: {{
              Array.isArray(data.result.transfer_results) ? data.result.transfer_results.length : data.result.transfer_results
            }}个
          </div>
          <div v-if="data.result.success" class="text-green-600">
            成功: {{ data.result.success }}条
          </div>
          <div v-if="data.result.failed" class="text-red-600">
            失败: {{ data.result.failed }}条
          </div>
          <div v-if="data.result.message" class="text-gray-600 truncate max-w-32" :title="data.result.message">
            {{ data.result.message }}
          </div>
        </div>
        <span v-else class="text-gray-400 text-sm">-</span>
      </template>
    </Column>

    <!-- 操作 -->
    <Column field="actions" header="操作" style="min-width: 150px">
      <template #body="{ data }">
        <div class="flex items-center gap-1">
          <Button icon="pi pi-eye"
                  text
                  size="small"
                  severity="secondary"
                  v-tooltip.top="'查看详情'"
                  @click="displayPopover($event, data)"/>

          <Button icon="pi pi-chart-line"
                  text
                  size="small"
                  severity="info"
                  v-tooltip.top="'查看数据质量'"
                  @click="viewDataQuality(data)"/>

          <Button icon="pi pi-download"
                  text
                  size="small"
                  severity="secondary"
                  v-tooltip.top="'导出日志'"
                  @click="toast.add({ severity: 'info', summary: '功能开发中', life: 2000 })"/>

          <Button v-if="data.status === 'failed'"
                  icon="pi pi-replay"
                  text
                  size="small"
                  severity="warning"
                  v-tooltip.top="'重新执行'"
                  @click="handleRetry(data)"/>

          <Button v-if="data.status === 'pending'"
                  icon="pi pi-times"
                  text
                  size="small"
                  severity="danger"
                  v-tooltip.top="'取消执行'"
                  @click="handleCancel(data)"/>
        </div>
      </template>
    </Column>
  </DataTable>

  <!-- 执行详情弹窗 -->
  <Popover ref="execution_detail_popover">
    <div class="flex flex-col gap-3 p-4 min-w-96 max-w-2xl max-h-[80vh] overflow-auto">
      <div class="border-b pb-2 mb-2">
        <h3 class="font-bold text-lg flex items-center gap-2">
          <i class="pi pi-info-circle text-blue-500"></i>
          执行详情
        </h3>
      </div>

      <!-- 基本信息 -->
      <div class="grid grid-cols-2 gap-3 text-sm">
        <div class="flex items-center gap-2">
          <span class="font-semibold">执行ID:</span>
          <span class="font-mono bg-blue-100 px-2 py-1 rounded text-xs">#{{ view_row?.id }}</span>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">状态:</span>
          <Tag :value="getStatusLabel(view_row?.status)"
               :severity="getStatusSeverity(view_row?.status)"
               class="text-xs"/>
        </div>

        <div class="col-span-2 flex items-center gap-2">
          <span class="font-semibold">执行唯一ID:</span>
          <span class="font-mono bg-gray-100 px-2 py-1 rounded text-xs flex-1">{{ view_row?.executionId }}</span>
          <Button icon="pi pi-copy" text size="small"
                  @click="copyToClipboard(view_row?.executionId, '执行唯一ID')"/>
        </div>
      </div>

      <!-- 任务和流程信息 -->
      <div class="space-y-3">
        <!-- 任务信息 -->
        <div v-if="view_row?.taskName && view_row?.taskName !== '未知任务'" class="bg-blue-50 p-3 rounded">
          <h4 class="font-semibold text-blue-800 mb-2 flex items-center gap-2">
            <i class="pi pi-clock"></i>任务信息
          </h4>
          <div class="space-y-1 text-sm">
            <div><strong>任务名称:</strong> {{ view_row?.taskName }}</div>
            <div v-if="view_row?.taskId"><strong>任务ID:</strong>
              <span class="font-mono">{{ view_row?.taskId }}</span>
              <Button icon="pi pi-copy" text size="small"
                      @click="copyToClipboard(view_row?.taskId, '任务ID')"/>
            </div>
            <div v-if="view_row?.taskType"><strong>任务类型:</strong>
              <Tag :value="getTaskTypeLabel(view_row?.taskType)"
                   :severity="getTaskTypeSeverity(view_row?.taskType)"
                   class="text-xs"/>
            </div>
          </div>
        </div>

        <!-- 流程信息 -->
        <div v-if="view_row?.flowName && view_row?.flowName !== '未知流程'" class="bg-green-50 p-3 rounded">
          <h4 class="font-semibold text-green-800 mb-2 flex items-center gap-2">
            <i class="pi pi-sitemap"></i>流程信息
          </h4>
          <div class="space-y-1 text-sm">
            <div><strong>流程名称:</strong> {{ view_row?.flowName }}</div>
            <div v-if="view_row?.flowId"><strong>流程ID:</strong>
              <span class="font-mono">{{ view_row?.flowId }}</span>
              <Button icon="pi pi-copy" text size="small"
                      @click="copyToClipboard(view_row?.flowId, '流程ID')"/>
            </div>
          </div>
        </div>
      </div>

      <!-- 系统参数 -->
      <div v-if="view_row?.systemParams && Object.keys(view_row.systemParams).length > 0"
           class="bg-gray-50 p-3 rounded">
        <h4 class="font-semibold text-gray-800 mb-2 flex items-center gap-2">
          <i class="pi pi-cog"></i>系统参数
        </h4>
        <div class="space-y-1 text-sm">
          <div v-for="(value, key) in view_row.systemParams" :key="key" class="flex justify-between">
            <span class="font-medium">{{ key }}:</span>
            <span class="bg-white px-2 py-1 rounded font-mono text-xs">{{ value }}</span>
          </div>
        </div>
      </div>

      <!-- 自定义参数 -->
      <div v-if="view_row?.customParams && Object.keys(view_row.customParams).length > 0"
           class="bg-purple-50 p-3 rounded">
        <h4 class="font-semibold text-purple-800 mb-2 flex items-center gap-2">
          <i class="pi pi-sliders-h"></i>自定义参数
        </h4>
        <div class="space-y-1 text-sm">
          <div v-for="(value, key) in view_row.customParams" :key="key" class="flex justify-between">
            <span class="font-medium">{{ key }}:</span>
            <span class="bg-white px-2 py-1 rounded font-mono text-xs">{{ value }}</span>
          </div>
        </div>
      </div>

      <!-- 时间信息 -->
      <div class="bg-indigo-50 p-3 rounded">
        <h4 class="font-semibold text-indigo-800 mb-2 flex items-center gap-2">
          <i class="pi pi-calendar"></i>执行时间
        </h4>
        <div class="grid grid-cols-1 gap-1 text-sm">
          <div><strong>数据时间:</strong>
            <span v-if="view_row?.dataTime" :class="getDataTimeClass(view_row.dataTime)">
              {{ formatDateTime(view_row.dataTime) }}
            </span>
            <span v-else class="text-gray-400">-</span>
          </div>
          <div><strong>开始时间:</strong>
            <span v-if="view_row?.startTime">{{ formatDateTime(view_row.startTime) }}</span>
            <span v-else class="text-gray-400">-</span>
          </div>
          <div><strong>执行时长:</strong>
            <span v-if="view_row?.duration" class="font-medium text-blue-600">
              {{ formatDuration(view_row.duration) }}
            </span>
            <span v-else-if="view_row?.status === 'running'" class="text-orange-500">
              <i class="pi pi-spin pi-spinner mr-1"></i>运行中
            </span>
            <span v-else class="text-gray-400">-</span>
          </div>
        </div>
      </div>

      <!-- 错误信息 -->
      <div v-if="view_row?.errorMessage" class="bg-red-50 p-3 rounded border border-red-200">
        <h4 class="font-semibold text-red-800 mb-2 flex items-center gap-2">
          <i class="pi pi-exclamation-triangle"></i>错误信息
        </h4>
        <div class="text-sm text-red-700 bg-white p-2 rounded font-mono">
          {{ view_row.errorMessage }}
        </div>
      </div>
    </div>
  </Popover>

  <!-- 数据质量弹窗 -->
  <Dialog v-model:visible="data_quality_dialog"
          header="数据质量视图"
          :style="{ width: '90vw'}"
          maximizable
          modal>
    <div class="h-full flex flex-col">
      <div v-if="data_quality_loading" class="flex items-center justify-center h-full">
        <i class="pi pi-spin pi-spinner text-2xl text-blue-500 mb-2 block"></i>
        <p>加载数据质量信息中...</p>
      </div>

      <div v-else-if="!execution_result" class="flex items-center justify-center h-full">
        <div class="text-center">
          <i class="pi pi-info-circle text-4xl text-gray-400 mb-4 block"></i>
          <p class="text-gray-500">暂无执行结果数据</p>
        </div>
      </div>

      <div v-else class="h-full w-full">
        <!-- Vue Flow 容器 -->
        <div class="bg-gray-50 border rounded p-4 h-full">
          <h3 class="text-lg font-semibold mb-4">执行结果流程图</h3>
          <div class="bg-white border rounded h-[60vh] overflow-hidden ">
            <VueFlow
                v-if="flow_nodes.length > 0"
                :nodes="flow_nodes"
                :edges="flow_edges">
              <Background pattern-color="#aaa" :gap="8"/>
              <Controls/>
              <template #node-common="nodeProps">
                <CommonNode v-bind="nodeProps" :toolbar="true"/>
              </template>
            </VueFlow>

            <!-- 原始数据展示（备用） -->
            <div v-else class="h-full flex items-center justify-center">
              <div class="text-center">
                <i class="pi pi-sitemap text-4xl text-blue-500 mb-4 block"></i>
                <p class="text-gray-600 mb-2">执行结果详情</p>
                <div class="text-left bg-gray-100 p-4 rounded max-w-2xl max-h-96 overflow-auto">
                  <pre class="text-sm whitespace-pre-wrap">{{ JSON.stringify(execution_result, null, 2) }}</pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Dialog>
</template>

<style scoped>
.execution-table {
  height: 100% !important;
  --p-datatable-header-cell-sm-padding: 0.75rem 0.5rem;
}

.execution-table .p-datatable-wrapper {
  height: calc(100% - 120px) !important;
  max-height: calc(100vh - 280px) !important;
}

/* 数据时间颜色样式 */
.text-green-600 {
  color: #16a34a;
}

.text-orange-600 {
  color: #ea580c;
}

.text-red-600 {
  color: #dc2626;
}

.text-blue-600 {
  color: #2563eb;
}
</style>
