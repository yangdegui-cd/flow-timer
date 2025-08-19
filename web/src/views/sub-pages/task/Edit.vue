<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { FtTask } from "@/data/types/type";
import { ApiGetFlowTreeList } from "@/api/flow-api";
import { ApiCreate, ApiList, ApiShow, ApiUpdate } from "@/api/base-api";
import { useToast } from "primevue/usetoast";
import { initDefaultTaskValue } from "@/data/defaults/default-values";
import PageHeader from "@/views/layer/PageHeader.vue";

const route = useRoute();
const router = useRouter();
const toast = useToast();

const task_id = computed(() => (route.query.task_id as string) || (route.query.id as string));
const flow_id = computed(() => route.query.flow_id as string);
const catalog_id = computed(() => route.query.catalog_id as string);

const is_add = computed(() => !task_id.value);
const loading = ref(false);
const loading_task = ref(false);
const loading_flows = ref(false);
const loading_spaces = ref(false);

const task = ref<FtTask>(initDefaultTaskValue());
const flow_tree = ref([]);
const spaces = ref([]);
const available_tasks = ref([]);

// 时间选择的响应式数据
const schedule_time = ref({
  hour: 0,
  minute: 0,
  day_of_week: 1, // 1=周一
  day_of_month: 1
});

// 表单验证状态
const form_errors = ref({
  name: '',
  flow_id: '',
  task_type: '',
  queue: '',
  period_type: '',
  cron_expression: '',
  dependents: ''
});

// 任务状态选项
const status_options = [
  { label: '待执行', value: 'pending' },
  { label: '运行中', value: 'running' },
  { label: '已暂停', value: 'paused' },
  { label: '已停用', value: 'inactive' }
];

// 任务类型选项
const task_type_options = [
  { label: '一次性任务', value: 'disposable' },
  { label: '周期性任务', value: 'periodic' },
  { label: '依赖性任务', value: 'dependent' }
];

// 周期类型选项
const period_type_options = [
  { label: '每小时', value: 'hourly' },
  { label: '每天', value: 'daily' },
  { label: '每周', value: 'weekly' },
  { label: '每月', value: 'monthly' },
  { label: '自定义(Cron)', value: 'cron' }
];

// 时间选择选项
const hour_options = Array.from({ length: 24 }, (_, i) => ({ label: i.toString().padStart(2, '0'), value: i }));
const minute_options = Array.from({ length: 60 }, (_, i) => ({ label: i.toString().padStart(2, '0'), value: i }));
const weekday_options = [
  { label: '周一', value: 1 },
  { label: '周二', value: 2 },
  { label: '周三', value: 3 },
  { label: '周四', value: 4 },
  { label: '周五', value: 5 },
  { label: '周六', value: 6 },
  { label: '周日', value: 0 }
];
const day_options = Array.from({ length: 31 }, (_, i) => ({ label: (i + 1).toString(), value: i + 1 }));

// 计算属性
const is_periodic_task = computed(() => task.value.task_type === 'periodic');
const is_dependent_task = computed(() => task.value.task_type === 'dependent');
const show_period_settings = computed(() => is_periodic_task.value || is_dependent_task.value);
const show_cron_expression = computed(() =>
  is_periodic_task.value && task.value.period_type
);
const show_dependency_settings = computed(() => is_dependent_task.value);

// 初始化任务数据
const initTaskData = () => {
  if (task_id.value) {
    // 编辑模式 - 加载现有任务
    loadTask();
  } else {
    // 新增模式 - 设置默认值
    task.value = initDefaultTaskValue();
    if (flow_id.value) task.value.flow_id = flow_id.value;
    if (catalog_id.value) task.value.catalog_id = catalog_id.value;
  }
};

// 加载任务数据
const loadTask = async () => {
  loading_task.value = true;
  try {
    const response = await ApiShow('ft_task', task_id.value);
    task.value = response;
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.msg || '无法加载任务数据',
      life: 3000
    });
  } finally {
    loading_task.value = false;
  }
};

// 获取流程树
const getFlowTree = async () => {
  loading_flows.value = true;
  try {
    const response = await ApiGetFlowTreeList();
    flow_tree.value = response;
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '获取流程列表失败',
      detail: error.msg || '无法获取流程数据',
      life: 3000
    });
  } finally {
    loading_flows.value = false;
  }
};

// 获取空间数据用于目录选择
const getSpaces = async () => {
  loading_spaces.value = true;
  try {
    const response = await ApiList('space', { type: 'TASK' });
    spaces.value = response;
  } catch (error) {
    console.error('获取空间数据失败:', error);
  } finally {
    loading_spaces.value = false;
  }
};

// 获取可选的依赖任务
const getAvailableTasks = async () => {
  if (!show_dependency_settings.value) return;

  try {
    // 获取同period_type的周期性或依赖性任务
    const params = {
      task_type: ['periodic', 'dependent'],
      period_type: task.value.period_type
    };

    if (task.value.period_type) {
      const response = await ApiList('ft_task', params);
      // 过滤掉当前任务
      available_tasks.value = response.filter(t => t.task_id !== task.value.task_id);
    }
  } catch (error) {
    console.error('获取可选任务失败:', error);
  }
};

// 生成基于用户选择时间的cron表达式
const generateCronFromTime = (period_type: string, hour: number = 0, minute: number = 0, day_of_week: number = 1, day_of_month: number = 1) => {
  switch (period_type) {
    case 'hourly':
      return `${minute} * * * *`; // 每小时的指定分钟
    case 'daily':
      return `${minute} ${hour} * * *`; // 每天的指定时间
    case 'weekly':
      return `${minute} ${hour} * * ${day_of_week}`; // 每周指定日的指定时间
    case 'monthly':
      return `${minute} ${hour} ${day_of_month} * *`; // 每月指定日的指定时间
    default:
      return '';
  }
};

// 解析现有cron表达式获取时间组件
const parseCronExpression = (cron: string) => {
  if (!cron) return { minute: 0, hour: 0, day_of_week: 1, day_of_month: 1 };

  const parts = cron.split(' ');
  return {
    minute: parseInt(parts[0]) || 0,
    hour: parseInt(parts[1]) || 0,
    day_of_week: parseInt(parts[4]) || 1,
    day_of_month: parseInt(parts[2]) || 1
  };
};

// 周期类型变化时的处理
const onPeriodTypeChange = () => {
  if (is_periodic_task.value && task.value.period_type && task.value.period_type !== 'cron') {
    // 解析现有cron表达式或使用默认值
    const cronData = parseCronExpression(task.value.cron_expression);
    schedule_time.value = cronData;

    // 生成初始cron表达式
    updateCronExpression();
  }

  // 如果是依赖性任务，重新加载可选任务
  if (is_dependent_task.value) {
    getAvailableTasks();
  }
};

// 更新cron表达式
const updateCronExpression = () => {
  if (is_periodic_task.value && task.value.period_type && task.value.period_type !== 'cron') {
    task.value.cron_expression = generateCronFromTime(
      task.value.period_type,
      schedule_time.value.hour,
      schedule_time.value.minute,
      schedule_time.value.day_of_week,
      schedule_time.value.day_of_month
    );
  }
};

// 从依赖任务同步参数
const syncParamsFromDependencies = async () => {
  if (!task.value.dependents?.length) return;

  try {
    const mergedParams = {};

    // 获取每个依赖任务的参数并合并
    for (const taskId of task.value.dependents) {
      const dependentTask = available_tasks.value.find(t => t.task_id === taskId);
      if (dependentTask && dependentTask.params) {
        Object.assign(mergedParams, dependentTask.params);
      }
    }

    // 将合并后的参数转换为JSON字符串
    task.value.params = JSON.stringify(mergedParams, null, 2);

    toast.add({
      severity: 'success',
      summary: '参数同步成功',
      detail: `已从 ${task.value.dependents.length} 个依赖任务同步参数`,
      life: 3000
    });
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '参数同步失败',
      detail: '无法同步依赖任务的参数',
      life: 3000
    });
  }
};

// 表单验证
const validateForm = () => {
  form_errors.value = {
    name: '',
    flow_id: '',
    task_type: '',
    queue: '',
    period_type: '',
    cron_expression: '',
    dependents: ''
  };

  let isValid = true;

  if (!task.value.name?.trim()) {
    form_errors.value.name = '任务名称不能为空';
    isValid = false;
  }

  if (!task.value.flow_id) {
    form_errors.value.flow_id = '请选择关联流程';
    isValid = false;
  }

  if (!task.value.task_type) {
    form_errors.value.task_type = '请选择任务类型';
    isValid = false;
  }

  if (!task.value.queue?.trim()) {
    form_errors.value.queue = '执行队列不能为空';
    isValid = false;
  }

  // 周期性或依赖性任务需要选择周期类型
  if (show_period_settings.value && !task.value.period_type) {
    form_errors.value.period_type = '请选择周期类型';
    isValid = false;
  }

  // 周期性任务需要cron表达式
  if (is_periodic_task.value && task.value.period_type && !task.value.cron_expression?.trim()) {
    form_errors.value.cron_expression = 'Cron表达式不能为空';
    isValid = false;
  }

  // 依赖性任务需要选择依赖任务
  if (is_dependent_task.value && (!task.value.dependents || task.value.dependents.length === 0)) {
    form_errors.value.dependents = '请选择至少一个依赖任务';
    isValid = false;
  }

  return isValid;
};

// 保存任务
const saveTask = async () => {
  if (!validateForm()) {
    toast.add({
      severity: 'warn',
      summary: '表单验证失败',
      detail: '请检查必填字段',
      life: 3000
    });
    return;
  }

  loading.value = true;
  try {
    if (is_add.value) {
      // 新增任务
      await ApiCreate('ft_task', task.value);
      toast.add({
        severity: 'success',
        summary: '创建成功',
        detail: '任务已成功创建',
        life: 3000
      });
    } else {
      // 更新任务
      await ApiUpdate('ft_task', task_id.value, task.value);
      toast.add({
        severity: 'success',
        summary: '更新成功',
        detail: '任务已成功更新',
        life: 3000
      });
    }

    // 保存成功后返回列表页
    setTimeout(() => {
      router.push('/tasks');
    }, 1500);
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: is_add.value ? '创建失败' : '更新失败',
      detail: error.msg || '操作失败，请重试',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
};

// 取消编辑
const cancelEdit = () => {
  router.push('/tasks');
};

// 监听路由参数变化
watch(() => [route.query.task_id, route.query.id, flow_id.value, catalog_id.value], () => {
  initTaskData();
}, { immediate: true });

// 组件挂载时初始化数据
onMounted(() => {
  getFlowTree();
  getSpaces();
});

// 监听任务类型和周期类型变化
watch(() => [task.value.task_type, task.value.period_type], () => {
  if (is_dependent_task.value && task.value.period_type) {
    getAvailableTasks();
  }
}, { immediate: true });
</script>

<template>
  <div class="task-edit-page w-full h-full overflow-auto">
    <div class="task-edit-container max-w-6xl mx-auto p-6 flex flex-col gap-2">
      <!-- 页面头部 -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <Button
            icon="pi pi-arrow-left"
            text
            severity="secondary"
            @click="cancelEdit"
            v-tooltip.bottom="'返回任务列表'"/>
          <div>
            <h1 class="text-2xl font-bold text-gray-800 mb-1">
              {{ is_add ? '新建任务' : '编辑任务' }}
            </h1>
            <p class="text-gray-600 text-sm">
              {{ is_add ? '创建一个新的执行任务' : '修改现有任务的配置信息' }}
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <Button
            :label="is_add ? '创建任务' : '保存修改'"
            icon="pi pi-save"
            @click="saveTask"
            :loading="loading"
            size="small"/>
          <Button
            label="取消"
            icon="pi pi-times"
            @click="cancelEdit"
            severity="secondary"
            outlined
            size="small"/>
        </div>
      </div>

      <!-- 主要内容区域 -->
      <div v-if="loading_task" class="flex items-center justify-center py-12 h-full">
        <div class="text-center">
          <i class="pi pi-spin pi-spinner text-2xl text-blue-500 mb-3 block"></i>
          <p class="text-gray-600">加载任务数据中...</p>
        </div>
      </div>

      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- 左侧主要表单 -->
        <div class="lg:col-span-2 space-y-6">
          <!-- 基本信息 -->
          <Card class="bg-surface-50">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-info-circle text-blue-500"></i>
                基本信息
              </div>
            </template>
            <template #content>
              <div class="space-y-4">
                <!-- 任务名称 -->
                <div>
                  <FloatLabel variant="on">
                    <InputText
                      id="taskName"
                      v-model="task.name"
                      :class="{ 'p-invalid': form_errors.name }"
                      class="w-full"/>
                    <label for="taskName">任务名称 *</label>
                  </FloatLabel>
                  <small v-if="form_errors.name" class="p-error">{{ form_errors.name }}</small>
                </div>

                <!-- 任务描述 -->
                <div>
                  <FloatLabel variant="on">
                    <Textarea
                      id="taskDescription"
                      v-model="task.description"
                      class="w-full"
                      rows="4"/>
                    <label for="taskDescription">任务描述</label>
                  </FloatLabel>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <!-- 关联流程 -->
                  <div>
                    <FloatLabel variant="on">
                      <Select
                        id="taskFlow"
                        v-model="task.flow_id"
                        :options="flow_tree"
                        option-value="key"
                        option-label="label"
                        option-group-label="label"
                        option-group-children="children"
                        :option-disabled="(item) => !item.key"
                        :disabled="!!flow_id || loading_flows"
                        :class="{ 'p-invalid': form_errors.flow_id }"
                        filter
                        class="w-full"/>
                      <label for="taskFlow">关联流程 *</label>
                    </FloatLabel>
                    <small v-if="form_errors.flow_id" class="p-error">{{ form_errors.flow_id }}</small>
                  </div>

                  <!-- 任务类型 -->
                  <div>
                    <FloatLabel variant="on">
                      <Select
                        id="taskType"
                        v-model="task.task_type"
                        :options="task_type_options"
                        option-value="value"
                        option-label="label"
                        :class="{ 'p-invalid': form_errors.task_type }"
                        class="w-full"/>
                      <label for="taskType">任务类型 *</label>
                    </FloatLabel>
                    <small v-if="form_errors.task_type" class="p-error">{{ form_errors.task_type }}</small>
                  </div>
                </div>

                <!-- 周期类型选择 (周期性和依赖性任务显示) -->
                <div v-if="show_period_settings" class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <FloatLabel variant="on">
                      <Select
                        id="periodType"
                        v-model="task.period_type"
                        :options="period_type_options"
                        option-value="value"
                        option-label="label"
                        :class="{ 'p-invalid': form_errors.period_type }"
                        class="w-full"
                        @change="onPeriodTypeChange"/>
                      <label for="periodType">周期类型 *</label>
                    </FloatLabel>
                    <small v-if="form_errors.period_type" class="p-error">{{ form_errors.period_type }}</small>
                  </div>
                </div>

                <!-- 时间设置 (周期性任务显示) -->
                <div v-if="is_periodic_task && task.period_type && task.period_type !== 'cron'" class="space-y-4">
                  <div class="border rounded-lg p-4 bg-blue-50">
                    <h4 class="font-medium text-blue-900 mb-3">执行时间设置</h4>

                    <!-- 每小时任务 -->
                    <div v-if="task.period_type === 'hourly'" class="grid grid-cols-1 gap-4">
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleMinute"
                            v-model="schedule_time.minute"
                            :options="minute_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleMinute">执行分钟</label>
                        </FloatLabel>
                        <small class="text-gray-500 text-xs block mt-1">每小时的第几分钟执行</small>
                      </div>
                    </div>

                    <!-- 每天任务 -->
                    <div v-if="task.period_type === 'daily'" class="grid grid-cols-2 gap-4">
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleHour"
                            v-model="schedule_time.hour"
                            :options="hour_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleHour">小时</label>
                        </FloatLabel>
                      </div>
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleMinute"
                            v-model="schedule_time.minute"
                            :options="minute_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleMinute">分钟</label>
                        </FloatLabel>
                      </div>
                    </div>

                    <!-- 每周任务 -->
                    <div v-if="task.period_type === 'weekly'" class="grid grid-cols-3 gap-4">
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleDayOfWeek"
                            v-model="schedule_time.day_of_week"
                            :options="weekday_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleDayOfWeek">星期</label>
                        </FloatLabel>
                      </div>
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleHour"
                            v-model="schedule_time.hour"
                            :options="hour_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleHour">小时</label>
                        </FloatLabel>
                      </div>
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleMinute"
                            v-model="schedule_time.minute"
                            :options="minute_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleMinute">分钟</label>
                        </FloatLabel>
                      </div>
                    </div>

                    <!-- 每月任务 -->
                    <div v-if="task.period_type === 'monthly'" class="grid grid-cols-3 gap-4">
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleDayOfMonth"
                            v-model="schedule_time.day_of_month"
                            :options="day_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleDayOfMonth">日期</label>
                        </FloatLabel>
                      </div>
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleHour"
                            v-model="schedule_time.hour"
                            :options="hour_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleHour">小时</label>
                        </FloatLabel>
                      </div>
                      <div>
                        <FloatLabel variant="on">
                          <Select
                            id="scheduleMinute"
                            v-model="schedule_time.minute"
                            :options="minute_options"
                            option-value="value"
                            option-label="label"
                            class="w-full"
                            @change="updateCronExpression"/>
                          <label for="scheduleMinute">分钟</label>
                        </FloatLabel>
                      </div>
                    </div>

                    <!-- 生成的Cron表达式预览 -->
                    <div class="mt-4 p-2 bg-white rounded border">
                      <small class="text-gray-600">生成的Cron表达式: </small>
                      <code class="font-mono text-sm bg-gray-100 px-2 py-1 rounded">{{ task.cron_expression }}</code>
                    </div>
                  </div>
                </div>

                <!-- 自定义Cron表达式 (自定义模式显示) -->
                <div v-if="is_periodic_task && task.period_type === 'cron'">
                  <FloatLabel variant="on">
                    <InputText
                      id="cronExpression"
                      v-model="task.cron_expression"
                      :class="{ 'p-invalid': form_errors.cron_expression }"
                      class="w-full"/>
                    <label for="cronExpression">自定义Cron表达式 *</label>
                  </FloatLabel>
                  <small v-if="form_errors.cron_expression" class="p-error">{{ form_errors.cron_expression }}</small>
                  <small class="text-gray-500 text-xs block mt-1">
                    格式：分 时 日 月 周，如：0 0 * * * （每天午夜执行）
                  </small>
                </div>

                <!-- 依赖任务选择 (依赖性任务显示) -->
                <div v-if="show_dependency_settings">
                  <FloatLabel variant="on">
                    <MultiSelect
                      id="dependentTasks"
                      v-model="task.dependents"
                      :options="available_tasks"
                      option-value="task_id"
                      option-label="name"
                      :class="{ 'p-invalid': form_errors.dependents }"
                      class="w-full"
                      placeholder="选择依赖任务"
                      filter>
                      <template #option="slotProps">
                        <div class="flex items-center gap-2">
                          <Tag :value="slotProps.option.task_type"
                               :severity="slotProps.option.task_type === 'periodic' ? 'success' : 'warning'"
                               class="text-xs"/>
                          <span>{{ slotProps.option.name }}</span>
                          <small class="text-gray-500 ml-2">({{ slotProps.option.period_type }})</small>
                        </div>
                      </template>
                    </MultiSelect>
                    <label for="dependentTasks">依赖任务 *</label>
                  </FloatLabel>
                  <small v-if="form_errors.dependents" class="p-error">{{ form_errors.dependents }}</small>
                  <small class="text-gray-500 text-xs block mt-1">
                    选择当前任务所依赖的其他任务，只显示相同周期类型的任务
                  </small>
                </div>
              </div>
            </template>
          </Card>

          <!-- 执行配置 -->
          <Card class="bg-surface-50">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-cog text-green-500"></i>
                执行配置
              </div>
            </template>
            <template #content>
              <div class="space-y-4">
                <!-- 执行队列 -->
                <div>
                  <FloatLabel variant="on">
                    <InputText
                      id="taskQueue"
                      v-model="task.queue"
                      :class="{ 'p-invalid': form_errors.queue }"
                      class="w-full"/>
                    <label for="taskQueue">执行队列 *</label>
                  </FloatLabel>
                  <small v-if="form_errors.queue" class="p-error">{{ form_errors.queue }}</small>
                  <small class="text-gray-500 text-xs block mt-1">指定任务执行的队列名称，如：default、high_priority</small>
                </div>


                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <!-- 优先级 -->
                  <div>
                    <FloatLabel variant="on">
                      <InputNumber
                        id="taskPriority"
                        v-model="task.priority"
                        :min="1"
                        :max="100"
                        class="w-full"/>
                      <label for="taskPriority">优先级</label>
                    </FloatLabel>
                    <small class="text-gray-500 text-xs block mt-1">1-100，数字越大优先级越高</small>
                  </div>

                  <!-- 任务状态 -->
                  <div v-if="!is_add">
                    <FloatLabel variant="on">
                      <Select
                        id="taskStatus"
                        v-model="task.status"
                        :options="status_options"
                        option-value="value"
                        option-label="label"
                        class="w-full"/>
                      <label for="taskStatus">任务状态</label>
                    </FloatLabel>
                  </div>
                </div>
              </div>
            </template>
          </Card>

          <!-- 高级配置 -->
          <Card class="bg-surface-50">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-sliders-h text-purple-500"></i>
                高级配置
              </div>
            </template>
            <template #content>
              <div class="space-y-4">
                <!-- 参数设置 -->
                <div>
                  <div class="flex items-center justify-between mb-2">
                    <label class="text-sm font-medium text-gray-700">参数设置</label>
                    <Button
                      v-if="show_dependency_settings && task.dependents?.length > 0"
                      icon="pi pi-sync"
                      text
                      size="small"
                      label="从依赖任务同步参数"
                      @click="syncParamsFromDependencies"/>
                  </div>

                  <FloatLabel variant="on">
                    <Textarea
                      id="taskParams"
                      v-model="task.params"
                      class="w-full"
                      rows="4"/>
                    <label for="taskParams">参数设置 (JSON格式)</label>
                  </FloatLabel>
                  <small class="text-gray-500 text-xs block mt-1">
                    <span v-if="show_dependency_settings">
                      依赖性任务可以从依赖任务继承参数配置
                    </span>
                    <span v-else>
                      JSON格式的任务参数配置，如：{"key": "value"}
                    </span>
                  </small>
                </div>

                <!-- 生效时间 -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <FloatLabel variant="on">
                      <Calendar
                        id="taskEffectiveTime"
                        v-model="task.effective_time"
                        showTime
                        class="w-full"/>
                      <label for="taskEffectiveTime">生效时间</label>
                    </FloatLabel>
                  </div>
                  <div>
                    <FloatLabel variant="on">
                      <Calendar
                        id="taskLoseEfficacyTime"
                        v-model="task.lose_efficacy_time"
                        showTime
                        class="w-full"/>
                      <label for="taskLoseEfficacyTime">失效时间</label>
                    </FloatLabel>
                  </div>
                </div>
              </div>
            </template>
          </Card>
        </div>

        <!-- 右侧信息面板 -->
        <div class="space-y-6">
          <!-- 操作指南 -->
          <Card class="bg-amber-200">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-question-circle text-blue-500"></i>
                操作指南
              </div>
            </template>
            <template #content>
              <div class="space-y-3 text-sm">
                <div class="flex items-start gap-2">
                  <i class="pi pi-check-circle text-green-500 mt-0.5"></i>
                  <div>
                    <p class="font-medium">必填字段</p>
                    <p class="text-gray-600">任务名称、关联流程、任务类型和执行队列为必填项</p>
                  </div>
                </div>

                <div class="flex items-start gap-2">
                  <i class="pi pi-info-circle text-blue-500 mt-0.5"></i>
                  <div>
                    <p class="font-medium">任务类型说明</p>
                    <p class="text-gray-600">
                      • 一次性任务：执行一次<br/>
                      • 周期性任务：按周期重复执行<br/>
                      • 依赖性任务：依赖其他任务完成后执行
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-2">
                  <i class="pi pi-calendar text-purple-500 mt-0.5"></i>
                  <div>
                    <p class="font-medium">周期设置</p>
                    <p class="text-gray-600">
                      • 周期性任务：设置周期类型和具体执行时间<br/>
                      • 依赖性任务：只需设置周期类型，在依赖完成后触发执行
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-2" v-if="is_dependent_task">
                  <i class="pi pi-link text-orange-500 mt-0.5"></i>
                  <div>
                    <p class="font-medium">依赖关系</p>
                    <p class="text-gray-600">依赖性任务无需Cron表达式，当所选依赖任务完成后自动触发执行</p>
                  </div>
                </div>

                <div class="flex items-start gap-2">
                  <i class="pi pi-sort-numeric-up text-indigo-500 mt-0.5"></i>
                  <div>
                    <p class="font-medium">优先级</p>
                    <p class="text-gray-600">范围1-100，数值越大优先级越高</p>
                  </div>
                </div>
              </div>
            </template>
          </Card>

          <!-- 任务统计（仅编辑模式） -->
          <Card v-if="!is_add">
            <template #title>
              <div class="flex items-center gap-2">
                <i class="pi pi-chart-bar text-green-500"></i>
                任务统计
              </div>
            </template>
            <template #content>
              <div class="space-y-3">
                <div class="flex justify-between items-center">
                  <span class="text-gray-600">创建时间</span>
                  <span class="font-mono text-sm">{{ task.created_at }}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-gray-600">最后更新</span>
                  <span class="font-mono text-sm">{{ task.updated_at }}</span>
                </div>
                <Divider />
                <div class="flex justify-between items-center">
                  <span class="text-gray-600">任务ID</span>
                  <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded">{{ task.task_id }}</span>
                </div>
              </div>
            </template>
          </Card>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 简洁的页面样式 */
.task-edit-page {
  min-height: 100vh;
  background-color: var(--p-surface-ground);
}

.task-edit-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
}

/* 响应式布局 */
@media (max-width: 768px) {
  .task-edit-container {
    padding: 1rem;
  }
}
</style>
