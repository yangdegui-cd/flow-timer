<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import PageHeader from '@/views/layer/PageHeader.vue'
import AutomationLogsTab from '../logs/AutomationLogsTab.vue'
import AutomationRuleDialog from '@/views/_dialogs/AutomationRuleDialog.vue'
import projectApi, { projectStatusOptions } from '@/api/project-api'
import automationRuleApi, { type AutomationRule, type AutomationRuleFormData } from '@/api/automation-rule-api'
import { adsAccountApi } from '@/api/ads-account-api'
import userProjectApi, { type ProjectRole, type UserProject } from '@/api/user-project-api'
import userApi from '@/api/user-api'
import Card from 'primevue/card'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Calendar from 'primevue/calendar'
import Dropdown from 'primevue/dropdown'
import ToggleButton from 'primevue/togglebutton'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import Avatar from 'primevue/avatar'
import MultiSelect from 'primevue/multiselect'
import Dialog from 'primevue/dialog'
import { Project } from "@/data/types/project-types"
import { actionOptions, getActionByValue } from '@/data/options/automation-actions'
import { Metrics } from "@/data/types/ads-types";
import metricsApi from "@/api/metrics-api";

const route = useRoute()
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()

const projectId = computed(() => route.params.id as string)
const isEditMode = ref(false)
const loading = ref(false)
const saving = ref(false)

// 项目基本信息
const project = ref<Project>({
  id: 0,
  name: '',
  description: '',
  start_date: '',
  status: 'active',
  active_ads_automate: true,
  time_zone: 8,
  adjust_game_token: '',
  sys_users: [],
  user_count: 0
})

// 编辑表单
const form = ref({
  name: '',
  description: '',
  start_date: null as Date | null,
  status: 'active',
  active_ads_automate: true,
  time_zone: 8,
  adjust_game_token: ''
})

// 广告账户数据
const adsAccounts = ref([])
const selectedAdsAccounts = ref([])
const availableAdsAccounts = ref([])


// 分配的用户
const assignedUsers = ref<UserProject[]>([])
const availableUsers = ref<any[]>([])
const selectedUsersForAssign = ref<any[]>([]) // 选中的用户对象数组
const showUserDialog = ref(false)
const currentUserRole = ref<ProjectRole>('member')
const editingUserProject = ref<UserProject | null>(null)
const metrics = ref<Metrics>([])

// 角色选项
const roleOptions = [
  { label: '所有者', value: 'owner', description: '拥有项目的完全控制权' },
  { label: '成员', value: 'member', description: '可以编辑项目和管理数据' },
  { label: '查看者', value: 'viewer', description: '只能查看项目数据' }
]

// 自动化规则
const automationRules = ref<AutomationRule[]>([])
const loadingRules = ref(false)

// 规则对话框
const showRuleDialog = ref(false)
const editingRule = ref<AutomationRule | null>(null) // 正在编辑的规则

// 时间粒度选项
const timeGranularityOptions = [
  { label: '小时', value: 'hour' },
  { label: '天', value: 'day' }
]

// 数值类型触发指标选项
const numericMetricOptions = [
  { label: '展示', value: 'impressions', unit: '', min: 0, max: 999999999, type: 'numeric' },
  { label: '点击', value: 'clicks', unit: '', min: 0, max: 999999999, type: 'numeric' },
  { label: '安装', value: 'installs', unit: '', min: 0, max: 999999999, type: 'numeric' },
  { label: 'CPM', value: 'cpm', unit: '$', min: 0, max: 1000, type: 'numeric' },
  { label: 'CPC', value: 'cpc', unit: '$', min: 0, max: 1000, type: 'numeric' },
  { label: 'CPI', value: 'cpi', unit: '$', min: 0, max: 1000, type: 'numeric' },
  { label: 'CTR', value: 'ctr', unit: '%', min: 0, max: 100, type: 'numeric' },
  { label: '转化率', value: 'cvRate', unit: '%', min: 0, max: 100, type: 'numeric' },
]

// 字符串类型触发指标选项
const stringMetricOptions = [
  { label: '账号名称', value: 'account_name', type: 'string' },
  { label: '广告系列名称', value: 'campaign_name', type: 'string' },
  { label: '广告组名称', value: 'adset_name', type: 'string' },
  { label: '广告名称', value: 'ad_name', type: 'string' }
]

// 合并所有指标选项
const allMetricOptions = [...numericMetricOptions, ...stringMetricOptions]

// 数值类型操作符选项
const numericOperatorOptions = [
  { label: '大于', value: 'gt', symbol: '>', type: 'numeric' },
  { label: '小于', value: 'lt', symbol: '<', type: 'numeric' },
  { label: '等于', value: 'eq', symbol: '=', type: 'numeric' },
  { label: '大于等于', value: 'gte', symbol: '≥', type: 'numeric' },
  { label: '小于等于', value: 'lte', symbol: '≤', type: 'numeric' }
]

// 字符串类型操作符选项
const stringOperatorOptions = [
  { label: '包含', value: 'contains', symbol: '包含', type: 'string' },
  { label: '不包含', value: 'not_contains', symbol: '不包含', type: 'string' },
  { label: '等于', value: 'equals', symbol: '=', type: 'string' },
  { label: '不等于', value: 'not_equals', symbol: '≠', type: 'string' }
]

// 条件逻辑选项
const conditionLogicOptions = [
  { label: '且 (AND)', value: 'AND' },
  { label: '或 (OR)', value: 'OR' }
]

// 触发动作选项已从 @/data/options/automation-actions 导入

// 模拟的已有数据（用于下拉选择）
const availableAccountNames = ref(['账号A', '账号B', '账号C'])
const availableCampaignNames = ref(['春季推广', '夏季活动', '秋季促销'])
const availableAdsetNames = ref(['年轻人群', '中年人群', '高收入人群'])
const availableAdNames = ref(['创意A', '创意B', '创意C'])


// 加载项目详情
const loadProject = () => {
  if (projectId.value === 'new') {
    isEditMode.value = true
    return
  }

  loading.value = true
  projectApi.show(parseInt(projectId.value)).then(data => {
    project.value = data

    // 填充编辑表单
    form.value = {
      name: data.name,
      description: data.description || '',
      start_date: data.start_date ? new Date(data.start_date) : null,
      status: data.status,
      active_ads_automate: data.active_ads_automate,
      time_zone: data.time_zone || 8,
      adjust_game_token: data.adjust_game_token || ''
    }
    // 加载关联数据
    Promise.all([
      loadProjectAdsAccounts(),
      loadProjectUsers(),
      loadAutomationRules()
    ])
  }).catch(err => {
    console.err('加载项目失败:', err)
    toast.add({ severity: 'err', summary: '错误', detail: '加载项目失败', life: 3000 })
  }).finally(() => {
    loading.value = false
  })
}

// 加载自动化规则
const loadAutomationRules = () => {
  if (projectId.value === 'new') return

  loadingRules.value = true
  automationRuleApi
      .getProjectRules(parseInt(projectId.value))
      .then(data => {
        automationRules.value = data
      })
      .catch(err => {
        console.err('加载自动化规则失败:', err)
        toast.add({ severity: 'err', summary: '错误', detail: err?.msg ?? "加载自动化规则失败", life: 3000 })
      })
      .finally(() => loadingRules.value = false)
}

// 加载可用的广告账户（未绑定或已绑定到当前项目的账户）
const loadAvailableAdsAccounts = () => {
  adsAccountApi
      .getAvailableAccounts(parseInt(projectId.value))
      .then(data => {
        availableAdsAccounts.value = data?.data ?? []
      })
      .catch(err => {
        console.err('加载可用广告账户失败:', err)
        toast.add({ severity: 'err', summary: '错误', detail: err?.msg ?? "加载可用广告账户失败", life: 3000 })
      })
}

const loadProjectAdsAccounts = () => {
  adsAccountApi
      .getAdsAccounts(parseInt(projectId.value))
      .then(data => {
        adsAccounts.value = data?.data ?? []
        loadAvailableAdsAccounts()
      })
      .catch(err => {
        console.err('加载项目广告账户失败:', err)
        toast.add({ severity: 'err', summary: '错误', detail: err?.msg ?? '加载项目广告账户失败', life: 3000 })
      })
}

// 加载项目分配的用户
const loadProjectUsers = async () => {
  userProjectApi
      .getProjectUsers(parseInt(projectId.value))
      .then(data => {
        assignedUsers.value = data ?? []
      })
      .catch(err => {
        console.err('加载项目用户失败:', err)
        toast.add({ severity: 'err', summary: '错误', detail: err?.msg ?? '加载项目用户失败', life: 3000 })
      })
}

const loadMetrics = () => {
  metricsApi.list()
      .then(res => {
        metrics.value = res
      })
      .catch(err => {
        toast.add({ severity: 'err', summary: '错误', detail: err.msg, life: 3000 })
      })
}

// 加载可用用户（所有系统用户）
const loadAvailableUsers = async () => {
  userApi.list()
      .then(res => {
        availableUsers.value = res.users
      })
      .catch(res => {
        toast.add({ severity: 'err', summary: '加载可用用户失败', detail: res.data.msg, life: 3000 })
      })
}

// 保存项目
const saveProject = () => {
  saving.value = true
  const formData = {
    ...form.value,
    start_date: form.value.start_date ? form.value.start_date.toISOString().split('T')[0] : null
  }

  if (projectId.value === 'new') {
    projectApi.create(formData).then(newProject => {
      toast.add({ severity: 'success', summary: '成功', detail: '项目创建成功', life: 3000 })
      router.push(`/project/${newProject.id}`)
    }).catch(err => {
      console.err('保存项目失败:', err)
      toast.add({ severity: 'err', summary: '错误', detail: '保存项目失败', life: 3000 })
    }).finally(() => {
      saving.value = false
    })
  } else {
    projectApi.update(parseInt(projectId.value), formData).then(() => {
      loadProject()
      isEditMode.value = false
      toast.add({ severity: 'success', summary: '成功', detail: '项目更新成功', life: 3000 })
    }).catch(err => {
      console.err('保存项目失败:', err)
      toast.add({ severity: 'err', summary: '错误', detail: '保存项目失败', life: 3000 })
    }).finally(() => {
      saving.value = false
    })
  }
}

// 取消编辑
const cancelEdit = () => {
  if (projectId.value === 'new') {
    router.push('/project')
    return
  }

  isEditMode.value = false
  // 重置表单
  form.value = {
    name: project.value.name,
    description: project.value.description || '',
    start_date: project.value.start_date ? new Date(project.value.start_date) : null,
    status: project.value.status,
    active_ads_automate: project.value.active_ads_automate,
    time_zone: project.value.time_zone || 8,
    adjust_game_token: project.value.adjust_game_token || ''
  }
}

// 绑定广告账户
const bindAdsAccounts = async () => {
  if (!selectedAdsAccounts.value || selectedAdsAccounts.value.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请选择要绑定的账户', life: 3000 })
    return
  }

  try {
    // 绑定所有选中的账户
    for (const accountId of selectedAdsAccounts.value) {
      await adsAccountApi.bindAccount(parseInt(projectId.value), accountId)
    }

    toast.add({ severity: 'success', summary: '成功', detail: '广告账户绑定成功', life: 3000 })
    selectedAdsAccounts.value = []
    await loadProjectAdsAccounts()
    await loadAvailableAdsAccounts()
  } catch (err: any) {
    console.err('绑定广告账户失败:', err)
    const message = err?.msg ?? '绑定失败'
    toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
  }
}

// 解绑广告账户
const unbindAdsAccount = async (accountId: number) => {
  confirm.require({
    message: '确定要解绑该广告账户吗？解绑后该账户将不再与此项目关联。',
    header: '确认解绑',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '确定',
    rejectLabel: '取消',
    accept: async () => {
      try {
        await adsAccountApi.unbindAccount(parseInt(projectId.value), accountId)
        toast.add({ severity: 'success', summary: '成功', detail: '广告账户解绑成功', life: 3000 })
        await loadProjectAdsAccounts()
        await loadAvailableAdsAccounts()
      } catch (err: any) {
        console.err('解绑广告账户失败:', err)
        const message = err?.msg ?? '解绑失败'
        toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
      }
    }
  })
}

// 打开分配用户对话框
const openAssignUserDialog = () => {
  selectedUsersForAssign.value = []
  currentUserRole.value = 'member'
  editingUserProject.value = null
  showUserDialog.value = true
}

// 分配用户
const assignUsers = async () => {
  if (!selectedUsersForAssign.value || selectedUsersForAssign.value.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请选择要分配的用户', life: 3000 })
    return
  }

  try {
    // 逐个分配用户
    for (const user of selectedUsersForAssign.value) {
      await userProjectApi.assignUser({
        sys_user_id: user.id,
        project_id: parseInt(projectId.value),
        role: currentUserRole.value
      })
    }
    toast.add({ severity: 'success', summary: '成功', detail: '用户分配成功', life: 3000 })
    showUserDialog.value = false
    selectedUsersForAssign.value = []
    await loadProjectUsers()
  } catch (err: any) {
    console.err('分配用户失败:', err)
    const message = err?.msg ?? '分配失败'
    toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
  }
}

// 更新用户角色
const updateUserRole = async (userProject: UserProject, newRole: ProjectRole) => {
  try {
    await userProjectApi.updateUserRole(userProject.id, newRole)
    toast.add({ severity: 'success', summary: '成功', detail: '角色更新成功', life: 3000 })
    await loadProjectUsers()
  } catch (err: any) {
    console.err('更新角色失败:', err)
    const message = err?.msg ?? '更新失败'
    toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
  }
}

// 移除用户
const removeUser = async (userProject: UserProject) => {
  confirm.require({
    message: `确定要将用户 "${userProject.sys_user.name}" 从项目中移除吗？`,
    header: '确认移除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '确定',
    rejectLabel: '取消',
    accept: async () => {
      try {
        await userProjectApi.removeUser(userProject.id)
        toast.add({ severity: 'success', summary: '成功', detail: '用户移除成功', life: 3000 })
        await loadProjectUsers()
      } catch (err: any) {
        console.err('移除用户失败:', err)
        const message = err?.msg ?? '移除失败'
        toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
      }
    }
  })
}

// 获取角色标签颜色
const getRoleSeverity = (role: ProjectRole) => {
  switch (role) {
    case 'owner':
      return 'danger'
    case 'member':
      return 'success'
    case 'viewer':
      return 'info'
    default:
      return 'secondary'
  }
}

// 格式化单个条件显示
const formatConditionText = (condition: any): string => {
  if (condition.type === 'group') {
    return '' // 条件组不需要格式化文本
  }

  const metric = allMetricOptions.find(m => m.value === condition.metric)
  const operator = [...numericOperatorOptions, ...stringOperatorOptions].find(o => o.value === condition.operator)

  let text = `${metric?.label} ${operator?.label}`

  if (condition.metricType === 'numeric') {
    const numMetric = numericMetricOptions.find(m => m.value === condition.metric)
    text += ` ${condition.value}${numMetric?.unit || ''}`
  } else {
    text += ` "${condition.value}"`
  }

  return text
}

// 递归格式化条件组显示（用于最终规则描述）
const formatConditionGroupText = (group: any, depth: number = 0): string => {
  if (!group.children || group.children.length === 0) {
    return ''
  }

  const texts = group.children.map((child: any) => {
    if (child.type === 'condition') {
      return formatConditionText(child)
    } else {
      // 递归处理子条件组
      const subText = formatConditionGroupText(child, depth + 1)
      return depth > 0 ? `(${subText})` : subText
    }
  }).filter((t: string) => t)

  const logicSymbol = group.logic === 'AND' ? ' 且 ' : ' 或 '
  return texts.join(logicSymbol)
}

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

// 保存自动化规则（从对话框触发）
const handleRuleSaved = async (ruleData: AutomationRuleFormData) => {
  saving.value = true

  try {
    if (editingRule.value) {
      // 编辑模式：更新现有规则
      await automationRuleApi.updateRule(editingRule.value.id, ruleData)
      toast.add({ severity: 'success', summary: '成功', detail: '规则更新成功', life: 3000 })
    } else {
      // 添加模式：创建新规则
      await automationRuleApi.createRule(parseInt(projectId.value), ruleData)
      toast.add({ severity: 'success', summary: '成功', detail: '规则添加成功', life: 3000 })
    }

    // 重新加载规则列表
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
        // 重新加载规则列表
        await loadAutomationRules()
      } catch (err: any) {
        console.err('删除规则失败:', err)
        const message = err?.msg ?? '删除规则失败'
        toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
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
    console.err('切换规则状态失败:', err)
    // 恢复之前的状态
    rule.enabled = previousState
    const message = err?.msg ?? '切换规则状态失败'
    toast.add({ severity: 'err', summary: '错误', detail: message, life: 3000 })
  }
}

// 页面标题
const pageTitle = computed(() => {
  if (projectId.value === 'new') return '新建项目'
  return isEditMode.value ? '编辑项目' : '项目详情'
})

// 格式化规则显示数据
const formattedRules = computed(() => {
  return automationRules.value.map(rule => {
    // 格式化条件文本
    const timeUnit = rule.time_granularity === 'hour' ? '小时' : '天'
    const conditionText = `最近${rule.time_range}${timeUnit}: ${formatConditionGroupText(rule.condition_group)}`

    // 格式化动作文本
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

onMounted(async () => {
  await Promise.all([
    loadProject(),
    loadAvailableAdsAccounts(),
    loadProjectAdsAccounts(),
    loadAvailableUsers(),
    loadProjectUsers(),
    loadMetrics()
  ])
})
</script>

<template>
  <PageHeader
      :title="pageTitle"
      :description="projectId === 'new' ? '创建新的项目' : project.name"
      icon="pi pi-folder"
      icon-color="text-blue-600"
  >
    <template #actions>
      <Button
          v-if="!isEditMode && projectId !== 'new'"
          @click="isEditMode = true"
          size="small"
          class="mr-2"
      >
        <i class="pi pi-pencil mr-2"></i>
        编辑项目
      </Button>

      <Button
          v-if="isEditMode"
          @click="saveProject"
          :loading="saving"
          size="small"
          class="mr-2"
      >
        <i class="pi pi-check mr-2"></i>
        保存
      </Button>

      <Button
          v-if="isEditMode"
          @click="cancelEdit"
          size="small"
          severity="secondary"
          class="mr-2"
      >
        <i class="pi pi-times mr-2"></i>
        取消
      </Button>

      <Button
          @click="router.push('/project')"
          size="small"
          severity="secondary"
      >
        <i class="pi pi-arrow-left mr-2"></i>
        返回列表
      </Button>
    </template>
  </PageHeader>

  <div class="flex-1 overflow-auto p-4 h-[calc(100vh-130px)]">
    <div class="max-w-7xl mx-auto space-y-4">
      <!-- 基本信息 -->
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-info-circle text-blue-600 mr-2"></i>
            基本信息
          </div>
        </template>
        <template #content>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">项目名称</label>
              <InputText
                  v-if="isEditMode"
                  v-model="form.name"
                  placeholder="请输入项目名称"
                  class="w-full"
              />
              <div v-else class="p-2 bg-gray-50 rounded">{{ project.name }}</div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">开始日期</label>
              <Calendar
                  v-if="isEditMode"
                  v-model="form.start_date"
                  placeholder="选择开始日期"
                  class="w-full"
              />
              <div v-else class="p-2 bg-gray-50 rounded">
                {{ project.start_date ? new Date(project.start_date).toLocaleDateString('zh-CN') : '-' }}
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">状态</label>
              <Dropdown
                  v-if="isEditMode"
                  v-model="form.status"
                  :options="projectStatusOptions"
                  optionLabel="label"
                  optionValue="value"
                  class="w-full"
              />
              <div v-else class="p-2">
                <Tag
                    :value="projectStatusOptions.find(opt => opt.value === project.status)?.label"
                    :severity="project.status === 'active' ? 'success' : 'warning'"
                />
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">广告自动化</label>
              <ToggleButton
                  v-if="isEditMode"
                  v-model="form.active_ads_automate"
                  onLabel="启用"
                  offLabel="禁用"
                  class="w-full"
              />
              <div v-else class="p-2">
                <Tag
                    :value="project.active_ads_automate ? '启用' : '禁用'"
                    :severity="project.active_ads_automate ? 'success' : 'warning'"
                />
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">时区(UTC)</label>
              <InputNumber
                  v-if="isEditMode"
                  v-model="form.time_zone"
                  :min="-12"
                  :max="14"
                  placeholder="如: 8 表示 UTC+8"
                  class="w-full"
              />
              <div v-else class="p-2 bg-gray-50 rounded">
                {{ project.time_zone >= 0 ? `UTC+${project.time_zone}` : `UTC${project.time_zone}` }}
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium text-gray-700">Adjust Game Token</label>
              <InputText
                  v-if="isEditMode"
                  v-model="form.adjust_game_token"
                  placeholder="请输入 Adjust Game Token"
                  class="w-full"
              />
              <div v-else class="p-2 bg-gray-50 rounded font-mono text-sm">
                {{ project.adjust_game_token || '未配置' }}
              </div>
            </div>

            <div class="md:col-span-2 space-y-2">
              <label class="text-sm font-medium text-gray-700">描述</label>
              <Textarea
                  v-if="isEditMode"
                  v-model="form.description"
                  placeholder="请输入项目描述"
                  rows="3"
                  class="w-full"
              />
              <div v-else class="p-2 bg-gray-50 rounded min-h-[80px]">
                {{ project.description || '暂无描述' }}
              </div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 绑定广告账户 -->
      <Card>
        <template #title>
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <i class="pi pi-link text-green-600 mr-2"></i>
              绑定广告账户
            </div>
            <Button
                @click="bindAdsAccounts"
                size="small"
                class="flex items-center"
            >
              <i class="pi pi-plus mr-2"></i>
              绑定账户
            </Button>
          </div>
        </template>
        <template #content>
          <div class="space-y-4">
            <MultiSelect
                v-model="selectedAdsAccounts"
                :options="availableAdsAccounts"
                optionLabel="display_name"
                optionValue="id"
                placeholder="选择要绑定的广告账户"
                class="w-full"
            >
              <template #option="{ option }">
                <div class="flex items-center gap-2">
                  <Tag :value="option.ads_platform?.name || '未知平台'" severity="info"/>
                  <span>{{ option.name }}</span>
                  <span class="text-gray-500 text-sm">({{ option.account_id }})</span>
                </div>
              </template>
            </MultiSelect>

            <DataTable
                :value="adsAccounts"
                size="small"
                class="mt-4"
            >
              <Column field="name" header="账户名称"/>
              <Column field="ads_platform.name" header="平台">
                <template #body="{ data }">
                  <Tag :value="data.ads_platform?.name || '未知平台'" severity="info"/>
                </template>
              </Column>
              <Column field="account_id" header="账户ID"/>
              <Column field="account_status" header="状态">
                <template #body="{ data }">
                  <Tag
                      :value="data.account_status === 'active' ? '活跃' : data.account_status === 'suspended' ? '暂停' : '关闭'"
                      :severity="data.account_status === 'active' ? 'success' : 'warning'"
                  />
                </template>
              </Column>
              <Column header="操作" style="width: 100px">
                <template #body="{ data }">
                  <Button
                      icon="pi pi-trash"
                      size="small"
                      severity="danger"
                      text
                      @click="unbindAdsAccount(data.id)"
                      title="解绑账户"
                  />
                </template>
              </Column>
              <template #empty>
                <div class="text-center py-4 text-gray-500">
                  暂未绑定广告账户
                </div>
              </template>
            </DataTable>
          </div>
        </template>
      </Card>

      <!-- 分配用户 -->
      <Card>
        <template #title>
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <i class="pi pi-users text-purple-600 mr-2"></i>
              分配用户
            </div>
            <Button
                @click="openAssignUserDialog"
                size="small"
                class="flex items-center"
            >
              <i class="pi pi-user-plus mr-2"></i>
              分配用户
            </Button>
          </div>
        </template>
        <template #content>
          <DataTable
              :value="assignedUsers"
              size="small"
          >
            <Column header="用户">
              <template #body="{ data }">
                <div class="flex items-center gap-3">
                  <Avatar
                      :label="data.sys_user.initials || data.sys_user.name?.[0]"
                      size="normal"
                  />
                  <div>
                    <div class="font-medium">{{ data.sys_user.name }}</div>
                    <div class="text-sm text-gray-500">{{ data.sys_user.email }}</div>
                  </div>
                </div>
              </template>
            </Column>
            <Column field="role" header="角色">
              <template #body="{ data }">
                <Dropdown
                    :modelValue="data.role"
                    :options="roleOptions"
                    optionLabel="label"
                    optionValue="value"
                    @change="(e) => updateUserRole(data, e.value)"
                    class="w-32"
                >
                  <template #value="{ value }">
                    <Tag
                        :value="roleOptions.find(r => r.value === value)?.label"
                        :severity="getRoleSeverity(value)"
                    />
                  </template>
                  <template #option="{ option }">
                    <div>
                      <div class="font-medium">{{ option.label }}</div>
                      <div class="text-xs text-gray-500">{{ option.description }}</div>
                    </div>
                  </template>
                </Dropdown>
              </template>
            </Column>
            <Column field="assigned_at" header="分配时间">
              <template #body="{ data }">
                {{ new Date(data.assigned_at).toLocaleDateString() }}
              </template>
            </Column>
            <Column header="操作" style="width: 100px">
              <template #body="{ data }">
                <Button
                    icon="pi pi-trash"
                    size="small"
                    severity="danger"
                    text
                    @click="removeUser(data)"
                    title="移除用户"
                />
              </template>
            </Column>
            <template #empty>
              <div class="text-center py-4 text-gray-500">
                暂未分配用户
              </div>
            </template>
          </DataTable>
        </template>
      </Card>

      <!-- 分配用户对话框 -->
      <Dialog
          v-model:visible="showUserDialog"
          header="分配用户到项目"
          :style="{ width: '800px' }"
          modal
      >
        <div class="flex flex-row gap-6">
          <div class="flex-1">
            <label class="block text-sm font-medium mb-2">选择用户</label>
            <DataTable
                :value="availableUsers.filter(u => !assignedUsers.find(au => au.sys_user_id === u.id))"
                v-model:selection="selectedUsersForAssign"
                selectionMode="multiple"
                dataKey="id"
                size="small"
                scrollable
                scrollHeight="300px"
            >
              <Column selectionMode="multiple" headerStyle="width: 3rem"></Column>
              <Column header="用户">
                <template #body="{ data }">
                  <div class="flex items-center gap-2">
                    <Avatar
                        :label="data.initials || data.name?.[0]"
                        size="small"
                    />
                    <div>
                      <div class="font-medium">{{ data.name }}</div>
                      <div class="text-xs text-gray-500">{{ data.email }}</div>
                    </div>
                  </div>
                </template>
              </Column>
              <template #empty>
                <div class="text-center py-4 text-gray-500">
                  所有用户已分配
                </div>
              </template>
            </DataTable>
          </div>

          <div class="flex-1">
            <label class="block text-sm font-medium mb-2">选择角色</label>
            <div class="grid grid-cols-1 gap-2">
              <div
                  v-for="role in roleOptions"
                  :key="role.value"
                  class="flex items-center p-3 border border-surface rounded cursor-pointer hover:bg-gray-50"
                  :class="{ 'border-blue-500 bg-blue-50': currentUserRole === role.value }"
                  @click="currentUserRole = role.value"
              >
                <input
                    type="radio"
                    :value="role.value"
                    v-model="currentUserRole"
                    class="mr-3"
                />
                <div class="flex-1">
                  <div class="font-medium">{{ role.label }}</div>
                  <div class="text-sm text-gray-500">{{ role.description }}</div>
                </div>
                <Tag :value="role.label" :severity="getRoleSeverity(role.value)"/>
              </div>
            </div>
          </div>
        </div>

        <template #footer>
          <Button
              label="取消"
              icon="pi pi-times"
              @click="showUserDialog = false"
              text
          />
          <Button
              label="确定分配"
              icon="pi pi-check"
              @click="assignUsers"
              :disabled="!selectedUsersForAssign || selectedUsersForAssign.length === 0"
          />
        </template>
      </Dialog>

      <!-- 自动化规则 -->
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
          <div class="space-y-4">

            <!-- 规则列表 -->
            <DataTable
                :value="formattedRules"
                :loading="loadingRules"
                size="small"
            >
              <Column field="name" header="规则名称"/>
              <Column field="condition" header="触发条件"/>
              <Column field="actionDisplay" header="执行动作"/>
              <Column header="状态" style="width: 120px">
                <template #body="{ data }">
                  <ToggleButton
                      v-model="data.enabled"
                      @change="toggleRule(data)"
                      onLabel="启用"
                      offLabel="禁用"
                      size="small"
                  />
                </template>
              </Column>
              <Column header="操作" style="width: 150px">
                <template #body="{ data }">
                  <div class="flex gap-2">
                    <Button
                        @click="openEditRuleDialog(data)"
                        icon="pi pi-pencil"
                        size="small"
                        severity="secondary"
                        text
                    />
                    <Button
                        @click="deleteRule(data.id)"
                        icon="pi pi-trash"
                        size="small"
                        severity="danger"
                        text
                    />
                  </div>
                </template>
              </Column>
              <template #empty>
                <div class="text-center py-4 text-gray-500">
                  暂无自动化规则
                </div>
              </template>
            </DataTable>
          </div>
        </template>
      </Card>

      <!-- 自动化日志 -->
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-history text-teal-600 mr-2"></i>
            自动化日志
          </div>
        </template>
        <template #content>
          <AutomationLogsTab :projectId="parseInt(projectId)"/>
        </template>
      </Card>
    </div>
  </div>

  <!-- 自动化规则对话框 -->
  <AutomationRuleDialog
    v-model:visible="showRuleDialog"
    :rule="editingRule"
    :projectId="parseInt(projectId)"
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
.space-y-4 > * + * {
  margin-top: 1rem;
}

.space-y-3 > * + * {
  margin-top: 0.75rem;
}

.space-y-2 > * + * {
  margin-top: 0.5rem;
}

.space-y-6 > * + * {
  margin-top: 1.5rem;
}

.space-y-1 > * + * {
  margin-top: 0.25rem;
}

.space-y-0\.5 > * + * {
  margin-top: 0.125rem;
}
</style>
