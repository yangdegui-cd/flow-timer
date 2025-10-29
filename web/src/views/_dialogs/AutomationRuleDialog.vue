<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Dropdown from 'primevue/dropdown'
import ToggleButton from 'primevue/togglebutton'
import Divider from 'primevue/divider'
import ConditionGroupDisplay, { type TriggerCondition } from './ConditionGroupDisplay.vue'
import ConditionEditDialog from './ConditionEditDialog.vue'
import { actionOptions, getActionByValue } from '@/data/options/automation-actions'
import type { AutomationRule } from '@/api/automation-rule-api'

interface Props {
  visible: boolean
  rule?: AutomationRule | null
  projectId: number
  stringMetricOptions: Array<{ label: string; value: string }>
  numericOperatorOptions: Array<{ label: string; value: string; symbol: string }>
  stringOperatorOptions: Array<{ label: string; value: string; symbol: string }>
  availableAccountNames?: string[]
  availableCampaignNames?: string[]
  availableAdsetNames?: string[]
  availableAdNames?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  rule: null,
  availableAccountNames: () => [],
  availableCampaignNames: () => [],
  availableAdsetNames: () => [],
  availableAdNames: () => []
})

const emit = defineEmits<{
  'update:visible': [value: boolean]
  saved: []
}>()

const toast = useToast()

// 时间粒度选项
const timeGranularityOptions = [
  { label: '小时', value: 'hour' },
  { label: '天', value: 'day' }
]

// 规则表单数据
const newRule = ref({
  name: '',
  timeGranularity: 'hour',
  timeRange: 1,
  conditionGroup: {
    id: Date.now(),
    type: 'group' as const,
    logic: 'AND' as 'AND' | 'OR',
    children: [] as TriggerCondition[]
  },
  action: 'pause_ad',
  actionValue: 0,
  enabled: true
})

// 条件编辑对话框
const showConditionDialog = ref(false)
const targetGroup = ref<TriggerCondition | null>(null)
const editingCondition = ref<TriggerCondition | null>(null)
const isConditionEditMode = ref(false)

// 计算属性：是否为编辑模式
const isEditMode = computed(() => !!props.rule)

// 计算属性：当前选中的动作信息
const selectedAction = computed(() => {
  return getActionByValue(newRule.value.action)
})

// 计算属性：格式化的时间范围描述
const timeRangeDescription = computed(() => {
  const unit = newRule.value.timeGranularity === 'hour' ? '小时' : '天'
  return `最近 ${newRule.value.timeRange} ${unit}`
})

// 监听 visible 变化，打开时初始化表单
watch(() => props.visible, (visible) => {
  if (visible) {
    if (props.rule) {
      // 编辑模式：加载规则数据
      newRule.value = {
        name: props.rule.name,
        timeGranularity: props.rule.time_granularity || 'hour',
        timeRange: props.rule.time_range || 1,
        conditionGroup: props.rule.condition_group ? JSON.parse(JSON.stringify(props.rule.condition_group)) : {
          id: Date.now(),
          type: 'group',
          logic: 'AND',
          children: []
        },
        action: props.rule.action || 'pause_ad',
        actionValue: props.rule.action_value || 0,
        enabled: props.rule.enabled
      }
    } else {
      // 新建模式：重置表单
      resetForm()
    }
  }
})

// 重置表单
const resetForm = () => {
  newRule.value = {
    name: '',
    timeGranularity: 'hour',
    timeRange: 1,
    conditionGroup: {
      id: Date.now(),
      type: 'group',
      logic: 'AND',
      children: []
    },
    action: 'pause_ad',
    actionValue: 0,
    enabled: true
  }
}

// 切换条件组逻辑
const toggleGroupLogic = (group: TriggerCondition) => {
  if (group.logic === 'AND') {
    group.logic = 'OR'
  } else {
    group.logic = 'AND'
  }
  // 强制更新
  newRule.value = { ...newRule.value }
}

// 删除条件或条件组
const removeConditionOrGroup = (conditionId: number, parent: TriggerCondition = newRule.value.conditionGroup) => {
  if (parent.children) {
    const index = parent.children.findIndex(c => c.id === conditionId)
    if (index !== -1) {
      parent.children.splice(index, 1)
      toast.add({ severity: 'info', summary: '提示', detail: '已删除', life: 2000 })
      return true
    }

    // 递归查找子条件组
    for (const child of parent.children) {
      if (child.type === 'group' && removeConditionOrGroup(conditionId, child)) {
        return true
      }
    }
  }
  return false
}

// 打开添加条件对话框
const addConditionToGroup = (group: TriggerCondition) => {
  targetGroup.value = group
  editingCondition.value = null
  isConditionEditMode.value = false
  showConditionDialog.value = true
}

// 打开编辑条件对话框
const editCondition = (condition: TriggerCondition) => {
  editingCondition.value = condition
  isConditionEditMode.value = true
  showConditionDialog.value = true
}

// 添加条件组到根
const addGroupToRoot = () => {
  newRule.value.conditionGroup.children.push({
    id: Date.now(),
    type: 'group',
    logic: 'AND',
    children: []
  })
  toast.add({ severity: 'success', summary: '成功', detail: '条件组添加成功', life: 2000 })
}

// 保存条件（从 ConditionEditDialog 触发）
const handleConditionSaved = (condition: TriggerCondition) => {
  if (isConditionEditMode.value && editingCondition.value) {
    // 编辑模式：更新现有条件
    editingCondition.value.metricType = condition.metricType
    editingCondition.value.metric = condition.metric
    editingCondition.value.operator = condition.operator
    editingCondition.value.value = condition.value
    // 强制更新
    newRule.value = { ...newRule.value }
    toast.add({ severity: 'success', summary: '成功', detail: '条件更新成功', life: 2000 })
  } else {
    // 添加模式：添加新条件
    if (!targetGroup.value) return
    if (!targetGroup.value.children) targetGroup.value.children = []
    targetGroup.value.children.push({ ...condition })
    toast.add({ severity: 'success', summary: '成功', detail: '条件添加成功', life: 2000 })
  }

  showConditionDialog.value = false
}

// 关闭对话框
const handleClose = () => {
  emit('update:visible', false)
}

// 保存规则
const handleSave = () => {
  // 验证
  if (!newRule.value.name) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请输入规则名称', life: 3000 })
    return
  }

  if (!newRule.value.conditionGroup.children || newRule.value.conditionGroup.children.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请至少添加一个触发条件', life: 3000 })
    return
  }

  if (selectedAction.value?.needsValue && (!newRule.value.actionValue || newRule.value.actionValue <= 0)) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请输入有效的百分比值', life: 3000 })
    return
  }

  // 准备数据并触发保存事件
  const ruleData = {
    name: newRule.value.name,
    time_granularity: newRule.value.timeGranularity,
    time_range: newRule.value.timeRange,
    condition_group: newRule.value.conditionGroup,
    action: newRule.value.action,
    action_value: newRule.value.actionValue,
    enabled: newRule.value.enabled
  }

  emit('saved', ruleData as any)
}
</script>

<template>
  <Dialog
    :visible="visible"
    modal
    :header="isEditMode ? '编辑自动化规则' : '添加自动化规则'"
    :style="{ width: '800px', maxWidth: '90vw' }"
    :dismissableMask="true"
    @update:visible="emit('update:visible', $event)"
  >
    <div class="space-y-6">
      <!-- 规则名称 -->
      <div class="space-y-2">
        <label class="text-sm font-medium text-gray-700 flex items-center">
          <i class="pi pi-tag text-gray-500 mr-2"></i>
          规则名称
          <span class="text-red-500 ml-1">*</span>
        </label>
        <InputText
          v-model="newRule.name"
          placeholder="例如:高CPI自动暂停"
          class="w-full"
        />
      </div>

      <Divider />

      <!-- 时间参数 -->
      <div class="space-y-3">
        <div class="flex items-center mb-3">
          <i class="pi pi-clock text-blue-600 mr-2"></i>
          <span class="text-sm font-semibold text-gray-700">时间参数</span>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-2">
            <label class="text-sm font-medium text-gray-700">时间粒度</label>
            <Dropdown
              v-model="newRule.timeGranularity"
              :options="timeGranularityOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择时间粒度"
              class="w-full"
            />
          </div>

          <div class="space-y-2">
            <label class="text-sm font-medium text-gray-700">时间范围</label>
            <InputNumber
              v-model="newRule.timeRange"
              :min="1"
              :max="365"
              placeholder="输入数字"
              class="w-full"
            />
            <span class="text-xs text-gray-500">{{ timeRangeDescription }}</span>
          </div>
        </div>
      </div>

      <Divider />

      <!-- 触发条件 -->
      <div class="space-y-3">
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center">
            <i class="pi pi-filter text-green-600 mr-2"></i>
            <span class="text-sm font-semibold text-gray-700">触发条件</span>
            <span class="text-red-500 ml-1">*</span>
          </div>
        </div>

        <!-- 条件组显示（递归） -->
        <ConditionGroupDisplay
          :group="newRule.conditionGroup"
          :level="0"
          :stringMetricOptions="stringMetricOptions"
          :numericOperatorOptions="numericOperatorOptions"
          :stringOperatorOptions="stringOperatorOptions"
          @remove="removeConditionOrGroup"
          @add-condition="addConditionToGroup"
          @add-group="addGroupToRoot"
          @edit="editCondition"
          @toggle-logic="toggleGroupLogic"
        />
      </div>

      <Divider />

      <!-- 触发动作 -->
      <div class="space-y-3">
        <div class="flex items-center mb-3">
          <i class="pi pi-bolt text-orange-600 mr-2"></i>
          <span class="text-sm font-semibold text-gray-700">触发动作</span>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-2" :class="{ 'col-span-2': !selectedAction?.needsValue }">
            <label class="text-sm font-medium text-gray-700">执行动作</label>
            <Dropdown
              v-model="newRule.action"
              :options="actionOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="选择动作"
              class="w-full"
            />
          </div>

          <div v-if="selectedAction?.needsValue" class="space-y-2">
            <label class="text-sm font-medium text-gray-700">调整百分比</label>
            <div class="flex items-center gap-2">
              <InputNumber
                v-model="newRule.actionValue"
                :min="1"
                :max="100"
                placeholder="输入百分比"
                class="flex-1"
              />
              <span class="text-sm text-gray-600">%</span>
            </div>
            <span class="text-xs text-gray-500">范围: 1% - 100%</span>
          </div>
        </div>
      </div>

      <Divider />

      <!-- 规则状态 -->
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <i class="pi pi-power-off text-purple-600 mr-2"></i>
          <span class="text-sm font-medium text-gray-700">创建后立即启用</span>
        </div>
        <ToggleButton
          v-model="newRule.enabled"
          onLabel="是"
          offLabel="否"
        />
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
          :label="isEditMode ? '保存' : '添加规则'"
          @click="handleSave"
        />
      </div>
    </template>

    <!-- 条件编辑对话框 -->
    <ConditionEditDialog
      v-model:visible="showConditionDialog"
      :condition="editingCondition"
      :isEdit="isConditionEditMode"
      :targetGroup="targetGroup"
      :stringMetricOptions="stringMetricOptions"
      :numericOperatorOptions="numericOperatorOptions"
      :stringOperatorOptions="stringOperatorOptions"
      :availableAccountNames="availableAccountNames"
      :availableCampaignNames="availableCampaignNames"
      :availableAdsetNames="availableAdsetNames"
      :availableAdNames="availableAdNames"
      @save="handleConditionSaved"
    />
  </Dialog>
</template>
