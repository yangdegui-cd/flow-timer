import { BaseApi } from './base-api'
import type {
  AuditLogListParams,
  AuditLogListResponse,
  HealthCheckResponse,
  SysLogListParams,
  SysLogListResponse,
  SysLogStats,
  SystemStats
} from '@/data/types/system-types'

// 系统API类
export class SystemApi extends BaseApi {
  constructor() {
    super('sys_logs')
  }

  // 获取系统统计信息
  async getStats(): Promise<SystemStats> {
    return this.get<SystemStats>('stats')
  }

  // 获取审计日志列表
  async getAuditLogs(params?: AuditLogListParams): Promise<AuditLogListResponse> {
    return this.get<AuditLogListResponse>('audit_logs', params)
  }

  // 导出审计日志
  async exportAuditLogs(params?: AuditLogListParams): Promise<Blob> {
    const response = await BaseApi.apiRequest<Blob>('GET', '/system/audit_logs/export', null, params)
    return response
  }

  // 获取系统健康检查
  async healthCheck(): Promise<HealthCheckResponse> {
    return this.get<HealthCheckResponse>('health')
  }

  // 获取系统日志统计
  async getLogStats(): Promise<SysLogStats> {
    return this.get<SysLogStats>('logs/stats')
  }

  // 获取系统日志列表
  async getSysLogs(params?: SysLogListParams): Promise<SysLogListResponse> {
    return this.get<SysLogListResponse>('logs', params)
  }
}

// 导出单例实例
const systemApi = new SystemApi()
export default systemApi
