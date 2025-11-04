<script setup lang="ts">
import { computed, ref } from 'vue'
import Button from 'primevue/button'
import { useToast } from 'primevue/usetoast'
import { useMetricsStore } from "@/stores/metrics";

// 单个触发条件的结构
export interface TriggerCondition {
  id: number
  type: 'condition' | 'group' // 条件或条件组
  metricType?: 'numeric' | 'string' // 指标类型（仅用于条件）
  metric?: string // 触发指标（仅用于条件）
  operator?: string // 操作符（仅用于条件）
  value?: number | string // 触发值（仅用于条件）
  logic?: 'AND' | 'OR' // 条件组的逻辑关系（仅用于条件组）
  children?: TriggerCondition[] // 子条件（仅用于条件组）
}

interface Props {
  group: TriggerCondition
  level?: number
  stringMetricOptions: Array<{ label: string; value: string }>
  numericOperatorOptions: Array<{ label: string; value: string; symbol: string }>
  stringOperatorOptions: Array<{ label: string; value: string; symbol: string }>
}

const props = withDefaults(defineProps<Props>(), {
  level: 0
})

const emit = defineEmits<{
  remove: [conditionId: number]
  addCondition: [group: TriggerCondition]
  addGroup: []
  edit: [condition: TriggerCondition]
  toggleLogic: [group: TriggerCondition]
}>()

const toast = useToast()
const {metrics} = storeToRefs(useMetricsStore())
const {getMetricName} = useMetricsStore()
// 数值指标选项（从 API 加载）
const numericMetricOptions = computed(() => {
  return unref(metrics).map(m => ({
    label: m.display_name,
    value: m.key,
    unit: m.unit
  }))
})

// 合并所有指标选项
const allMetricOptions = computed(() => [...numericMetricOptions.value, ...props.stringMetricOptions])
const allOperatorOptions = [...props.numericOperatorOptions, ...props.stringOperatorOptions]

// 获取指标显示文本
const getMetricLabel = (metricValue?: string) => {
  return allMetricOptions.value.find(m => m.value === metricValue)?.label || metricValue
}

// 获取操作符符号
const getOperatorSymbol = (operatorValue?: string) => {
  return allOperatorOptions.find(o => o.value === operatorValue)?.symbol || operatorValue
}

// 获取条件值显示文本
const getConditionValueText = (condition: TriggerCondition) => {
  if (condition.metricType === 'numeric') {
    const metric = numericMetricOptions.value.find(m => m.value === condition.metric)
    return `${condition.value}${metric?.unit || ''}`
  } else {
    return `"${condition.value}"`
  }
}

// 判断是否有多个子项
const hasMultipleChildren = (group: TriggerCondition) => {
  return group.children && group.children.length > 1
}
</script>

<template>
  <div :class="level > 0 ? 'relative' : ''">
    <!-- 左侧竖线 -->
    <div v-if="level > 0" class="absolute top-0 bottom-0 w-px bg-gray-300"></div>

    <!-- 内容容器 -->
    <div :class="level > 0 ? 'pl-2' : ''">
      <!-- 子条件和子条件组 -->
      <template v-if="group.children && group.children.length > 0">
        <template v-for="(child, index) in group.children" :key="child.id">
          <!-- 单个条件 -->
          <div v-if="child.type === 'condition'" class="flex items-center gap-2 py-1">
            <!-- 逻辑标签（只在第一项且有多个子项时显示） -->
            <div
              v-if="hasMultipleChildren(group) && index === 0"
              class="px-2 py-1 rounded text-xs cursor-pointer w-9 text-center bg-gray-100 text-gray-600 hover:bg-gray-200"
              @click="emit('toggleLogic', group)"
            >
              {{ group.logic === 'AND' ? '且' : '或' }}
            </div>
            <div v-else class="w-9"></div>

            <!-- 编辑按钮 -->
            <Button
              icon="pi pi-filter-slash"
              size="small"
              severity="secondary"
              outlined
              class="h-7 w-16 text-xs p-0 flex-shrink-0"
              @click="emit('edit', child)"
            />

            <!-- 条件显示 -->
            <div class="flex items-center gap-2 px-3 py-1.5 bg-white border border-gray-200 rounded text-sm flex-1">
              <span class="text-gray-700">
                {{ getMetricName(child.metric) }}
                {{ getOperatorSymbol(child.operator) }}
                {{ getConditionValueText(child) }}
              </span>
            </div>

            <!-- 删除按钮 -->
            <Button
              icon="pi pi-times"
              size="small"
              severity="secondary"
              text
              class="h-6 w-6 p-0"
              @click="emit('remove', child.id)"
            />
          </div>

          <!-- 条件组（递归） -->
          <div v-else class="flex items-start gap-2 py-1">
            <!-- 逻辑标签（只在第一项且有多个子项时显示） -->
            <div
              v-if="hasMultipleChildren(group) && index === 0"
              class="px-2 py-1 rounded text-xs cursor-pointer w-9 text-center bg-gray-100 text-gray-600 hover:bg-gray-200 flex-shrink-0"
              @click="emit('toggleLogic', group)"
            >
              {{ group.logic === 'AND' ? '且' : '或' }}
            </div>
            <div v-else class="w-9 flex-shrink-0"></div>

            <!-- 子条件组内容 -->
            <div class="flex-1">
              <ConditionGroupDisplay
                :group="child"
                :level="level + 1"
                :stringMetricOptions="stringMetricOptions"
                :numericOperatorOptions="numericOperatorOptions"
                :stringOperatorOptions="stringOperatorOptions"
                @remove="emit('remove', $event)"
                @add-condition="emit('addCondition', $event)"
                @add-group="emit('addGroup')"
                @edit="emit('edit', $event)"
                @toggle-logic="emit('toggleLogic', $event)"
              />
            </div>
          </div>
        </template>
      </template>

      <!-- 空状态 -->
      <div v-else class="text-sm text-gray-400 py-2 ml-11">
        暂无条件
      </div>

      <!-- 底部添加按钮 -->
      <div class="flex gap-2 py-2 ml-11">
        <Button
          icon="pi pi-plus"
          label="添加条件"
          size="small"
          severity="secondary"
          outlined
          class="h-8 px-4 text-sm"
          @click="emit('addCondition', group)"
        />
        <Button
          v-if="level === 0"
          icon="pi pi-sitemap"
          label="添加条件组"
          size="small"
          severity="secondary"
          outlined
          class="h-8 px-4 text-sm"
          @click="emit('addGroup')"
        />
        <Button
          v-if="level > 0"
          icon="pi pi-trash"
          label="删除组"
          size="small"
          severity="secondary"
          text
          class="h-8 text-sm"
          @click="emit('remove', group.id)"
        />
      </div>
    </div>
  </div>
</template>
