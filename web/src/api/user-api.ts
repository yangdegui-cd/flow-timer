import { ApiRequest, type ApiResponse } from './base-api'
import type { User } from './auth-api'

export interface UserListParams {
  page?: number
  per_page?: number
  status?: string
  email?: string
  name?: string
}

export interface UserListResponse {
  users: User[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

export interface CreateUserRequest {
  email: string
  password?: string
  name: string
  avatar_url?: string
  status?: 'active' | 'inactive' | 'suspended'
  roles?: string[]
}

export interface UpdateUserRequest {
  email?: string
  name?: string
  avatar_url?: string
  status?: 'active' | 'inactive' | 'suspended'
}

export interface AssignRolesRequest {
  roles: string[]
}

export interface Role {
  id: number
  name: string
  display_name: string
  description?: string
  permissions: string[]
  system_role: boolean
  user_count: number
  permission_count?: number
  created_at: string
}

class UserApi {
  // 获取用户列表
  static list(params?: UserListParams): Promise<ApiResponse<UserListResponse>> {
    return ApiRequest<UserListResponse>('GET', '/users', null, params)
  }

  // 获取用户详情
  static show(id: number): Promise<ApiResponse<{ user: User }>> {
    return ApiRequest<{ user: User }>('GET', `/users/${id}`)
  }

  // 创建用户
  static create(data: CreateUserRequest): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('POST', '/users', data)
  }

  // 更新用户
  static update(id: number, data: UpdateUserRequest): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('PUT', `/users/${id}`, data)
  }

  // 删除用户
  static delete(id: number): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('DELETE', `/users/${id}`)
  }

  // 修改用户状态
  static changeStatus(id: number, status: string): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('PUT', `/users/${id}/change_status`, { status })
  }

  // 分配角色
  static assignRoles(id: number, data: AssignRolesRequest): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('PUT', `/users/${id}/assign_roles`, data)
  }

  // 移除角色
  static removeRole(id: number, roleName: string): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('DELETE', `/users/${id}/remove_role`, { role_name: roleName })
  }

  // 获取所有角色
  static getRoles(): Promise<ApiResponse<{ roles: Role[] }>> {
    return ApiRequest<{ roles: Role[] }>('GET', '/users/roles')
  }

  // 获取所有权限
  static getPermissions(): Promise<ApiResponse<{ permissions: string[]; descriptions: Record<string, string> }>> {
    return ApiRequest<{ permissions: string[]; descriptions: Record<string, string> }>('GET', '/users/permissions')
  }
}

export default UserApi