<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'

const toast = useToast()
const props = defineProps<{
  task?: any
  tasks?: any[]
}>()

const emit = defineEmits(['execute', 'close'])

const executionParams = ref({
  task_ids: [] as string[],
  execution_type: 'single_date', // single_date, multiple_dates, date_range
  single_date: null,
  multiple_dates: [],
  range_dates: null,
  execute_dependencies: false,
  execution_time_type: 'now', // now, delayed
  delay_time: null
})

// 初始化任务ID列表 - 支持单个任务或多个任务
if (props.tasks && props.tasks.length > 0) {
  executionParams.value.task_ids = props.tasks.map(task => task.task_id || task.id)
} else if (props.task) {
  executionParams.value.task_ids = [props.task.task_id || props.task.id]
}

const tabs = [
  { label: '按日期执行', value: 'single_date' },
  { label: '按多日期执行', value: 'multiple_dates' },
  { label: '按时间区间执行', value: 'date_range' }
]

// 当前日期时间（用于最小值限制）
const now = new Date()

const minDelayTime = computed(() => {
  const future = new Date(now.getTime() + 60 * 1000) // 至少1分钟后
  return future.toISOString().slice(0, 16)
})

watch()

// 验证表单
const validateForm = () => {
  const params = executionParams.value

  if (params.task_ids.length === 0) {
    toast.add({
      severity: 'error',
      summary: '验证失败',
      detail: '没有可执行的任务',
      life: 3000
    })
    return false
  }

  switch (params.execution_type) {
    case 'single_date':
      if (!params.single_date) {
        toast.add({
          severity: 'error',
          summary: '验证失败',
          detail: '请选择执行日期',
          life: 3000
        })
        return false
      }
      break
    case 'multiple_dates':
      if (!params.multiple_dates || params.multiple_dates.length === 0) {
        toast.add({
          severity: 'error',
          summary: '验证失败',
          detail: '请至少选择一个执行日期',
          life: 3000
        })
        return false
      }
      break
    case 'date_range':
      if (!params.range_dates || !Array.isArray(params.range_dates) || params.range_dates.length !== 2) {
        toast.add({
          severity: 'error',
          summary: '验证失败',
          detail: '请选择完整的时间区间',
          life: 3000
        })
        return false
      }
      if (new Date(params.range_dates[0]) >= new Date(params.range_dates[1])) {
        toast.add({
          severity: 'error',
          summary: '验证失败',
          detail: '结束时间必须大于开始时间',
          life: 3000
        })
        return false
      }
      break
  }

  if (params.execution_time_type === 'delayed') {
    if (!params.delay_time) {
      toast.add({
        severity: 'error',
        summary: '验证失败',
        detail: '请选择延迟执行时间',
        life: 3000
      })
      return false
    }
    if (new Date(params.delay_time) <= now) {
      toast.add({
        severity: 'error',
        summary: '验证失败',
        detail: '延迟时间必须大于当前时间',
        life: 3000
      })
      return false
    }
  }

  return true
}

// 提交执行
const handleSubmit = () => {
  if (!validateForm()) {
    return
  }

  const submitData = { ...executionParams.value }

  // 根据执行类型清理不需要的参数
  switch (submitData.execution_type) {
    case 'single_date':
      delete submitData.multiple_dates
      delete submitData.range_dates
      break
    case 'multiple_dates':
      delete submitData.single_date
      delete submitData.range_dates
      break
    case 'date_range':
      delete submitData.single_date
      delete submitData.multiple_dates
      // 将范围日期转换为开始和结束时间
      if (submitData.range_dates && submitData.range_dates.length === 2) {
        submitData.date_range_start = submitData.range_dates[0]
        submitData.date_range_end = submitData.range_dates[1]
      }
      delete submitData.range_dates
      break
  }

  if (submitData.execution_time_type === 'now') {
    delete submitData.delay_time
  }

  emit('execute', submitData)
}
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- 任务信息 -->
    <div class="bg-gray-50 p-3 rounded-lg">
      <h4 class="font-semibold mb-2">任务信息</h4>
      <div v-if="task && !tasks" class="grid grid-cols-2 gap-2 text-sm">
        <div><span class="font-medium">任务名称:</span> {{ task.name }}</div>
        <div><span class="font-medium">任务ID:</span> {{ task.task_id }}</div>
        <div><span class="font-medium">任务类型:</span> {{ task.task_type }}</div>
        <div><span class="font-medium">当前状态:</span> {{ task.status }}</div>
      </div>
      <div v-else-if="tasks && tasks.length > 0" class="text-sm">
        <div><span class="font-medium">批量执行任务:</span> {{ tasks.length }} 个任务</div>
        <div class="mt-2 max-h-20 overflow-y-auto">
          <div v-for="(task, index) in tasks" :key="index" class="text-xs text-gray-600">
            {{ index + 1 }}. {{ task.name }} ({{ task.task_id }})
          </div>
        </div>
      </div>
    </div>

    <!-- 执行方式选择 -->
    <div>
      <h4 class="font-semibold mb-3">执行方式</h4>
      <Tabs v-model:value="executionParams.execution_type">
        <TabList>
          <Tab v-for="tab in tabs" :key="tab.label" :value="tab.value">
            {{ tab.label }}
          </Tab>
        </TabList>
        <TabPanels>
          <!-- 按日期执行 -->
          <TabPanel value="single_date">
            <div class="flex flex-col gap-3 pt-4">
              <FloatLabel variant="on">
                <DatePicker id="single_date"
                           v-model="executionParams.single_date"
                           dateFormat="yy-mm-dd"
                           :manualInput="false"
                           class="w-full" />
                <label for="single_date">选择执行日期和时间</label>
              </FloatLabel>
            </div>
          </TabPanel>

          <!-- 按多日期执行 -->
          <TabPanel value="multiple_dates">
            <div class="flex flex-col gap-3 pt-4">
              <FloatLabel variant="on">
                <DatePicker id="multiple_dates"
                           v-model="executionParams.multiple_dates"
                           selectionMode="multiple"
                           dateFormat="yy-mm-dd"
                           :manualInput="false"
                           class="w-full" />
                <label for="multiple_dates">选择多个执行日期</label>
              </FloatLabel>
              <div class="text-sm text-gray-600 bg-blue-50 p-2 rounded">
                <i class="pi pi-info-circle mr-1"></i>
                可以选择多个日期，系统将在每个选定的日期执行任务
              </div>
            </div>
          </TabPanel>

          <!-- 按时间区间执行 -->
          <TabPanel value="date_range">
            <div class="flex flex-col gap-3 pt-4">
              <FloatLabel variant="on">
                <DatePicker id="range_dates"
                           v-model="executionParams.range_dates"
                           selectionMode="range"
                           dateFormat="yy-mm-dd"
                           :manualInput="false"
                           class="w-full" />
                <label for="range_dates">选择时间区间</label>
              </FloatLabel>
              <div class="text-sm text-gray-600 bg-blue-50 p-2 rounded">
                <i class="pi pi-info-circle mr-1"></i>
                系统将在指定时间区间内按照任务的原定计划执行
              </div>
            </div>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>

    <!-- 执行选项 -->
    <div>
      <h4 class="font-semibold mb-3">执行选项</h4>

      <!-- 依赖任务选项 -->
      <div class="flex items-center gap-3 mb-3">
        <Checkbox id="execute_dependencies"
                 v-model="executionParams.execute_dependencies"
                 :binary="true" />
        <label for="execute_dependencies" class="font-medium">执行依赖任务</label>
        <i class="pi pi-info-circle text-gray-400"
           v-tooltip="'勾选后将同时执行该任务的所有依赖任务'"></i>
      </div>

      <!-- 执行时间选项 -->
      <div class="flex flex-col gap-3">
        <label class="font-medium">执行时间</label>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <RadioButton id="now"
                        v-model="executionParams.execution_time_type"
                        value="now" />
            <label for="now">立即执行</label>
          </div>
          <div class="flex items-center gap-2">
            <RadioButton id="delayed"
                        v-model="executionParams.execution_time_type"
                        value="delayed" />
            <label for="delayed">延迟执行</label>
          </div>
        </div>

        <div v-if="executionParams.execution_time_type === 'delayed'"
             class="ml-6">
          <FloatLabel variant="on">
            <DatePicker id="delay_time"
                       v-model="executionParams.delay_time"
                       showTime
                       hourFormat="24"
                       :minDate="new Date(minDelayTime)"
                       dateFormat="yy-mm-dd"
                       :manualInput="false"
                       class="w-full" />
            <label for="delay_time">延迟时间 (必须大于当前时间)</label>
          </FloatLabel>
        </div>
      </div>
    </div>

    <!-- 操作按钮 -->
    <div class="flex items-center justify-end gap-2 pt-4 border-t">
      <Button label="取消"
             severity="secondary"
             variant="outlined"
             @click="emit('close')" />
      <Button label="提交执行"
             severity="primary"
             @click="handleSubmit" />
    </div>
  </div>
</template>

<style scoped>
.p-tabs :deep(.p-tabpanels) {
  padding: 0;
}
</style>
