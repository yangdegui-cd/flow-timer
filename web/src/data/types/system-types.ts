/**
 * 系统配置相关类型定义
 */

// 系统配置类型
export type ConfigCategory = 'system' | 'security' | 'notification' | 'integration' | 'performance'

// 配置值类型
export type ConfigValueType = 'string' | 'number' | 'boolean' | 'json' | 'array'

// 系统配置接口
export interface SystemConfig {
  id: number
  key: string
  value: any
  type: ConfigValueType
  category: ConfigCategory
  description?: string
  is_encrypted: boolean
  is_readonly: boolean
  default_value?: any
  validation_rules?: string
  created_at: string
  updated_at: string
}

// 系统配置表单数据
export interface SystemConfigFormData {
  key: string
  value: any
  type: ConfigValueType
  category: ConfigCategory
  description?: string
  is_encrypted: boolean
  validation_rules?: string
}

// 备份状态类型
export type BackupStatus = 'pending' | 'running' | 'completed' | 'failed'

// 备份类型
export type BackupType = 'full' | 'incremental' | 'manual'

// 备份记录接口
export interface Backup {
  id: number
  name: string
  type: BackupType
  status: BackupStatus
  file_size: number
  file_path: string
  started_at: string
  completed_at?: string
  duration?: number
  error_message?: string
  created_by_user?: { id: number; name: string }
}

// 备份配置接口
export interface BackupConfig {
  auto_backup_enabled: boolean
  backup_schedule: string
  backup_retention_days: number
  backup_location: string
  compression_enabled: boolean
  encryption_enabled: boolean
  notification_enabled: boolean
  notification_emails: string[]
}

// 系统信息接口
export interface SystemInfo {
  version: string
  build_time: string
  git_commit: string
  uptime: number
  environment: string
  ruby_version: string
  rails_version: string
  database: {
    type: string
    version: string
    size: number
    connections: number
  }
  redis: {
    version: string
    memory_usage: number
    connected_clients: number
  }
  system: {
    os: string
    cpu_cores: number
    total_memory: number
    disk_space: {
      total: number
      used: number
      available: number
    }
  }
}

// 许可证信息接口
export interface LicenseInfo {
  type: 'community' | 'professional' | 'enterprise'
  expires_at?: string
  max_flows: number
  max_users: number
  features: string[]
  is_valid: boolean
  is_expired: boolean
  days_until_expiry?: number
  license_key?: string
}

// 系统维护模式接口
export interface MaintenanceMode {
  is_enabled: boolean
  message?: string
  allowed_ips: string[]
  started_at?: string
  scheduled_end_at?: string
  created_by_user?: { id: number; name: string }
}

// 系统事件类型
export type SystemEventType = 'system_start' | 'system_stop' | 'backup_start' | 'backup_complete' |
  'maintenance_start' | 'maintenance_end' | 'config_change' | 'license_change'

// 系统事件接口
export interface SystemEvent {
  id: number
  type: SystemEventType
  title: string
  description?: string
  details?: Record<string, any>
  level: 'info' | 'warning' | 'error'
  user_id?: number
  ip_address?: string
  user_agent?: string
  created_at: string
  user?: { id: number; name: string }
}

// 数据库连接配置
export interface DatabaseConnection {
  id: number
  name: string
  type: 'mysql' | 'postgresql' | 'sqlite' | 'mongodb' | 'redis'
  host: string
  port: number
  database: string
  username: string
  password?: string
  options?: Record<string, any>
  is_default: boolean
  is_active: boolean
  connection_pool_size: number
  timeout: number
  ssl_enabled: boolean
  created_at: string
  updated_at: string
}

// 数据库连接表单数据
export interface DatabaseConnectionFormData {
  name: string
  type: 'mysql' | 'postgresql' | 'sqlite' | 'mongodb' | 'redis'
  host: string
  port: number
  database: string
  username: string
  password?: string
  options?: Record<string, any>
  connection_pool_size: number
  timeout: number
  ssl_enabled: boolean
}

// 外部集成配置
export interface ExternalIntegration {
  id: number
  name: string
  type: 'webhook' | 'api' | 'email' | 'slack' | 'github' | 'gitlab'
  config: Record<string, any>
  is_enabled: boolean
  test_endpoint?: string
  last_test_at?: string
  last_test_result?: 'success' | 'failed'
  last_test_error?: string
  created_at: string
  updated_at: string
}

// API 限流配置
export interface RateLimitConfig {
  enabled: boolean
  requests_per_minute: number
  requests_per_hour: number
  burst_limit: number
  whitelist_ips: string[]
  blacklist_ips: string[]
}

// 权限系统类型定义

export interface SysPermission {
  id: number
  code: string              // 权限标识，如 'user:create', 'role:edit'
  name: string              // 权限名称，如 '创建用户', '编辑角色'
  description?: string      // 权限描述
  module: string           // 所属模块，如 'user', 'role', 'system'
  action: string           // 操作类型，如 'create', 'read', 'update', 'delete'
  resource?: string        // 资源标识，如具体的资源路径
  is_active: boolean       // 是否启用
  is_system: boolean       // 是否系统权限
  sort_order: number       // 排序
  created_at: string
  updated_at: string
  display_name?: string    // 显示名称
}

// 为了兼容，保留Permission类型别名
export type Permission = SysPermission


export interface SysRole {
  id: number
  code: string              // 角色标识
  name: string              // 角色名称
  description?: string      // 角色描述
  is_system: boolean        // 是否系统角色（不可删除）
  is_active: boolean        // 是否启用
  sort_order: number        // 排序
  permissions: SysPermission[]        // 绑定的权限
  users_count: number       // 拥有该角色的用户数量
  created_at: string
  updated_at: string
  display_name?: string     // 显示名称
}

// API 请求接口
export interface PermissionListParams {
  page?: number
  per_page?: number
  module?: string
  is_active?: boolean
  search?: string
}


export interface CreatePermissionRequest {
  code: string
  name: string
  description?: string
  module: string
  action: string
  resource?: string
  is_active?: boolean
  sort_order?: number
}

export interface UpdatePermissionRequest {
  code?: string
  name?: string
  description?: string
  module?: string
  action?: string
  resource?: string
  is_active?: boolean
  sort_order?: number
}

export interface UpdateRolePermissionsRequest {
  permission_ids: number[]           // 绑定的权限ID
}

// API 响应接口
export interface PermissionListResponse {
  permissions: SysPermission[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

export interface ModuleListResponse {
  modules: Array<{
    code: string
    name: string
    description?: string
    permissions_count: number
  }>
}

// 系统统计信息
export interface SystemStats {
  user_stats: {
    total_users: number
    active_users: number
    inactive_users: number
    suspended_users: number
    users_registered_today: number
    users_registered_this_month: number
  }
  role_stats: {
    total_roles: number
    system_roles: number
    custom_roles: number
  }
  task_stats: {
    total_tasks: number
    running_tasks: number
    completed_tasks: number
    failed_tasks: number
    tasks_executed_today: number
    tasks_executed_this_month: number
  }
  flow_stats: {
    total_flows: number
    active_flows: number
    draft_flows: number
    flows_created_today: number
    flows_created_this_month: number
  }
  system_health: {
    status: 'healthy' | 'warning' | 'error'
    cpu_usage: number
    memory_usage: number
    disk_usage: number
    database_status: 'connected' | 'disconnected'
    redis_status: 'connected' | 'disconnected'
    last_check: string
  }
}

// 审计日志
export interface AuditLog {
  id: number
  user_id?: number
  user_name?: string
  user_email?: string
  action: string
  resource_type: string
  resource_id?: number
  resource_name?: string
  details: Record<string, any>
  ip_address: string
  user_agent: string
  created_at: string
}

// 审计日志查询参数
export interface AuditLogListParams {
  page?: number
  per_page?: number
  user_id?: number
  action?: string
  resource_type?: string
  start_date?: string
  end_date?: string
}

// 审计日志响应
export interface AuditLogListResponse {
  audit_logs: AuditLog[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

// 系统日志统计
export interface SysLogStats {
  total_requests: number
  today_requests: number
  this_week_requests: number
  error_requests: number
  slow_requests: number
  by_controller: Array<[string, number]>
  by_status: Record<string, number>
  by_user: Array<[string, number]>
  by_hour: Record<string, number>
  route_performance: Array<{
    route: string
    controller: string
    action: string
    total_requests: number
    avg_duration: number
    error_rate: number
    slow_requests: number
  }>
}

// 系统日志
export interface SysLog {
  id: number
  user: {
    id: number
    name: string
    email: string
  }
  controller_name: string
  action_name: string
  request_method: string
  request_url: string
  status_code: number
  duration: number
  formatted_duration: string
  request_time: string
  response_time: string
  ip_address: string
  error: boolean
  slow: boolean
  action_description: string
  url_params?: Record<string, any>
  body_params?: Record<string, any>
  user_agent?: string
  error_message?: string
}

// 系统日志查询参数
export interface SysLogListParams {
  page?: number
  per_page?: number
  user_id?: number
  controller_name?: string
  action_name?: string
  request_method?: string
  status_code?: number
  start_date?: string
  end_date?: string
  errors_only?: boolean
  slow_requests?: boolean
  slow_threshold?: number
}

// 系统日志响应
export interface SysLogListResponse {
  logs: SysLog[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

// 健康检查响应
export interface HealthCheckResponse {
  status: string
  details: Record<string, any>
}
