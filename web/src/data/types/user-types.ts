/**
 * 用户管理相关类型定义
 */

// 用户状态类型
export type UserStatus = 'active' | 'inactive' | 'suspended' | 'pending'

// 用户角色类型
export type UserRole = 'admin' | 'developer' | 'operator' | 'viewer'

// OAuth提供商类型
export type OAuthProvider = 'github' | 'wechat' | 'google'

// 用户接口
export interface User {
  id: number
  name: string
  email: string
  status: UserStatus
  created_at: string
  updated_at: string
  last_login_at?: string
  avatar_url?: string
  phone?: string
  department?: string
  position?: string
  roles?: Role[]
  oauth_accounts?: OAuthAccount[]
}

// 角色接口
export interface Role {
  id: number
  name: string
  display_name: string
  description?: string
  permissions: Permission[]
  users_count?: number
  created_at: string
  updated_at: string
}

// 权限接口
export interface Permission {
  id: number
  name: string
  display_name: string
  description?: string
  resource: string
  action: string
  module: string
  created_at: string
  updated_at: string
}

// OAuth账户接口
export interface OAuthAccount {
  id: number
  provider: OAuthProvider
  provider_id: string
  provider_username: string
  provider_avatar?: string
  linked_at: string
  user_id: number
}

// 用户表单数据
export interface UserFormData {
  name: string
  email: string
  password?: string
  status: UserStatus
  phone?: string
  department?: string
  position?: string
  role_ids?: number[]
}

// 角色表单数据
export interface RoleFormData {
  name: string
  display_name: string
  description?: string
  permission_ids?: number[]
}

// 权限表单数据
export interface PermissionFormData {
  name: string
  display_name: string
  description?: string
  resource: string
  action: string
  module: string
}

// 登录表单数据
export interface LoginFormData {
  email: string
  password: string
  remember?: boolean
}

// 注册表单数据
export interface RegisterFormData {
  name: string
  email: string
  password: string
  confirm_password: string
}

// 用户资料表单数据
export interface ProfileFormData {
  name: string
  email: string
  phone?: string
  department?: string
  position?: string
  current_password?: string
  new_password?: string
  confirm_password?: string
}

// 系统统计数据
export interface SystemStats {
  users_count: number
  roles_count: number
  permissions_count: number
  online_users_count: number
  active_users_today: number
  new_users_this_week: number
}

// 审计日志
export interface AuditLog {
  id: number
  user_id?: number
  user_name?: string
  action: string
  resource: string
  resource_id?: string
  ip_address: string
  user_agent: string
  details?: Record<string, any>
  created_at: string
}