<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import Card from 'primevue/card'
import Button from 'primevue/button'
import AutomationRulesTable from '@/views/_tables/AutomationRulesTable.vue'
import AutomationRuleDialog from '@/views/_dialogs/AutomationRuleDialog.vue'
import automationRuleApi, { type AutomationRule, type AutomationRuleFormData } from '@/api/automation-rule-api'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { getActionByValue } from '@/data/options/automation-actions'
import { useMetricsStore } from "@/stores/metrics"

const toast = useToast()
const confirm = useConfirm()
const { getMetric } = useMetricsStore()

const props = defineProps<{
  project: any
}>()

// 自动化规则
const automationRules = ref<AutomationRule[]>([])
const loadingRules = ref(false)

// 规则对话框
const showRuleDialog = ref(false)
const editingRule = ref<AutomationRule | null>(null)
const saving = ref(false)

// 字符串类型触发指标选项
const stringMetricOptions = [
  { label: '账号名称', value: 'account_name', type: 'string' },
  { label: '广告系列名称', value: 'campaign_name', type: 'string' },
  { label: '广告组名称', value: 'adset_name', type: 'string' },
  { label: '广告名称', value: 'ad_name', type: 'string' }
]

// 数值类型操作符选项
const numericOperatorOptions = [
  { label: '>', value: '>', symbol: '>', type: 'numeric' },
  { label: '<', value: '<', symbol: '<', type: 'numeric' },
  { label: '=', value: '=', symbol: '=', type: 'numeric' },
  { label: '!=', value: '!=', symbol: '!=', type: 'numeric' },
  { label: '>=', value: '>=', symbol: '>=', type: 'numeric' },
  { label: '<=', value: '<=', symbol: '<=', type: 'numeric' }
]

// 字符串类型操作符选项
const stringOperatorOptions = [
  { label: '包含', value: 'contains', symbol: '包含', type: 'string' },
  { label: '不包含', value: 'not_contains', symbol: '不包含', type: 'string' },
  { label: '等于', value: 'equals', symbol: '=', type: 'string' },
  { label: '不等于', value: 'not_equals', symbol: '≠', type: 'string' }
]

// 模拟的已有数据
const availableAccountNames = ref(['账号A', '账号B', '账号C'])
const availableCampaignNames = ref(['春季推广', '夏季活动', '秋季促销'])
const availableAdsetNames = ref(['年轻人群', '中年人群', '高收入人群'])
const availableAdNames = ref(['创意A', '创意B', '创意C'])

// 加载自动化规则
const loadAutomationRules = () => {
  if (!props.project?.id) return

  loadingRules.value = true
  automationRuleApi
      .getProjectRules(props.project.id)
      .then(data => {
        automationRules.value = data
      })
      .catch(err => {
        console.error('加载自动化规则失败:', err)
        toast.add({ severity: 'error', summary: '错误', detail: err?.msg ?? "加载自动化规则失败", life: 3000 })
      })
      .finally(() => loadingRules.value = false)
}

// 格式化单个条件显示
const formatConditionText = (condition: any): string => {
  if (condition.type === 'group') {
    return ''
  }

  const metric = getMetric(condition.metric)
  const operator = [...numericOperatorOptions, ...stringOperatorOptions].find(o => o.value === condition.operator)

  let text = `${metric?.display_name} ${operator?.label}`

  if (condition.metricType === 'numeric') {
    text += ` ${condition.value}${metric?.unit || ''}`
  } else {
    text += ` "${condition.value}"`
  }

  return text
}

// 递归格式化条件组显示
const formatConditionGroupText = (group: any, depth: number = 0): string => {
  if (!group.children || group.children.length === 0) {
    return ''
  }

  const texts = group.children.map((child: any) => {
    if (child.type === 'condition') {
      return formatConditionText(child)
    } else {
      const subText = formatConditionGroupText(child, depth + 1)
      return depth > 0 ? `(${subText})` : subText
    }
  }).filter((t: string) => t)

  const logicSymbol = group.logic === 'AND' ? ' 且 ' : ' 或 '
  return texts.join(logicSymbol)
}

// 格式化时间范围显示
const formatTimeRangeText = (rule: AutomationRule): string => {
  const ruleAny = rule as any

  if (ruleAny.time_type === 'range' && ruleAny.time_range_config) {
    const config = ruleAny.time_range_config
    const startDateConfig = config.start_date
    const endDateConfig = config.end_date

    // 格式化开始时间
    let startText = ''
    if (startDateConfig.type === 'absolute') {
      startText = startDateConfig.date
    } else {
      const days = Math.abs(startDateConfig.date)
      if (days === 0) {
        startText = '今天'
      } else if (days === 1) {
        startText = '昨天'
      } else {
        startText = `过去${days}天`
      }
    }

    // 格式化结束时间
    let endText = ''
    if (endDateConfig.type === 'absolute') {
      endText = endDateConfig.date
    } else {
      const days = Math.abs(endDateConfig.date)
      if (days === 0) {
        endText = '今天'
      } else if (days === 1) {
        endText = '昨天'
      } else {
        endText = `过去${days}天`
      }
    }

    // 如果开始和结束相同
    if (startText === endText) {
      return startText
    }

    return `${startText}~${endText}`
  } else {
    // 最近时间
    const timeUnit = rule.time_granularity === 'hour' ? '小时' : '天'
    return `最近${rule.time_range}${timeUnit}`
  }
}

// 格式化规则显示数据
const formattedRules = computed(() => {
  return automationRules.value.map(rule => {
    const timeRangeText = formatTimeRangeText(rule)
    const conditionText = `${timeRangeText}: ${formatConditionGroupText(rule.condition_group)}`

    const actionOption = getActionByValue(rule.action)
    let actionText = actionOption?.label || rule.action
    if (actionOption?.needsValue && rule.action_value) {
      actionText += ` ${rule.action_value}%`
    }

    return {
      ...rule,
      condition: conditionText,
      actionDisplay: actionText
    }
  })
})

// 打开添加规则对话框
const openRuleDialog = () => {
  editingRule.value = null
  showRuleDialog.value = true
}

// 打开编辑规则对话框
const openEditRuleDialog = (rule: AutomationRule) => {
  editingRule.value = rule
  showRuleDialog.value = true
}

// 保存自动化规则
const handleRuleSaved = async (ruleData: AutomationRuleFormData) => {
  saving.value = true

  try {
    if (editingRule.value) {
      await automationRuleApi.updateRule(editingRule.value.id, ruleData)
      toast.add({ severity: 'success', summary: '成功', detail: '规则更新成功', life: 3000 })
    } else {
      await automationRuleApi.createRule(props.project.id, ruleData)
      toast.add({ severity: 'success', summary: '成功', detail: '规则添加成功', life: 3000 })
    }

    await loadAutomationRules()
    showRuleDialog.value = false
    editingRule.value = null
  } catch (err: any) {
    console.error('保存规则失败:', err)
    const defaultMessage = editingRule.value ? '更新规则失败' : '添加规则失败'
    const message = err?.msg ?? defaultMessage
    toast.add({
      severity: 'error',
      summary: '错误',
      detail: message,
      life: 3000
    })
  } finally {
    saving.value = false
  }
}

// 删除自动化规则
const deleteRule = async (ruleId: number) => {
  confirm.require({
    message: '确定要删除该自动化规则吗？此操作不可恢复。',
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '确定',
    rejectLabel: '取消',
    accept: async () => {
      try {
        await automationRuleApi.deleteRule(ruleId)
        toast.add({ severity: 'success', summary: '成功', detail: '规则删除成功', life: 3000 })
        await loadAutomationRules()
      } catch (err: any) {
        console.error('删除规则失败:', err)
        const message = err?.msg ?? '删除规则失败'
        toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
      }
    }
  })
}

// 切换规则状态
const toggleRule = async (rule: AutomationRule) => {
  const previousState = rule.enabled
  try {
    await automationRuleApi.toggleRule(rule.id, rule.enabled)
    toast.add({
      severity: 'info',
      summary: '规则状态',
      detail: `规则已${rule.enabled ? '启用' : '禁用'}`,
      life: 3000
    })
  } catch (err: any) {
    console.error('切换规则状态失败:', err)
    rule.enabled = previousState
    const message = err?.msg ?? '切换规则状态失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 监听 project 变化，重新加载数据
watch(() => props.project?.id, (newId) => {
  if (newId) {
    loadAutomationRules()
  }
}, { immediate: true })
</script>

<template>
  <Card>
    <template #title>
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <i class="pi pi-cog text-orange-600 mr-2"></i>
          自动化规则
        </div>
        <Button
            @click="openRuleDialog"
            size="small"
            class="flex items-center"
        >
          <i class="pi pi-plus mr-2"></i>
          添加规则
        </Button>
      </div>
    </template>
    <template #content>
      <AutomationRulesTable
          :rules="formattedRules"
          :loading="loadingRules"
          @toggle="toggleRule"
          @edit="openEditRuleDialog"
          @delete="deleteRule"
      />
    </template>
  </Card>

  <!-- 自动化规则对话框 -->
  <AutomationRuleDialog
      v-model:visible="showRuleDialog"
      :rule="editingRule"
      :projectId="project.id"
      :stringMetricOptions="stringMetricOptions"
      :numericOperatorOptions="numericOperatorOptions"
      :stringOperatorOptions="stringOperatorOptions"
      :availableAccountNames="availableAccountNames"
      :availableCampaignNames="availableCampaignNames"
      :availableAdsetNames="availableAdsetNames"
      :availableAdNames="availableAdNames"
      @saved="handleRuleSaved"
  />
</template>

<style scoped>
</style>
