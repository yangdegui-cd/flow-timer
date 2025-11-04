<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useMetricsStore } from '@/stores/metrics'
import { storeToRefs } from 'pinia'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Checkbox from 'primevue/checkbox'
import RadioButton from 'primevue/radiobutton'
import draggable from 'vuedraggable'
import type { AdsMetric } from '@/data/types/ads-types'

interface Props {
  modelValue: string[] | string | null
  label?: string
  disabled?: boolean
  multiple?: boolean
  size?: 'small' | 'large' | undefined
}

const props = withDefaults(defineProps<Props>(), {
  label: '设置指标',
  disabled: false,
  multiple: false,
  size: undefined
})

const emit = defineEmits<{
  'update:modelValue': [value: string[] | string]
}>()

const { metrics, loading } = storeToRefs(useMetricsStore())

// 对话框状态
const visible = ref(false)

// 搜索关键词
const searchKeyword = ref('')


// 临时选中的指标键列表
const tempSelectedKeys = ref<string[]>([])

// 临时选中的指标对象列表（用于拖拽排序）
const tempSelectedMetrics = ref<AdsMetric[]>([])

// 更新临时选中的指标对象列表
const updateTempSelectedMetrics = () => {
  tempSelectedMetrics.value = tempSelectedKeys.value
    .map(key => metrics.value.find(m => m.key === key))
    .filter(m => m !== undefined) as AdsMetric[]
}

// 监听 modelValue 初始化
watch(() => props.modelValue, (value) => {
  if (value) {
    if (props.multiple) {
      tempSelectedKeys.value = Array.isArray(value) ? [...value] : []
    } else {
      tempSelectedKeys.value = typeof value === 'string' ? [value] : []
    }
    updateTempSelectedMetrics()
  }
}, { immediate: true })

// 按分类分组的指标
const metricsByCategory = computed(() => {
  // 搜索过滤
  const searched = metrics.value.filter(metric => {
    if (!searchKeyword.value) return true
    return metric.display_name.toLowerCase().includes(searchKeyword.value.toLowerCase())
  })

  // 按分类分组
  const grouped = new Map<string, AdsMetric[]>()
  searched.forEach(metric => {
    const category = metric.category || '其他'
    if (!grouped.has(category)) {
      grouped.set(category, [])
    }
    grouped.get(category)!.push(metric)
  })

  // 转换为数组并排序
  return Array.from(grouped.entries()).map(([category, items]) => ({
    category,
    metrics: items.sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
  }))
})

// 打开对话框
const openDialog = () => {
  if (props.disabled) return

  // 初始化临时数据
  if (props.multiple) {
    tempSelectedKeys.value = Array.isArray(props.modelValue) ? [...props.modelValue] : []
  } else {
    tempSelectedKeys.value = typeof props.modelValue === 'string' ? [props.modelValue] : []
  }
  updateTempSelectedMetrics()

  visible.value = true
}

// 检查分类是否全选
const isCategoryAllSelected = (categoryMetrics: AdsMetric[]) => {
  return categoryMetrics.every(metric => tempSelectedKeys.value.includes(metric.key))
}

// 检查分类是否部分选中
const isCategoryPartialSelected = (categoryMetrics: AdsMetric[]) => {
  const selectedCount = categoryMetrics.filter(metric => tempSelectedKeys.value.includes(metric.key)).length
  return selectedCount > 0 && selectedCount < categoryMetrics.length
}

// 切换分类全选
const toggleCategorySelection = (categoryMetrics: AdsMetric[]) => {
  const allSelected = isCategoryAllSelected(categoryMetrics)

  if (allSelected) {
    // 取消全选
    categoryMetrics.forEach(metric => {
      const index = tempSelectedKeys.value.indexOf(metric.key)
      if (index >= 0) {
        tempSelectedKeys.value.splice(index, 1)
      }
    })
  } else {
    // 全选
    categoryMetrics.forEach(metric => {
      if (!tempSelectedKeys.value.includes(metric.key)) {
        tempSelectedKeys.value.push(metric.key)
      }
    })
  }

  updateTempSelectedMetrics()
}

// 检查指标是否被选中
const isMetricSelected = (key: string) => {
  return tempSelectedKeys.value.includes(key)
}

// 切换指标选中状态
const toggleMetric = (metric: AdsMetric) => {
  if (!props.multiple) {
    // 单选模式：直接选中并关闭对话框
    emit('update:modelValue', metric.key)
    visible.value = false
    return
  }

  // 多选模式：切换选中状态
  const index = tempSelectedKeys.value.indexOf(metric.key)
  if (index >= 0) {
    // 取消选中
    tempSelectedKeys.value.splice(index, 1)
  } else {
    // 选中
    tempSelectedKeys.value.push(metric.key)
  }
  updateTempSelectedMetrics()
}

// 清除所有选择
const clearSelection = () => {
  tempSelectedKeys.value = []
  tempSelectedMetrics.value = []
}

// 拖拽结束后更新选中的键列表
watch(tempSelectedMetrics, (newMetrics) => {
  tempSelectedKeys.value = newMetrics.map(m => m.key)
})

// 取消
const handleCancel = () => {
  visible.value = false
}

// 确定
const handleConfirm = () => {
  emit('update:modelValue', tempSelectedKeys.value)
  visible.value = false
}

// 移除已选择的指标
const removeSelectedMetric = (key: string) => {
  const index = tempSelectedKeys.value.indexOf(key)
  if (index >= 0) {
    tempSelectedKeys.value.splice(index, 1)
    updateTempSelectedMetrics()
  }
}

// 显示文本
const displayText = computed(() => {
  if (!props.multiple) {
    // 单选模式：显示选中指标的名称
    if (!props.modelValue || typeof props.modelValue !== 'string') {
      return '请选择指标'
    }
    const metric = metrics.value.find(m => m.key === props.modelValue)
    return metric?.display_name || '请选择指标'
  } else {
    // 多选模式：显示选中数量
    if (!props.modelValue || !Array.isArray(props.modelValue) || props.modelValue.length === 0) {
      return '指标设置'
    }
    return `已选择 ${props.modelValue.length} 个指标`
  }
})
</script>

<template>
  <div class="metrics-selector">
    <!-- 触发按钮 -->
    <Button
      :label="label"
      icon="pi pi-cog"
      @click="openDialog"
      :disabled="disabled"
      :size="size"
    >
      <template #default>
        <i class="pi pi-cog mr-2"></i>
        {{ displayText }}
      </template>
    </Button>

    <!-- 指标设置对话框 -->
    <Dialog
      v-model:visible="visible"
      modal
      header="指标设置"
      :style="{ width: multiple ? '1100px' : '800px', maxWidth: '95vw', height: '700px' }"
      :dismissableMask="true"
      class="metrics-dialog"
    >
      <div class="flex h-full">
        <!-- 左侧：指标列表 -->
        <div :class="multiple ? 'flex-1 border-r border-gray-200 pr-4' : 'w-full'" class="flex flex-col">
          <!-- 搜索框 -->
          <div class="mb-4">
            <InputText
              v-model="searchKeyword"
              placeholder="请输入列名称"
              class="w-full"
            >
              <template #prefix>
                <i class="pi pi-search"></i>
              </template>
            </InputText>
          </div>

          <!-- 指标列表 -->
          <div class="flex-1 overflow-y-auto">
            <div
              v-for="group in metricsByCategory"
              :key="group.category"
              class="mb-4"
            >
              <!-- 分类标题 -->
              <div
                class="flex items-center gap-3 px-3 py-2.5 bg-gradient-to-r from-blue-50 to-blue-100 border-l-4 border-blue-500 rounded-md mb-3 transition-colors"
                :class="multiple ? 'cursor-pointer hover:from-blue-100 hover:to-blue-200' : ''"
                @click="multiple ? toggleCategorySelection(group.metrics) : null"
              >
                <Checkbox
                  v-if="multiple"
                  :modelValue="isCategoryAllSelected(group.metrics)"
                  :indeterminate="isCategoryPartialSelected(group.metrics)"
                  :binary="true"
                  @click.stop
                  @update:modelValue="toggleCategorySelection(group.metrics)"
                />
                <span class="font-semibold text-sm text-gray-800">{{ group.category }}</span>
              </div>

              <!-- 指标项 - 网格布局 -->
              <div class="grid grid-cols-3 gap-2 pl-2">
                <div
                  v-for="metric in group.metrics"
                  :key="metric.key"
                  class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-50 rounded"
                >
                  <RadioButton
                    v-if="!multiple"
                    :modelValue="tempSelectedKeys[0]"
                    :value="metric.key"
                    @update:modelValue="toggleMetric(metric)"
                  />
                  <Checkbox
                    v-else
                    :modelValue="isMetricSelected(metric.key)"
                    :binary="true"
                    @update:modelValue="toggleMetric(metric)"
                  />
                  <span class="text-sm truncate cursor-pointer" :title="metric.display_name" @click="toggleMetric(metric)" v-tooltip.top="metric.description">{{ metric.display_name }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：已选择列表（仅多选模式显示） -->
        <div v-if="multiple" class="w-64 pl-4 flex flex-col">
          <div class="flex items-center justify-between mb-4">
            <span class="font-semibold">已选择 {{ tempSelectedMetrics.length }} 列</span>
            <Button
              label="清除"
              link
              size="small"
              @click="clearSelection"
            />
          </div>

          <div class="text-xs text-gray-500 mb-2">
            拖动到列上方的列将固定显示
          </div>

          <!-- 拖拽列表 -->
          <div class="flex-1 overflow-y-auto">
            <draggable
              v-model="tempSelectedMetrics"
              item-key="key"
              class="space-y-2"
              handle=".drag-handle"
            >
              <template #item="{ element }">
                <div class="flex items-center gap-3 p-2 bg-gray-100 rounded hover:bg-gray-200">
                  <i class="pi pi-bars text-gray-400 cursor-move drag-handle"></i>
                  <span class="text-sm flex-1">{{ element.display_name }}</span>
                  <i
                    class="pi pi-times text-gray-400 cursor-pointer hover:text-red-500"
                    @click="removeSelectedMetric(element.key)"
                  ></i>
                </div>
              </template>
            </draggable>
          </div>
        </div>
      </div>

      <template #footer v-if="multiple">
        <div class="flex justify-end gap-2">
          <Button
            label="取消"
            severity="secondary"
            @click="handleCancel"
          />
          <Button
            label="确定"
            @click="handleConfirm"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.metrics-dialog :deep(.p-dialog-content) {
  padding: 1.5rem;
  height: calc(100% - 120px);
  overflow: hidden;
}

.drag-handle {
  cursor: move;
}
</style>
