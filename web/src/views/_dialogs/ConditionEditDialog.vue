<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Select from 'primevue/select'
import FloatLabel from 'primevue/floatlabel'
import metricsApi from '@/api/metrics-api'
import type { Metric } from '@/data/types/ads-types'
import type { TriggerCondition } from './ConditionGroupDisplay.vue'

interface Props {
  visible: boolean
  condition?: TriggerCondition | null
  isEdit?: boolean
  targetGroup?: TriggerCondition | null
  stringMetricOptions: Array<{ label: string; value: string; type: string }>
  numericOperatorOptions: Array<{ label: string; value: string; symbol: string; type: string }>
  stringOperatorOptions: Array<{ label: string; value: string; symbol: string; type: string }>
  availableAccountNames?: string[]
  availableCampaignNames?: string[]
  availableAdsetNames?: string[]
  availableAdNames?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  condition: null,
  isEdit: false,
  targetGroup: null,
  availableAccountNames: () => [],
  availableCampaignNames: () => [],
  availableAdsetNames: () => [],
  availableAdNames: () => []
})

const emit = defineEmits<{
  'update:visible': [value: boolean]
  save: [condition: TriggerCondition]
}>()

const toast = useToast()

// 指标数据
const metrics = ref<Metric[]>([])
const loadingMetrics = ref(false)

// 数值指标选项（从 API 加载）
const numericMetricOptions = computed(() => {
  return metrics.value.map(m => ({
    label: m.name_cn,
    value: m.name_en,
    unit: m.unit,
    min: 0,
    max: m.unit === '%' ? 100 : (m.unit === '$' || m.unit === '¥' ? 100000 : 999999999),
    type: 'numeric',
    id: m.id,
    color: m.color
  }))
})

// 合并所有指标选项
const allMetricOptions = computed(() => [...numericMetricOptions.value, ...props.stringMetricOptions])

// 当前编辑的条件
const currentCondition = ref<TriggerCondition>({
  id: Date.now(),
  type: 'condition',
  metricType: 'numeric',
  metric: '',
  operator: 'gt',
  value: 0
})

// 加载指标数据
const loadMetrics = async () => {
  if (metrics.value.length > 0) return

  loadingMetrics.value = true
  try {
    const response = await metricsApi.list()
    metrics.value = response.metrics || []
  } catch (err) {
    console.error('加载指标失败:', err)
    toast.add({ severity: 'error', summary: '错误', detail: '加载指标失败', life: 3000 })
  } finally {
    loadingMetrics.value = false
  }
}

onMounted(() => {
  loadMetrics()
})

// 监听 visible 变化，打开时初始化
watch(() => props.visible, (visible) => {
  if (visible) {
    if (props.isEdit && props.condition) {
      // 编辑模式：复制条件数据
      currentCondition.value = {
        id: props.condition.id,
        type: props.condition.type,
        metricType: props.condition.metricType,
        metric: props.condition.metric,
        operator: props.condition.operator,
        value: props.condition.value
      }
    } else {
      // 新建模式：重置为默认值
      const defaultMetric = numericMetricOptions.value[0]?.value || ''
      currentCondition.value = {
        id: Date.now(),
        type: 'condition',
        metricType: 'numeric',
        metric: defaultMetric,
        operator: 'gt',
        value: 0
      }
    }
  }
})

// 计算属性：当前条件选中的指标信息
const currentSelectedMetric = computed(() => {
  return allMetricOptions.value.find(m => m.value === currentCondition.value.metric)
})

// 计算属性：当前条件的操作符选项
const currentOperatorOptions = computed(() => {
  return currentCondition.value.metricType === 'numeric'
    ? props.numericOperatorOptions
    : props.stringOperatorOptions
})

// 计算属性：是否显示下拉选择（等于/不等于操作符）
const shouldShowDropdown = computed(() => {
  return currentCondition.value.metricType === 'string' &&
    (currentCondition.value.operator === 'equals' || currentCondition.value.operator === 'not_equals')
})

// 计算属性：根据指标类型获取可选值
const availableValues = computed(() => {
  if (!shouldShowDropdown.value) return []

  switch (currentCondition.value.metric) {
    case 'account_name':
      return props.availableAccountNames
    case 'campaign_name':
      return props.availableCampaignNames
    case 'adset_name':
      return props.availableAdsetNames
    case 'ad_name':
      return props.availableAdNames
    default:
      return []
  }
})

// 当指标类型改变时，更新操作符和值
const onMetricTypeChange = (newType: 'numeric' | 'string') => {
  currentCondition.value.metricType = newType
  // 重置操作符
  if (newType === 'numeric') {
    currentCondition.value.metric = numericMetricOptions.value[0]?.value || ''
    currentCondition.value.operator = 'gt'
    currentCondition.value.value = 0
  } else {
    currentCondition.value.metric = 'account_name'
    currentCondition.value.operator = 'contains'
    currentCondition.value.value = ''
  }
}

// 当指标改变时，重置操作符
const onMetricChange = () => {
  const metric = allMetricOptions.value.find(m => m.value === currentCondition.value.metric)
  if (metric?.type === 'numeric') {
    currentCondition.value.metricType = 'numeric'
    currentCondition.value.operator = 'gt'
    currentCondition.value.value = 0
  } else {
    currentCondition.value.metricType = 'string'
    currentCondition.value.operator = 'contains'
    currentCondition.value.value = ''
  }
}

// 关闭对话框
const handleClose = () => {
  emit('update:visible', false)
}

// 保存条件
const handleSave = () => {
  // 验证
  if (currentCondition.value.metricType === 'numeric') {
    const metric = numericMetricOptions.value.find(m => m.value === currentCondition.value.metric)
    const val = Number(currentCondition.value.value)
    if (metric && (val < metric.min || val > metric.max)) {
      toast.add({
        severity: 'warn',
        summary: '提示',
        detail: `${metric.label}的值应该在 ${metric.min} 到 ${metric.max} 之间`,
        life: 3000
      })
      return
    }
  } else {
    if (!currentCondition.value.value || currentCondition.value.value === '') {
      toast.add({ severity: 'warn', summary: '提示', detail: '请输入或选择条件值', life: 3000 })
      return
    }
  }

  // 触发保存事件
  emit('save', { ...currentCondition.value })
  emit('update:visible', false)
}
</script>

<template>
  <Dialog
    :visible="visible"
    modal
    :header="isEdit ? '编辑条件' : '添加条件'"
    :style="{ width: '700px' }"
    :dismissableMask="true"
    @update:visible="emit('update:visible', $event)"
  >
    <div class="space-y-4">
      <!-- 指标类型选择 -->
      <div class="grid grid-cols-2 gap-2">
        <Button
          label="数值指标"
          :severity="currentCondition.metricType === 'numeric' ? 'primary' : 'secondary'"
          @click="onMetricTypeChange('numeric')"
          size="small"
        />
        <Button
          label="字符串指标"
          :severity="currentCondition.metricType === 'string' ? 'primary' : 'secondary'"
          @click="onMetricTypeChange('string')"
          size="small"
        />
      </div>

      <!-- 3个输入框并排 -->
      <div class="grid grid-cols-3 gap-3">
        <!-- 指标选择 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">指标</label>
          <!-- 数值指标：使用 Select 组件支持搜索和颜色显示 -->
          <Select
            v-if="currentCondition.metricType === 'numeric'"
            v-model="currentCondition.metric"
            :options="numericMetricOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择指标"
            filter
            :loading="metricsStore.loading"
            class="w-full"
            @change="onMetricChange"
          >
            <template #option="slotProps">
              <div class="flex items-center gap-2">
                <div
                  class="w-3 h-3 rounded-full flex-shrink-0"
                  :style="{ backgroundColor: slotProps.option.color }"
                ></div>
                <span>{{ slotProps.option.label }}</span>
              </div>
            </template>
            <template #value="slotProps">
              <div v-if="slotProps.value" class="flex items-center gap-2">
                <div
                  class="w-3 h-3 rounded-full flex-shrink-0"
                  :style="{ backgroundColor: numericMetricOptions.find(m => m.value === slotProps.value)?.color }"
                ></div>
                <span>{{ slotProps.placeholder }}</span>
              </div>
              <span v-else>{{ slotProps.placeholder }}</span>
            </template>
          </Select>
          <!-- 字符串指标：使用 Dropdown -->
          <Dropdown
            v-else
            v-model="currentCondition.metric"
            :options="stringMetricOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择指标"
            class="w-full"
            @change="onMetricChange"
          />
        </div>

        <!-- 操作符选择 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">操作符</label>
          <Dropdown
            v-model="currentCondition.operator"
            :options="currentOperatorOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择操作符"
            class="w-full"
          >
            <template #option="slotProps">
              <span>{{ slotProps.option.label }} ({{ slotProps.option.symbol }})</span>
            </template>
          </Dropdown>
        </div>

        <!-- 值输入 -->
        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">值</label>

          <!-- 数值输入 -->
          <div v-if="currentCondition.metricType === 'numeric'" class="flex items-center gap-1">
            <InputNumber
              v-model="currentCondition.value"
              :min="currentSelectedMetric?.min"
              :max="currentSelectedMetric?.max"
              :minFractionDigits="0"
              :maxFractionDigits="2"
              placeholder="输入数值"
              class="flex-1"
            />
            <span v-if="currentSelectedMetric?.unit" class="text-sm text-gray-600 min-w-[24px]">
              {{ currentSelectedMetric.unit }}
            </span>
          </div>

          <!-- 字符串输入或下拉选择 -->
          <div v-else>
            <!-- 等于/不等于使用下拉选择 -->
            <Dropdown
              v-if="shouldShowDropdown"
              v-model="currentCondition.value"
              :options="availableValues"
              placeholder="选择值"
              class="w-full"
            />
            <!-- 包含/不包含使用文本输入 -->
            <InputText
              v-else
              v-model="currentCondition.value"
              placeholder="输入文本"
              class="w-full"
            />
          </div>
        </div>
      </div>

      <!-- 提示信息 -->
      <div v-if="currentCondition.metricType === 'numeric' && currentSelectedMetric" class="text-xs text-gray-500">
        提示: {{ currentSelectedMetric.label }}的有效范围是 {{ currentSelectedMetric.min }} 到 {{ currentSelectedMetric.max }}
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          label="取消"
          severity="secondary"
          @click="handleClose"
        />
        <Button
          :label="isEdit ? '保存' : '添加'"
          @click="handleSave"
        />
      </div>
    </template>
  </Dialog>
</template>
