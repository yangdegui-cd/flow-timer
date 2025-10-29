/**
 * 自动化触发动作选项配置
 * 用于项目规则配置和日志展示
 */

export interface AutomationAction {
  label: string
  value: string
  severity: 'success' | 'warning' | 'danger' | 'info'
  needsValue: boolean
  unit?: string
}

/**
 * 自动化触发动作选项列表
 */
export const actionOptions: AutomationAction[] = [
  {
    label: '预警',
    value: 'alert',
    severity: 'info',
    needsValue: false
  },
  {
    label: '暂停广告',
    value: 'pause_ad',
    severity: 'danger',
    needsValue: false
  },
  {
    label: '提升出价',
    value: 'increase_bid',
    severity: 'success',
    needsValue: true,
    unit: '%'
  },
  {
    label: '降低出价',
    value: 'decrease_bid',
    severity: 'warning',
    needsValue: true,
    unit: '%'
  },
  {
    label: '提升预算',
    value: 'increase_budget',
    severity: 'success',
    needsValue: true,
    unit: '%'
  },
  {
    label: '降低预算',
    value: 'decrease_budget',
    severity: 'warning',
    needsValue: true,
    unit: '%'
  }
]

/**
 * 根据 value 获取动作配置
 */
export const getActionByValue = (value: string): AutomationAction | undefined => {
  return actionOptions.find(action => action.value === value)
}

/**
 * 根据 value 获取动作标签
 */
export const getActionLabel = (value: string): string => {
  return getActionByValue(value)?.label || value
}

/**
 * 根据 value 获取动作严重程度
 */
export const getActionSeverity = (value: string): 'success' | 'warning' | 'danger' | 'info' => {
  return getActionByValue(value)?.severity || 'info'
}

export default actionOptions
