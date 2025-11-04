import { BaseApi } from './base-api'

// 自动化规则条件类型
export interface AutomationCondition {
  id: number
  type: 'condition' | 'group'
  metricType?: 'numeric' | 'string'
  metric?: string
  operator?: string
  value?: number | string
  logic?: 'AND' | 'OR'
  children?: AutomationCondition[]
}

// 时间范围配置类型
export interface TimeRangeConfig {
  start_date: {
    type: 'absolute' | 'relative'
    date: string | number
  }
  end_date: {
    type: 'absolute' | 'relative'
    date: string | number
  }
}

// 自动化规则类型
export interface AutomationRule {
  id: number
  project_id: number
  name: string
  time_type: 'recent' | 'range'
  time_granularity: 'hour' | 'day'
  time_range: number
  time_range_config?: TimeRangeConfig
  condition_group: AutomationCondition
  action: string
  action_value?: number
  enabled: boolean
  created_at?: string
  updated_at?: string
}

// 创建/更新规则请求类型
export interface AutomationRuleFormData {
  name: string
  time_type: 'recent' | 'range'
  time_granularity: 'hour' | 'day'
  time_range: number
  time_range_config?: TimeRangeConfig
  condition_group: AutomationCondition
  action: string
  action_value?: number
  enabled: boolean
}

// 规则列表响应类型
export interface AutomationRuleListResponse {
  rules: AutomationRule[]
  pagination?: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

// 自动化规则API类
class AutomationRuleApi extends BaseApi {
  constructor() {
    super('automation_rules')
  }

  // 获取项目的规则列表
  async getProjectRules(projectId: number): Promise<AutomationRule[]> {
    const url = `/projects/${projectId}/automation_rules`
    return BaseApi.apiRequest<AutomationRule[]>('GET', url)
  }

  // 创建规则
  async createRule(projectId: number, data: AutomationRuleFormData): Promise<AutomationRule> {
    const url = `/projects/${projectId}/automation_rules`
    return BaseApi.apiRequest<AutomationRule>('POST', url, data)
  }

  // 更新规则
  async updateRule(id: number, data: AutomationRuleFormData): Promise<AutomationRule> {
    return this.update<AutomationRule>(id, data)
  }

  // 删除规则
  async deleteRule(id: number): Promise<void> {
    return this.delete<void>(id)
  }

  // 切换规则启用状态
  async toggleRule(id: number, enabled: boolean): Promise<AutomationRule> {
    return this.patch<AutomationRule>(`${id}/toggle`, { enabled })
  }

  // 获取单个规则详情
  async getRule(id: number): Promise<AutomationRule> {
    return this.show<AutomationRule>(id)
  }
}

// 导出单例实例
const automationRuleApi = new AutomationRuleApi()
export default automationRuleApi

// 也可以导出类，以便其他地方使用
export { AutomationRuleApi }
