<script setup lang="ts">
import { onMounted, Ref, watch } from "vue";
import { ApiList, ApiRequest } from "@/api/base-api";
import { useRouter } from "vue-router";
import { SpaceType } from "@/data/types/type";
import clipboard from "@/utils/clipboard";
import { useToast } from "primevue/usetoast";
import { useConfirm } from 'primevue/useconfirm';
import request from "@/request";
import TaskExecuteDialog from "@/views/_dialogs/TaskExecuteDialog.vue";

const router = useRouter()
const toast = useToast();
const confirm = useConfirm();
const props = defineProps<{ catalogs: Ref<int[]> }>()

watch(() => props.catalogs, () => {
  console.log("Catalogs changed:", props.catalogs)
  handleGetRows()
})

const loading_data = ref(false)
const executing_tasks = ref<Set<string>>(new Set())
const activating_tasks = ref<Set<string>>(new Set())
const show_execute_dialog = ref(false)
const selected_execute_task = ref(null)
const selected_execute_tasks = ref(null)
const filters = ref({
  global: {
    value: '',
    matchMode: 'contains'
  }
})

onMounted(() => {
  handleGetCatalogConfig()
  handleGetRows()
})

const rows = ref([])
const locked_rows = ref([])
const editing_rows = ref([])
const selected_rows = ref([])
const name_popover = ref();
const params_popover = ref();
const status_popover = ref();
// 鼠标点击查看行
const view_row = ref(null);
const catalog_config = ref<Record<any, any>>({})

const displayPopover = (event, row, popover) => {
  unref(popover)?.hide()
  if (view_row.value?.id === row.id) {
    view_row.value = null;
  } else {
    view_row.value = row;
    nextTick(() => unref(popover)?.show(event));
  }
};

const hidePopover = (popover) => {
  unref(popover)?.hide()
  view_row.value = null;
}

const toggleLock = (data, frozen, index) => {
  if (frozen) {
    locked_rows.value = locked_rows.value.filter((c, i) => i !== index);
    rows.value.push(data);
  } else {
    rows.value = rows.value.filter((c, i) => i !== index);
    locked_rows.value.push(data);
  }
  rows.value.sort((val1, val2) => {
    return val1.id < val2.id ? -1 : 1;
  });
};

const handleGetRows = () => {
  loading_data.value = true
  ApiList("ft_task", { catalog_id: props.catalogs }).then((res) => {
    rows.value = res
  }).catch((error) => {
    console.error("Failed to fetch tasks:", error)
    toast.add({ severity: 'error', summary: '加载失败', detail: error.msg || '获取任务列表失败', life: 3000 });
  }).finally(() => {
    loading_data.value = false
  })
}

const handleGetCatalogConfig = () => {
  ApiList("space", { type: SpaceType.TASK }).then((res) => {
    catalog_config.value = res.reduce((acc, item) => {
      item.catalogs.forEach((catalog) => {
        acc[catalog.id] = {
          space_name: item.name,
          catalog_name: catalog.name,
          space_id: item.id,
          catalog_id: catalog.id
        };
      });
      return acc;
    }, {});
  }).catch((error) => {
    console.error("Failed to fetch catalog config:", error)
  });
}

// 执行任务
const executeTask = async (taskId: string) => {
  executing_tasks.value.add(taskId);
  try {
    const response = await request({
      url: `/ft_task/${taskId}/execute`,
      method: 'post'
    });

    if (response.success) {
      toast.add({
        severity: 'success',
        summary: '执行成功',
        detail: `任务 ${taskId} 执行成功`,
        life: 3000
      });
      // 刷新数据
      handleGetRows();
    } else {
      toast.add({
        severity: 'error',
        summary: '执行失败',
        detail: response.msg || '任务执行失败',
        life: 5000
      });
    }
  } catch (error) {
    console.error('Execute task error:', error);
    toast.add({
      severity: 'error',
      summary: '执行异常',
      detail: '任务执行请求失败',
      life: 5000
    });
  } finally {
    executing_tasks.value.delete(taskId);
  }
}

// 批量执行任务
const executeBatchTasks = () => {
  if (selected_rows.value.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请先选择要执行的任务', life: 3000 });
    return;
  }

  // 检查选中的任务是否都是激活状态
  const inactiveTasks = selected_rows.value.filter(task => task.status !== 'active');
  if (inactiveTasks.length > 0) {
    toast.add({
      severity: 'warn',
      summary: '提示',
      detail: `选中的任务中有 ${inactiveTasks.length} 个非激活状态的任务，只能执行激活状态的任务`,
      life: 5000
    });
    return;
  }

  // 打开批量执行对话框
  selected_execute_tasks.value = selected_rows.value;
  show_execute_dialog.value = true;
}

// 检查任务是否可执行
const checkTaskExecutable = async (taskId: string) => {
  try {
    const response = await request({
      url: `/ft_task/${taskId}/check_executable`,
      method: 'get'
    });

    if (response.success) {
      const info = response.data;
      const message = `
        任务类型: ${info.task_type}
        当前状态: ${info.status}
        可执行: ${info.can_execute ? '是' : '否'}
        生效时间: ${new Date(info.effective_time).toLocaleString()}
        ${info.lose_efficacy_time ? `失效时间: ${new Date(info.lose_efficacy_time).toLocaleString()}` : ''}
        依赖满足: ${info.dependencies_satisfied ? '是' : '否'}
      `;

      toast.add({
        severity: 'info',
        summary: '任务执行条件',
        detail: message,
        life: 8000
      });
    }
  } catch (error) {
    console.error('Check executable error:', error);
    toast.add({
      severity: 'error',
      summary: '检查失败',
      detail: '检查任务执行条件失败',
      life: 3000
    });
  }
}

// 获取任务状态显示样式
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
    default:
      return 'secondary';
  }
}

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
}

// 格式化时间显示
const formatDateTime = (dateString: string) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString('zh-CN');
}

// 激活任务
const activateTask = (taskId: string) => {
  ApiRequest('post', 'ft_task/activate', { task_ids: [taskId] })
      .then(res => {
        toast.add({ severity: 'success', detail: `任务 ${taskId} 已激活`, life: 3000 })
        handleGetRows();
      })
      .catch(err => {
        toast.add({ severity: 'error', summary: err.msg, life: 3000 })
      })
}

// 暂停任务
const deactivateTask = (taskId: string) => {
  ApiRequest('post', 'ft_task/deactivate', { task_ids: [taskId] })
      .then(res => {
        toast.add({ severity: 'success', detail: `任务 ${taskId} 已暂停`, life: 3000 })
        handleGetRows();
      })
      .catch(err => {
        toast.add({ severity: 'error', summary: err.msg, life: 3000 })
      })
}

// 显示立即执行对话框
const showExecuteDialog = (task: any) => {
  selected_execute_task.value = task;
  selected_execute_tasks.value = null;
  show_execute_dialog.value = true;
}

// 隐藏立即执行对话框
const hideExecuteDialog = () => {
  show_execute_dialog.value = false;
  selected_execute_task.value = null;
  selected_execute_tasks.value = null;
}

// 处理执行任务
const handleExecuteTask = async (executeParams: any) => {
  ApiRequest("post", "/ft_task/execute_immediate", executeParams)
      .then((response) => {
        toast.add({
          severity: 'success',
          summary: '执行提交成功',
          detail: response.msg || '任务执行提交成功',
          life: 5000
        });
      })
      .catch((error) => {
        toast.add({
          severity: 'error',
          summary: '执行异常',
          detail: error.msg,
          life: 5000
        });
      });
}

</script>

<template>
  <DataTable :value="rows"
             :frozenValue="locked_rows"
             v-model:editing-rows="editing_rows"
             v-model:selection="selected_rows"
             :loading="loading_data"
             :globalFilterFields="['name', 'description', 'task_type', 'status']"
             :filters="filters"
             tableStyle="min-width: 50rem; padding: 10px"
             class="w-full h-full"
             edit-mode="row"
             data-key="id"
             paginator
             :rows="20"
             size="small"
             scrollable
             scrollHeight="calc(100% - 200px)"
             sortMode="multiple"
             rowGroupMode="subheader"
             groupRowsBy="catalog_id"
             :rowsPerPageOptions="[5, 10, 20, 50]"
             paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
             currentPageReportTemplate="{first} to {last} of {totalRecords}"
             :pt="{
                table: { style: 'min-width: 50rem' },
                bodyrow: ({ props }) => ({
                    class: [{ 'font-bold bg-gray-100': props.frozenRow }]
                }),
                rowGroupHeader: [{ 'hidden': props.frozenRow }],
                header: { style: 'border-bottom: 1px solid var(--surface-border)' },
            }">
    <template #header>
      <div class="flex xl:items-center justify-between gap-2 flex-col xl:flex-row">
        <div class="flex items-center gap-2">
          <Button icon="pi pi-play"
                  aria-label="execute batch"
                  variant="outlined"
                  label="批量执行"
                  size="small"
                  :disabled="selected_rows.length === 0"
                  @click="executeBatchTasks"/>
          <Button icon="pi pi-refresh"
                  aria-label="refresh"
                  variant="outlined"
                  label="刷新"
                  size="small"
                  @click="handleGetRows"/>
          <Button icon="pi pi-trash"
                  aria-label="delete"
                  severity="danger"
                  variant="outlined"
                  label="删除"
                  :disabled="selected_rows.length === 0"
                  size="small"/>
          <Button icon="pi pi-plus"
                  aria-label="add"
                  label="新增任务"
                  size="small"
                  @click="router.push('/task/add')"/>
        </div>
        <div class="flex items-center gap-2">
          <FloatLabel variant="on">
            <IconField>
              <InputIcon class="pi pi-search"/>
              <InputText id="task_search" v-model="filters['global'].value" autocomplete="on" size="small"/>
            </IconField>
            <label for="task_search">搜索任务</label>
          </FloatLabel>
          <Button icon="pi pi-filter" aria-label="filter" severity="secondary" variant="outlined" size="small"/>
        </div>
      </div>
    </template>
    <template #empty>
      <div class="text-center py-4">
        <i class="pi pi-inbox text-4xl text-gray-400 mb-4 block"></i>
        <p class="text-gray-500">暂无任务数据</p>
      </div>
    </template>
    <template #loading>
      <div class="text-center py-4">
        <i class="pi pi-spin pi-spinner text-2xl text-blue-500 mb-2 block"></i>
        <p>加载任务数据中...</p>
      </div>
    </template>
    <template #groupheader="{data, frozenRow}">
      <div class="flex items-center gap-2" v-if="!frozenRow">
        <Tag class="font-bold px-5 py-2">
          <i class="pi pi-folder text-sm mr-1"></i>
          {{ catalog_config[data.catalog_id]?.space_name }} /
          {{ catalog_config[data.catalog_id]?.catalog_name }}
        </Tag>
      </div>
    </template>

    <Column selectionMode="multiple" headerStyle="width: 3rem"></Column>

    <Column field="name" sortable header="任务名称">
      <template #body="{ data }">
        <span @click="displayPopover($event, data, name_popover)"
              v-tooltip.top="'点击查看详情'"
              class="cursor-pointer text-blue-700 hover:text-blue-500 hover:underline">
          {{ data.name }}
        </span>
      </template>
    </Column>

    <Column field="task_type" sortable header="任务类型">
      <template #body="{ data }">
        <Tag :value="data.task_type"
             :severity="getTaskTypeSeverity(data.task_type)"
             class="text-xs">
          {{
            data.task_type === 'disposable' ? '一次性' :
                data.task_type === 'periodic' ? '周期性' :
                    data.task_type === 'dependent' ? '依赖性' : data.task_type
          }}
        </Tag>
      </template>
    </Column>

    <Column field="status" sortable header="状态">
      <template #body="{ data }">
        <Tag :value="data.status"
             :severity="getStatusSeverity(data.status)"
             class="text-xs">
          {{
            data.status === 'pending' ? '待执行' :
                data.status === 'running' ? '执行中' :
                    data.status === 'completed' ? '已完成' :
                        data.status === 'failed' ? '执行失败' : data.status
          }}
        </Tag>
      </template>
    </Column>

    <Column field="effective_time" sortable header="生效时间">
      <template #body="{ data }">
        <span class="text-sm">{{ formatDateTime(data.effective_time) }}</span>
      </template>
    </Column>

    <Column field="cron_expression" header="定时表达式">
      <template #body="{ data }">
        <span v-if="data.task_type === 'periodic'"
              class="text-sm font-mono bg-gray-100 px-2 py-1 rounded">
          {{ data.cron_expression || '-' }}
        </span>
        <span v-else class="text-gray-400 text-sm">-</span>
      </template>
    </Column>

    <Column field="priority" sortable header="优先级">
      <template #body="{ data }">
        <div class="flex items-center gap-1">
          <i class="pi pi-arrow-up text-xs"
             :class="data.priority > 0 ? 'text-red-500' : 'text-gray-300'"></i>
          <span class="text-sm">{{ data.priority || 0 }}</span>
        </div>
      </template>
    </Column>

    <Column field="created_at" sortable header="创建时间">
      <template #body="{ data }">
        <span class="text-sm text-gray-600">{{ formatDateTime(data.created_at) }}</span>
      </template>
    </Column>

    <Column field="actions" header="操作" header-class="text-center" body-class="text-center">
      <template #body="{ data, frozenRow, index }">
        <div class="inline-flex gap-1 items-center justify-center">
          <!-- 激活/暂停按钮 -->
          <Button v-if="data.status === 'paused'"
                  icon="pi pi-play-circle"
                  text
                  severity="success"
                  v-tooltip.top="'激活任务'"
                  :loading="activating_tasks.has(data.task_id)"
                  @click="activateTask(data.task_id)"
                  size="small"/>
          <Button v-else-if="data.status === 'active'"
                  icon="pi pi-pause-circle"
                  text
                  severity="warning"
                  v-tooltip.top="'暂停任务'"
                  :loading="activating_tasks.has(data.task_id)"
                  @click="deactivateTask(data.task_id)"
                  size="small"/>

          <!-- 立即执行按钮 (仅在active状态显示) -->
          <Button v-if="data.status === 'active'"
                  icon="pi pi-forward"
                  text
                  severity="info"
                  v-tooltip.top="'立即执行'"
                  :disabled="data.status === 'running'"
                  @click="showExecuteDialog(data)"
                  size="small"/>

          <Button icon="pi pi-info-circle"
                  text
                  severity="secondary"
                  v-tooltip.top="'检查执行条件'"
                  @click="checkTaskExecutable(data.task_id)"
                  size="small"/>
          <Button icon="pi pi-pencil"
                  text
                  severity="secondary"
                  v-tooltip.top="'编辑任务'"
                  @click="$router.push({path: '/task/edit', query: { id: data.id } })"
                  size="small"/>
          <Button icon="pi pi-external-link"
                  text
                  severity="secondary"
                  v-tooltip.top="'查看关联流程'"
                  @click="$router.push({path: '/flows/edit', query: { id: data.flow_id } })"
                  size="small"/>
          <Button type="button"
                  :icon="frozenRow ? 'pi pi-lock-open' : 'pi pi-lock'"
                  :disabled="frozenRow ? false : locked_rows.length >= 3"
                  text
                  severity="secondary"
                  v-tooltip.top="frozenRow ? '解锁行' : '锁定行'"
                  size="small"
                  @click="toggleLock(data, frozenRow, index)"/>
        </div>
      </template>
    </Column>
  </DataTable>

  <!-- 任务详情弹窗 -->
  <Popover ref="name_popover">
    <div class="flex flex-col gap-3 p-4 min-w-80">
      <div class="border-b pb-2 mb-2">
        <h3 class="font-bold text-lg">{{ view_row?.name }}</h3>
        <p class="text-sm text-gray-600">{{ view_row?.description }}</p>
      </div>

      <div class="grid grid-cols-2 gap-2 text-sm">
        <div class="flex items-center gap-2">
          <span class="font-semibold">任务ID:</span>
          <span class="font-mono bg-gray-100 px-2 py-1 rounded text-xs">{{ view_row?.task_id }}</span>
          <Button icon="pi pi-copy" text size="small"
                  @click="clipboard(view_row?.task_id, toast)"/>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">流程ID:</span>
          <span class="font-mono bg-gray-100 px-2 py-1 rounded text-xs">{{ view_row?.flow_id }}</span>
          <Button icon="pi pi-copy" text size="small"
                  @click="clipboard(view_row?.flow_id, toast)"/>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">任务类型:</span>
          <Tag :value="view_row?.task_type"
               :severity="getTaskTypeSeverity(view_row?.task_type)"
               class="text-xs"/>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">状态:</span>
          <Tag :value="view_row?.status"
               :severity="getStatusSeverity(view_row?.status)"
               class="text-xs"/>
        </div>

        <div class="col-span-2 flex items-center gap-2" v-if="view_row?.effective_time">
          <span class="font-semibold">生效时间:</span>
          <span>{{ formatDateTime(view_row?.effective_time) }}</span>
        </div>

        <div class="col-span-2 flex items-center gap-2" v-if="view_row?.lose_efficacy_time">
          <span class="font-semibold">失效时间:</span>
          <span>{{ formatDateTime(view_row?.lose_efficacy_time) }}</span>
        </div>

        <div class="col-span-2 flex items-center gap-2" v-if="view_row?.cron_expression">
          <span class="font-semibold">Cron表达式:</span>
          <span class="font-mono bg-gray-100 px-2 py-1 rounded">{{ view_row?.cron_expression }}</span>
        </div>
      </div>
    </div>
  </Popover>

  <!-- 参数详情弹窗 -->
  <Popover ref="params_popover" class="w-auto">
    <div class="flex flex-col gap-2 p-3">
      <h4 class="font-bold mb-2">任务参数</h4>
      <div class="flex items-center justify-between gap-4"
           v-for="(value, key) in view_row?.params" :key="key">
        <span class="font-semibold text-sm">{{ key }}:</span>
        <span class="text-sm bg-gray-100 px-2 py-1 rounded">{{ value }}</span>
      </div>
      <div v-if="!view_row?.params || Object.keys(view_row?.params).length === 0"
           class="text-gray-500 text-center py-2">
        <i class="pi pi-info-circle mr-2"></i>
        <span>暂无参数配置</span>
      </div>
    </div>
  </Popover>

  <!-- 状态详情弹窗 -->
  <Popover ref="status_popover">
    <div class="flex flex-col gap-2 p-3">
      <h4 class="font-bold mb-2">状态详情</h4>
      <div class="text-sm space-y-1">
        <div><strong>当前状态:</strong> {{ view_row?.status }}</div>
        <div><strong>创建时间:</strong> {{ formatDateTime(view_row?.created_at) }}</div>
        <div><strong>更新时间:</strong> {{ formatDateTime(view_row?.updated_at) }}</div>
      </div>
    </div>
  </Popover>

  <!-- 立即执行对话框 -->
  <Dialog v-model:visible="show_execute_dialog"
          modal
          :header="selected_execute_tasks ? `批量立即执行 - ${selected_execute_tasks.length} 个任务` : `立即执行 - ${selected_execute_task?.name}`"
          :style="{ width: '600px' }"
          @hide="hideExecuteDialog">
    <TaskExecuteDialog
        v-if="show_execute_dialog && (selected_execute_task || selected_execute_tasks)"
        :task="selected_execute_task"
        :tasks="selected_execute_tasks"
        @execute="handleExecuteTask"
        @close="hideExecuteDialog"/>
  </Dialog>

  <!-- 确认对话框 -->
  <ConfirmDialog/>
</template>

<style scoped>

</style>
