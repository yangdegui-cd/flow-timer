/**
 * 监控相关类型定义
 */

// 监控指标类型
export type MetricType = 'counter' | 'gauge' | 'histogram' | 'summary'

// 警报级别类型
export type AlertLevel = 'info' | 'warning' | 'error' | 'critical'

// 警报状态类型
export type AlertStatus = 'active' | 'resolved' | 'suppressed'

// 系统指标接口
export interface SystemMetrics {
  timestamp: string
  cpu_usage: number
  memory_usage: number
  disk_usage: number
  network_in: number
  network_out: number
  active_connections: number
  queue_size: number
  response_time: number
}

// 应用指标接口
export interface AppMetrics {
  timestamp: string
  active_flows: number
  running_executions: number
  completed_executions_today: number
  failed_executions_today: number
  success_rate: number
  average_execution_time: number
  peak_concurrent_executions: number
  error_rate: number
}

// 警报规则接口
export interface AlertRule {
  id: number
  name: string
  description?: string
  metric: string
  condition: string
  threshold: number
  level: AlertLevel
  is_enabled: boolean
  cooldown_period: number
  notification_channels: string[]
  created_at: string
  updated_at: string
  last_triggered_at?: string
  trigger_count: number
}

// 警报记录接口
export interface Alert {
  id: number
  rule_id: number
  level: AlertLevel
  status: AlertStatus
  title: string
  message: string
  metric_value: number
  threshold: number
  triggered_at: string
  resolved_at?: string
  acknowledged_at?: string
  acknowledged_by?: string
  rule?: AlertRule
}

// 警报规则表单数据
export interface AlertRuleFormData {
  name: string
  description?: string
  metric: string
  condition: string
  threshold: number
  level: AlertLevel
  is_enabled: boolean
  cooldown_period: number
  notification_channels: string[]
}

// 日志级别类型
export type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal'

// 日志接口
export interface Log {
  id: number
  timestamp: string
  level: LogLevel
  source: string
  message: string
  context?: Record<string, any>
  flow_id?: number
  execution_id?: number
  task_id?: number
  user_id?: number
  ip_address?: string
  user_agent?: string
}

// 日志查询参数
export interface LogQuery {
  level?: LogLevel[]
  source?: string[]
  start_time?: string
  end_time?: string
  flow_id?: number
  execution_id?: number
  task_id?: number
  user_id?: number
  keyword?: string
  page?: number
  per_page?: number
}

// 性能监控接口
export interface PerformanceMetric {
  id: number
  timestamp: string
  endpoint: string
  method: string
  status_code: number
  response_time: number
  memory_usage: number
  cpu_usage: number
  query_count: number
  query_time: number
  cache_hit_rate: number
  error_count: number
}

// 健康检查接口
export interface HealthCheck {
  timestamp: string
  status: 'healthy' | 'degraded' | 'unhealthy'
  version: string
  uptime: number
  checks: {
    database: { status: string; response_time: number }
    redis: { status: string; response_time: number }
    external_apis: { status: string; response_time: number }
    disk_space: { status: string; available: number; total: number }
    memory: { status: string; used: number; total: number }
  }
}

// 监控仪表板配置
export interface DashboardWidget {
  id: string
  type: 'chart' | 'metric' | 'table' | 'alert'
  title: string
  description?: string
  position: { x: number; y: number; width: number; height: number }
  config: {
    metric?: string
    timeRange?: string
    refreshInterval?: number
    chartType?: 'line' | 'bar' | 'pie' | 'gauge'
    thresholds?: Array<{ value: number; color: string }>
  }
}

export interface Dashboard {
  id: number
  name: string
  description?: string
  is_default: boolean
  widgets: DashboardWidget[]
  created_at: string
  updated_at: string
  created_by_user?: { id: number; name: string }
}

// 通知渠道接口
export interface NotificationChannel {
  id: number
  name: string
  type: 'email' | 'slack' | 'webhook' | 'sms'
  config: {
    webhook_url?: string
    email_addresses?: string[]
    slack_channel?: string
    slack_token?: string
    phone_numbers?: string[]
  }
  is_enabled: boolean
  created_at: string
  updated_at: string
}