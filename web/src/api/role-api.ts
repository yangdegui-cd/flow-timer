import { ApiRequest, type ApiResponse } from './base-api'
import type { Role } from './user-api'

export interface CreateRoleRequest {
  name: string
  description?: string
  permissions: string[]
}

export interface UpdateRoleRequest {
  name?: string
  description?: string
  permissions?: string[]
}

export interface UpdatePermissionsRequest {
  permissions: string[]
}

export interface GroupedPermissions {
  [key: string]: {
    label: string
    permissions: string[]
  }
}

export interface AvailablePermissionsResponse {
  permissions: string[]
  descriptions: Record<string, string>
  grouped_permissions: GroupedPermissions
}

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

class RoleApi {
  // 获取角色列表
  static list(): Promise<ApiResponse<{ roles: Role[] }>> {
    return ApiRequest<{ roles: Role[] }>('GET', '/roles')
  }

  // 获取角色详情
  static show(id: number): Promise<ApiResponse<RoleDetailResponse>> {
    return ApiRequest<RoleDetailResponse>('GET', `/roles/${id}`)
  }

  // 创建角色
  static create(data: CreateRoleRequest): Promise<ApiResponse<{ role: Role; message: string }>> {
    return ApiRequest<{ role: Role; message: string }>('POST', '/roles', data)
  }

  // 更新角色
  static update(id: number, data: UpdateRoleRequest): Promise<ApiResponse<{ role: Role; message: string }>> {
    return ApiRequest<{ role: Role; message: string }>('PUT', `/roles/${id}`, data)
  }

  // 删除角色
  static delete(id: number): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('DELETE', `/roles/${id}`)
  }

  // 更新角色权限
  static updatePermissions(id: number, data: UpdatePermissionsRequest): Promise<ApiResponse<{ role: Role; message: string }>> {
    return ApiRequest<{ role: Role; message: string }>('PUT', `/roles/${id}/update_permissions`, data)
  }

  // 获取所有可用权限
  static getAvailablePermissions(): Promise<ApiResponse<AvailablePermissionsResponse>> {
    return ApiRequest<AvailablePermissionsResponse>('GET', '/roles/available_permissions')
  }
}

export default RoleApi