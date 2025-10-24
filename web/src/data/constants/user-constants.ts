/**
 * 用户管理相关常量定义
 */

import type { UserStatus, UserRole, OAuthProvider } from '../types'

// 用户状态选项
export const USER_STATUS_OPTIONS = [
  { label: '活跃', value: 'active' as UserStatus },
  { label: '非活跃', value: 'inactive' as UserStatus },
  { label: '已暂停', value: 'suspended' as UserStatus },
  { label: '待激活', value: 'pending' as UserStatus }
] as const

// 用户角色选项
export const USER_ROLE_OPTIONS = [
  { label: '管理员', value: 'admin' as UserRole },
  { label: '开发者', value: 'developer' as UserRole },
  { label: '操作员', value: 'operator' as UserRole },
  { label: '查看者', value: 'viewer' as UserRole }
] as const

// OAuth提供商选项
export const OAUTH_PROVIDER_OPTIONS = [
  { label: 'GitHub', value: 'github' as OAuthProvider },
  { label: '微信', value: 'wechat' as OAuthProvider },
  { label: 'Google', value: 'google' as OAuthProvider }
] as const

// 用户状态标签映射
export const USER_STATUS_LABELS = {
  active: '活跃',
  inactive: '非活跃',
  suspended: '已暂停',
  pending: '待激活'
} as const

// 用户状态颜色映射
export const USER_STATUS_COLORS = {
  active: 'success',
  inactive: 'secondary',
  suspended: 'danger',
  pending: 'warning'
} as const

// 用户角色标签映射
export const USER_ROLE_LABELS = {
  admin: '管理员',
  developer: '开发者',
  operator: '操作员',
  viewer: '查看者'
} as const

// 用户角色颜色映射
export const USER_ROLE_COLORS = {
  admin: 'danger',
  developer: 'info',
  operator: 'warning',
  viewer: 'secondary'
} as const

// OAuth提供商标签映射
export const OAUTH_PROVIDER_LABELS = {
  github: 'GitHub',
  wechat: '微信',
  google: 'Google'
} as const

// 权限模块选项
export const PERMISSION_MODULE_OPTIONS = [
  { label: '用户管理', value: 'users' },
  { label: '角色管理', value: 'roles' },
  { label: '权限管理', value: 'permissions' },
  { label: '流程管理', value: 'flows' },
  { label: '任务管理', value: 'tasks' },
  { label: '执行管理', value: 'executions' },
  { label: '监控管理', value: 'monitoring' },
  { label: '系统配置', value: 'system' },
  { label: '元数据管理', value: 'metadata' }
] as const

// 权限动作选项
export const PERMISSION_ACTION_OPTIONS = [
  { label: '查看', value: 'view' },
  { label: '创建', value: 'create' },
  { label: '编辑', value: 'edit' },
  { label: '删除', value: 'delete' },
  { label: '执行', value: 'execute' },
  { label: '管理', value: 'manage' }
] as const

// 部门选项
export const DEPARTMENT_OPTIONS = [
  { label: '技术部', value: '技术部' },
  { label: '产品部', value: '产品部' },
  { label: '运营部', value: '运营部' },
  { label: '市场部', value: '市场部' },
  { label: '人事部', value: '人事部' },
  { label: '财务部', value: '财务部' },
  { label: '行政部', value: '行政部' }
] as const