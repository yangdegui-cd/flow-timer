/**
 * 角色管理相关类型定义
 */

import type { Role } from './user-types'

// 创建角色请求
export interface CreateRoleRequest {
  name: string
  description?: string
  permissions: string[]
}

// 更新角色请求
export interface UpdateRoleRequest {
  name?: string
  description?: string
  permissions?: string[]
}

// 更新权限请求
export interface UpdatePermissionsRequest {
  permissions: string[]
}

// 分组权限
export interface GroupedPermissions {
  [key: string]: {
    label: string
    permissions: string[]
  }
}

// 可用权限响应
export interface AvailablePermissionsResponse {
  permissions: string[]
  descriptions: Record<string, string>
  grouped_permissions: GroupedPermissions
}

// 角色详情响应
export interface RoleDetailResponse {
  role: Role & {
    users: Array<{
      id: number
      name: string
      email: string
      avatar_url?: string
    }>
    total_users: number
  }
}

// 角色列表响应
export interface RoleListResponse {
  roles: Role[]
}

// 角色操作响应
export interface RoleOperationResponse {
  role: Role
  message: string
}