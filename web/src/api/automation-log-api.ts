import { BaseApi } from './base-api'

// 自动化日志类型
export interface AutomationLog {
  id: number
  project_id: number
  sys_user_id: number | null
  action_type: string
  action: string
  duration: number | null
  status: string
  remark: Record<string, any>
  created_at: string
  updated_at: string
  duration_in_seconds: number | null
  display_status: string
  display_name: string
  sys_user?: {
    id: number
    name: string
    email: string
    initials: string
  }
  project?: {
    id: number
    name: string
  }
}

// 日志列表响应
export interface AutomationLogListResponse {
  logs: AutomationLog[]
  pagination: {
    current_page: number
    per_page: number
    total: number
    total_pages: number
  }
}

// 日志统计响应
export interface AutomationLogStatsResponse {
  total: number
  success: number
  failed: number
  by_action_type: Record<string, number>
  by_status: Record<string, number>
  recent_24h: number
}

// 日志查询参数
export interface AutomationLogQueryParams {
  action_type?: string
  status?: string
  user_id?: number
  start_date?: string
  end_date?: string
  search?: string
  page?: number
  per_page?: number
}

// 自动化日志 API 类
class AutomationLogApi extends BaseApi {
  constructor() {
    super('automation_logs')
  }

  // 获取所有项目的日志列表(全局查询)
  async getAllLogs(params?: AutomationLogQueryParams): Promise<AutomationLogListResponse> {
    return BaseApi.apiRequest<AutomationLogListResponse>(
      'GET',
      '/automation_logs',
      null,
      params
    )
  }

  // 获取项目的日志列表
  async getProjectLogs(
    projectId: number,
    params?: AutomationLogQueryParams
  ): Promise<AutomationLogListResponse> {
    return BaseApi.apiRequest<AutomationLogListResponse>(
      'GET',
      `/projects/${projectId}/automation_logs`,
      null,
      params
    )
  }

  // 获取日志详情
  async getLog(id: number): Promise<AutomationLog> {
    return BaseApi.apiRequest<AutomationLog>('GET', `/automation_logs/${id}`)
  }

  // 获取日志统计
  async getStats(projectId: number, params?: Partial<AutomationLogQueryParams>): Promise<AutomationLogStatsResponse> {
    return BaseApi.apiRequest<AutomationLogStatsResponse>(
      'GET',
      `/projects/${projectId}/automation_logs/stats`,
      null,
      params
    )
  }
}

// 导出单例实例
const automationLogApi = new AutomationLogApi()
export default automationLogApi
export { AutomationLogApi }
