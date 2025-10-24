<script setup lang="ts">
import { computed, onMounted, ref, defineComponent, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import PageHeader from '@/views/layer/PageHeader.vue'
import AutomationLogsTab from './AutomationLogsTab.vue'
import projectApi, { projectStatusOptions } from '@/api/project-api'
import automationRuleApi, { type AutomationRule, type AutomationRuleFormData } from '@/api/automation-rule-api'
import { adsAccountApi } from '@/api/ads-account-api'
import userProjectApi, { type UserProject, type ProjectRole } from '@/api/user-project-api'
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
import InputNumber from 'primevue/inputnumber'
import Dialog from 'primevue/dialog'
import Divider from 'primevue/divider'
import { Project } from "@/data/types/project-types"

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
  sys_users: [],
  user_count: 0
})

// 编辑表单
const form = ref({
  name: '',
  description: '',
  start_date: null as Date | null,
  status: 'active',
  active_ads_automate: true
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
const editingRule = ref<any>(null) // 正在编辑的规则
const isRuleEditMode = ref(false) // 是否为规则编辑模式

// 条件编辑对话框
const showConditionDialog = ref(false)
const targetGroup = ref<TriggerCondition | null>(null) // 要添加条件的目标组
const editingCondition = ref<TriggerCondition | null>(null) // 正在编辑的条件
const isConditionEditMode = ref(false) // 是否为条件编辑模式

// 单个触发条件的结构
interface TriggerCondition {
  id: number
  type: 'condition' | 'group' // 条件或条件组
  metricType?: 'numeric' | 'string' // 指标类型（仅用于条件）
  metric?: string // 触发指标（仅用于条件）
  operator?: string // 操作符（仅用于条件）
  value?: number | string // 触发值（仅用于条件）
  logic?: 'AND' | 'OR' // 条件组的逻辑关系（仅用于条件组）
  children?: TriggerCondition[] // 子条件（仅用于条件组）
}

const newRule = ref({
  name: '',
  // 时间参数
  timeGranularity: 'hour', // hour | day
  timeRange: 1,
  // 触发条件（根条件组）
  conditionGroup: {
    id: Date.now(),
    type: 'group' as const,
    logic: 'AND' as 'AND' | 'OR',
    children: [] as TriggerCondition[]
  },
  // 触发动作
  action: 'pause_ad', // pause_ad, add_ad, increase_bid, decrease_bid, increase_budget, decrease_budget
  actionValue: 0, // 对于百分比调整类动作，存储百分比值
  enabled: true
})

// 当前正在编辑的条件
const currentCondition = ref<TriggerCondition>({
  id: Date.now(),
  type: 'condition',
  metricType: 'numeric',
  metric: 'cpi',
  operator: 'gt',
  value: 0
})

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

// 触发动作选项
const actionOptions = [
  { label: '添加广告', value: 'add_ad', needsValue: false },
  { label: '暂停广告', value: 'pause_ad', needsValue: false },
  { label: '提升出价', value: 'increase_bid', needsValue: true, unit: '%' },
  { label: '降低出价', value: 'decrease_bid', needsValue: true, unit: '%' },
  { label: '提升预算', value: 'increase_budget', needsValue: true, unit: '%' },
  { label: '降低预算', value: 'decrease_budget', needsValue: true, unit: '%' }
]

// 模拟的已有数据（用于下拉选择）
const availableAccountNames = ref(['账号A', '账号B', '账号C'])
const availableCampaignNames = ref(['春季推广', '夏季活动', '秋季促销'])
const availableAdsetNames = ref(['年轻人群', '中年人群', '高收入人群'])
const availableAdNames = ref(['创意A', '创意B', '创意C'])

// 计算属性：当前条件选中的指标信息
const currentSelectedMetric = computed(() => {
  return allMetricOptions.find(m => m.value === currentCondition.value.metric)
})

// 计算属性：当前条件的操作符选项
const currentOperatorOptions = computed(() => {
  return currentCondition.value.metricType === 'numeric'
    ? numericOperatorOptions
    : stringOperatorOptions
})

// 计算属性：当前选中的动作信息
const selectedAction = computed(() => {
  return actionOptions.find(a => a.value === newRule.value.action)
})

// 计算属性：格式化的时间范围描述
const timeRangeDescription = computed(() => {
  const unit = newRule.value.timeGranularity === 'hour' ? '小时' : '天'
  return `最近 ${newRule.value.timeRange} ${unit}`
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
      return availableAccountNames.value
    case 'campaign_name':
      return availableCampaignNames.value
    case 'adset_name':
      return availableAdsetNames.value
    case 'ad_name':
      return availableAdNames.value
    default:
      return []
  }
})

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
      active_ads_automate: data.active_ads_automate
    }
    // 加载关联数据
    Promise.all([
      loadProjectAdsAccounts(),
      loadProjectUsers(),
      loadAutomationRules()
    ])
  }).catch(error => {
    console.error('加载项目失败:', error)
    toast.add({ severity: 'error', summary: '错误', detail: '加载项目失败', life: 3000 })
  }).finally(() => {
    loading.value = false
  })
}

// 加载自动化规则
const loadAutomationRules = async () => {
  if (projectId.value === 'new') return

  loadingRules.value = true
  try {
    const rules = await automationRuleApi.getProjectRules(parseInt(projectId.value))
    automationRules.value = rules
  } catch (error: any) {
    console.error('加载自动化规则失败:', error)
    const message = error?.msg ?? '加载自动化规则失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  } finally {
    loadingRules.value = false
  }
}

// 加载可用的广告账户（未绑定或已绑定到当前项目的账户）
const loadAvailableAdsAccounts = async () => {
  try {
    const response = await adsAccountApi.getAvailableAccounts(parseInt(projectId.value))
    availableAdsAccounts.value = response.data
  } catch (error: any) {
    console.error('加载可用广告账户失败:', error)
    const message = error?.msg ?? '加载可用广告账户失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 加载项目绑定的广告账户
const loadProjectAdsAccounts = async () => {
  try {
    const response = await adsAccountApi.getAdsAccounts(parseInt(projectId.value))
    adsAccounts.value = response.data || []
  } catch (error: any) {
    console.error('加载项目广告账户失败:', error)
    const message = error?.msg ?? '加载项目广告账户失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 加载项目分配的用户
const loadProjectUsers = async () => {
  try {
    const users = await userProjectApi.getProjectUsers(parseInt(projectId.value))
    assignedUsers.value = users
  } catch (error: any) {
    console.error('加载项目用户失败:', error)
    const message = error?.msg ?? '加载项目用户失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 加载可用用户（所有系统用户）
const loadAvailableUsers = async () => {
  userApi.list().then(res => {
    availableUsers.value = res.users
  }).catch(res => {
    toast.add({ severity: 'error', summary: '加载可用用户失败', detail: res.data.msg, life: 3000 })
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
    }).catch(error => {
      console.error('保存项目失败:', error)
      toast.add({ severity: 'error', summary: '错误', detail: '保存项目失败', life: 3000 })
    }).finally(() => {
      saving.value = false
    })
  } else {
    projectApi.update(parseInt(projectId.value), formData).then(() => {
      loadProject()
      isEditMode.value = false
      toast.add({ severity: 'success', summary: '成功', detail: '项目更新成功', life: 3000 })
    }).catch(error => {
      console.error('保存项目失败:', error)
      toast.add({ severity: 'error', summary: '错误', detail: '保存项目失败', life: 3000 })
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
    active_ads_automate: project.value.active_ads_automate
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
  } catch (error: any) {
    console.error('绑定广告账户失败:', error)
    const message = error?.msg ?? '绑定失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
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
      } catch (error: any) {
        console.error('解绑广告账户失败:', error)
        const message = error?.msg ?? '解绑失败'
        toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
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
  } catch (error: any) {
    console.error('分配用户失败:', error)
    const message = error?.msg ?? '分配失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 更新用户角色
const updateUserRole = async (userProject: UserProject, newRole: ProjectRole) => {
  try {
    await userProjectApi.updateUserRole(userProject.id, newRole)
    toast.add({ severity: 'success', summary: '成功', detail: '角色更新成功', life: 3000 })
    await loadProjectUsers()
  } catch (error: any) {
    console.error('更新角色失败:', error)
    const message = error?.msg ?? '更新失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
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
      } catch (error: any) {
        console.error('移除用户失败:', error)
        const message = error?.msg ?? '移除失败'
        toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
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

// 当指标类型改变时，更新操作符和值
const onMetricTypeChange = (newType: 'numeric' | 'string') => {
  currentCondition.value.metricType = newType
  // 重置操作符
  if (newType === 'numeric') {
    currentCondition.value.metric = 'cpi'
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
  const metric = allMetricOptions.find(m => m.value === currentCondition.value.metric)
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

// 添加条件到根条件组
const addConditionToRoot = () => {
  // 验证当前条件
  if (currentCondition.value.metricType === 'numeric') {
    const metric = numericMetricOptions.find(m => m.value === currentCondition.value.metric)
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

  // 添加条件到根条件组
  newRule.value.conditionGroup.children.push({ ...currentCondition.value })

  // 重置当前条件
  currentCondition.value = {
    id: Date.now() + 1,
    type: 'condition',
    metricType: 'numeric',
    metric: 'cpi',
    operator: 'gt',
    value: 0
  }

  toast.add({ severity: 'success', summary: '成功', detail: '条件添加成功', life: 2000 })
}

// 添加条件组到根条件组
const addGroupToRoot = () => {
  newRule.value.conditionGroup.children.push({
    id: Date.now(),
    type: 'group',
    logic: 'AND',
    children: []
  })
  toast.add({ severity: 'success', summary: '成功', detail: '条件组添加成功', life: 2000 })
}

// 打开条件编辑对话框
const openConditionDialog = (group: TriggerCondition) => {
  targetGroup.value = group
  // 重置当前条件
  currentCondition.value = {
    id: Date.now(),
    type: 'condition',
    metricType: 'numeric',
    metric: 'cpi',
    operator: 'gt',
    value: 0
  }
  showConditionDialog.value = true
}

// 添加条件到指定条件组
const addConditionToGroup = (group: TriggerCondition) => {
  openConditionDialog(group)
}

// 编辑条件
const editCondition = (condition: TriggerCondition) => {
  isConditionEditMode.value = true
  editingCondition.value = condition
  // 复制条件到当前编辑对象
  currentCondition.value = {
    id: condition.id,
    type: condition.type,
    metricType: condition.metricType,
    metric: condition.metric,
    operator: condition.operator,
    value: condition.value
  }
  showConditionDialog.value = true
}

// 确认添加条件
const confirmAddCondition = () => {
  // 验证当前条件
  if (currentCondition.value.metricType === 'numeric') {
    const metric = numericMetricOptions.find(m => m.value === currentCondition.value.metric)
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

  if (isConditionEditMode.value && editingCondition.value) {
    // 编辑模式：更新现有条件
    editingCondition.value.metricType = currentCondition.value.metricType
    editingCondition.value.metric = currentCondition.value.metric
    editingCondition.value.operator = currentCondition.value.operator
    editingCondition.value.value = currentCondition.value.value
    // 强制更新
    newRule.value = { ...newRule.value }
    toast.add({ severity: 'success', summary: '成功', detail: '条件更新成功', life: 2000 })
  } else {
    // 添加模式：添加新条件
    if (!targetGroup.value) return
    if (!targetGroup.value.children) targetGroup.value.children = []
    targetGroup.value.children.push({ ...currentCondition.value })
    toast.add({ severity: 'success', summary: '成功', detail: '条件添加成功', life: 2000 })
  }

  showConditionDialog.value = false
  isConditionEditMode.value = false
  editingCondition.value = null
}

// 从条件组中删除条件或子条件组
const removeFromGroup = (group: TriggerCondition, itemId: number) => {
  if (group.children) {
    group.children = group.children.filter(c => c.id !== itemId)
  }
}

// 递归删除条件或条件组
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

// 格式化单个条件显示
const formatConditionText = (condition: TriggerCondition): string => {
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
const formatConditionGroupText = (group: TriggerCondition, depth: number = 0): string => {
  if (!group.children || group.children.length === 0) {
    return ''
  }

  const texts = group.children.map(child => {
    if (child.type === 'condition') {
      return formatConditionText(child)
    } else {
      // 递归处理子条件组
      const subText = formatConditionGroupText(child, depth + 1)
      return depth > 0 ? `(${subText})` : subText
    }
  }).filter(t => t)

  const logicSymbol = group.logic === 'AND' ? ' 且 ' : ' 或 '
  return texts.join(logicSymbol)
}

// 打开添加规则对话框
const openRuleDialog = () => {
  isRuleEditMode.value = false
  editingRule.value = null
  resetRuleForm()
  showRuleDialog.value = true
}

// 打开编辑规则对话框
const openEditRuleDialog = (rule: AutomationRule) => {
  isRuleEditMode.value = true
  editingRule.value = rule

  // 复制规则数据到编辑表单（处理后端返回的snake_case格式）
  newRule.value = {
    name: rule.name,
    timeGranularity: rule.time_granularity || 'hour',
    timeRange: rule.time_range || 1,
    conditionGroup: rule.condition_group ? JSON.parse(JSON.stringify(rule.condition_group)) : {
      id: Date.now(),
      type: 'group',
      logic: 'AND',
      children: []
    },
    action: rule.action || 'pause_ad',
    actionValue: rule.action_value || 0,
    enabled: rule.enabled
  }

  showRuleDialog.value = true
}

// 重置规则表单
const resetRuleForm = () => {
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

  currentCondition.value = {
    id: Date.now() + 1,
    type: 'condition',
    metricType: 'numeric',
    metric: 'cpi',
    operator: 'gt',
    value: 0
  }
}

// 添加自动化规则
const addAutomationRule = async () => {
  if (!newRule.value.name) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请输入规则名称', life: 3000 })
    return
  }

  // 验证至少有一个条件
  if (!newRule.value.conditionGroup.children || newRule.value.conditionGroup.children.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请至少添加一个触发条件', life: 3000 })
    return
  }

  // 验证动作值（如果需要）
  if (selectedAction.value?.needsValue && (!newRule.value.actionValue || newRule.value.actionValue <= 0)) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请输入有效的百分比值', life: 3000 })
    return
  }

  saving.value = true

  try {
    // 准备API数据
    const ruleData: AutomationRuleFormData = {
      name: newRule.value.name,
      time_granularity: newRule.value.timeGranularity,
      time_range: newRule.value.timeRange,
      condition_group: newRule.value.conditionGroup,
      action: newRule.value.action,
      action_value: newRule.value.actionValue,
      enabled: newRule.value.enabled
    }

    if (isRuleEditMode.value && editingRule.value) {
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
    isRuleEditMode.value = false
    editingRule.value = null
  } catch (error: any) {
    console.error('保存规则失败:', error)
    const defaultMessage = isRuleEditMode.value ? '更新规则失败' : '添加规则失败'
    const message = error?.msg ?? defaultMessage
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
      } catch (error: any) {
        console.error('删除规则失败:', error)
        const message = error?.msg ?? '删除规则失败'
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
  } catch (error: any) {
    console.error('切换规则状态失败:', error)
    // 恢复之前的状态
    rule.enabled = previousState
    const message = error?.msg ?? '切换规则状态失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
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
    const actionOption = actionOptions.find(a => a.value === rule.action)
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
    loadProjectUsers()
  ])
})

// 切换条件组逻辑（不使用ref，直接修改对象）
const toggleGroupLogic = (group: TriggerCondition) => {
  if (group.logic === 'AND') {
    group.logic = 'OR'
  } else {
    group.logic = 'AND'
  }
  // 强制更新
  newRule.value = { ...newRule.value }
}

// 条件组显示组件（递归）
const ConditionGroupDisplay = defineComponent({
  name: 'ConditionGroupDisplay',
  props: {
    group: {
      type: Object as () => TriggerCondition,
      required: true
    },
    level: {
      type: Number,
      default: 0
    }
  },
  emits: ['remove', 'addCondition', 'addGroup', 'edit'],
  setup(props, { emit }) {
    // 渲染单个条件
    const renderCondition = (condition: TriggerCondition, index: number, parentGroup: TriggerCondition, showLogic: boolean = false) => {
      const metric = allMetricOptions.find(m => m.value === condition.metric)
      const operator = [...numericOperatorOptions, ...stringOperatorOptions].find(o => o.value === condition.operator)

      let valueText = ''
      if (condition.metricType === 'numeric') {
        const numMetric = numericMetricOptions.find(m => m.value === condition.metric)
        valueText = `${condition.value}${numMetric?.unit || ''}`
      } else {
        valueText = `"${condition.value}"`
      }

      const parentLogic = parentGroup.logic || 'AND'

      return h('div', { class: 'flex items-center gap-2 py-1', key: condition.id }, [
        // 逻辑标签（只在需要时显示）
        showLogic ? h('div', {
          class: `px-2 py-1 rounded text-xs cursor-pointer w-9 text-center bg-gray-100 text-gray-600 hover:bg-gray-200`,
          onClick: () => toggleGroupLogic(parentGroup)
        }, parentLogic === 'AND' ? '或' : '且') : h('div', { class: 'w-9' }), // 占位

        // adid按钮（点击可编辑条件）
        h(Button, {
          icon: 'pi pi-filter-slash',
          size: 'small',
          severity: 'secondary',
          outlined: true,
          class: 'h-7 w-16 text-xs p-0 flex-shrink-0',
          onClick: () => emit('edit', condition)
        }),

        // 条件显示
        h('div', {
          class: 'flex items-center gap-2 px-3 py-1.5 bg-white border border-gray-200 rounded text-sm flex-1'
        }, [
          h('span', { class: 'text-gray-700' }, `${metric?.label} ${operator?.symbol} ${valueText}`)
        ]),

        // 删除按钮（始终显示）
        h(Button, {
          icon: 'pi pi-times',
          size: 'small',
          severity: 'secondary',
          text: true,
          class: 'h-6 w-6 p-0',
          onClick: () => emit('remove', condition.id)
        })
      ])
    }

    // 渲染条件组
    const renderGroup = (group: TriggerCondition, level: number, parentGroup?: TriggerCondition, indexInParent: number = 0): any => {
      const hasChildren = group.children && group.children.length > 0

      const elements: any[] = []

      // 条件组容器
      const groupContent = h('div', {
        class: level > 0 ? 'relative' : ''
      }, [
        // 左侧竖线
        level > 0 && h('div', {
          class: 'absolute top-0 bottom-0 w-px bg-gray-300'
        }),

        // 内容容器
        h('div', {
          class: level > 0 ? 'pl-2' : ''
        }, [
          // 子条件和子条件组
          ...(hasChildren ? (() => {
            // 判断是否有多个子项（条件或条件组）
            const hasMultipleChildren = group.children!.length > 1

            return group.children!.map((child, index) => {
              if (child.type === 'condition') {
                // 只在第一项处且有多个子项时显示逻辑符号
                const showLogic = hasMultipleChildren && index === 0
                return renderCondition(child, index, group, showLogic)
              } else {
                // 递归渲染子条件组
                // 只在第一项处且有多个子项时显示逻辑操作符
                const showLogic = hasMultipleChildren && index === 0
                return h('div', { key: child.id, class: 'flex items-start gap-2 py-1' }, [
                  // 左侧逻辑操作符（只在第一项显示）
                  showLogic ? (() => {
                    const parentLogic = group.logic || 'AND'
                    return h('div', {
                      class: `px-2 py-1 rounded text-xs cursor-pointer w-9 text-center bg-gray-100 text-gray-600 hover:bg-gray-200 flex-shrink-0`,
                      onClick: () => toggleGroupLogic(group)
                    }, parentLogic === 'AND' ? '或' : '且')
                  })() : h('div', { class: 'w-9 flex-shrink-0' }),
                  // 子条件组内容
                  h('div', { class: 'flex-1' }, [
                    renderGroup(child, level + 1, group, index)
                  ])
                ])
              }
            })
          })() : [
            h('div', { class: 'text-sm text-gray-400 py-2 ml-11' }, '暂无条件')
          ]),

          // 底部添加按钮（和删除组按钮放在一起）
          h('div', { class: 'flex gap-2 py-2 ml-11' }, [
            h(Button, {
              icon: 'pi pi-plus',
              label: '添加条件',
              size: 'small',
              severity: 'secondary',
              outlined: true,
              class: 'h-8 px-4 text-sm',
              onClick: () => emit('addCondition', group)
            }),
            level === 0 && h(Button, {
              icon: 'pi pi-sitemap',
              label: '添加条件组',
              size: 'small',
              severity: 'secondary',
              outlined: true,
              class: 'h-8 px-4 text-sm',
              onClick: () => emit('addGroup')
            }),
            // 如果是嵌套组（level > 0），显示删除组按钮
            level > 0 && h(Button, {
              icon: 'pi pi-trash',
              label: '删除组',
              size: 'small',
              severity: 'secondary',
              text: true,
              class: 'h-8 text-sm',
              onClick: () => emit('remove', group.id)
            })
          ])
        ])
      ])

      elements.push(groupContent)

      return h('div', elements)
    }

    return () => renderGroup(props.group, props.level)
  }
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
                <Tag :value="role.label" :severity="getRoleSeverity(role.value)" />
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
          <AutomationLogsTab :projectId="parseInt(projectId)" />
        </template>
      </Card>
    </div>
  </div>

  <!-- 添加/编辑规则对话框 -->
  <Dialog
      v-model:visible="showRuleDialog"
      modal
      :header="isRuleEditMode ? '编辑自动化规则' : '添加自动化规则'"
      :style="{ width: '800px', maxWidth: '90vw' }"
      :dismissableMask="true"
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
            placeholder="例如：高CPI自动暂停"
            class="w-full"
        />
      </div>

      <Divider/>

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

      <Divider/>

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
            @remove="removeConditionOrGroup"
            @add-condition="addConditionToGroup"
            @add-group="addGroupToRoot"
            @edit="editCondition"
        />

      </div>

      <Divider/>

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

      <Divider/>

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
            :disabled="saving"
            @click="showRuleDialog = false"
        />
        <Button
            :label="isRuleEditMode ? '保存' : '添加规则'"
            :loading="saving"
            @click="addAutomationRule"
        />
      </div>
    </template>
  </Dialog>

  <!-- 条件编辑对话框 -->
  <Dialog
      v-model:visible="showConditionDialog"
      modal
      :header="isConditionEditMode ? '编辑条件' : '添加条件'"
      :style="{ width: '700px' }"
      :dismissableMask="true"
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
          <Dropdown
              v-model="currentCondition.metric"
              :options="currentCondition.metricType === 'numeric' ? numericMetricOptions : stringMetricOptions"
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
        有效范围: {{ currentSelectedMetric.min }} - {{ currentSelectedMetric.max }}
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
            label="取消"
            severity="secondary"
            @click="showConditionDialog = false"
        />
        <Button
            :label="isConditionEditMode ? '保存' : '确定'"
            @click="confirmAddCondition"
        />
      </div>
    </template>
  </Dialog>
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
