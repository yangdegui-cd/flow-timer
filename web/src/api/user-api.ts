import { BaseApi } from './base-api'
import type {
  User,
  Role,
  UserFormData,
  UserStatus,
  SystemStats,
  AuditLog
} from '@/data/types/user-types'

// 用户API请求响应类型
export interface UserListParams {
  page?: number
  per_page?: number
  status?: UserStatus
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

export interface CreateUserRequest extends UserFormData {
  password?: string
}

export interface UpdateUserRequest {
  name?: string
  email?: string
  status?: UserStatus
  phone?: string
  department?: string
  position?: string
}

export interface AssignRolesRequest {
  role_ids: number[]
}

export interface ChangePasswordRequest {
  current_password: string
  new_password: string
  confirm_password: string
}

// 用户API类
export class UserApi extends BaseApi {
  constructor() {
    super('sys_user')
  }

  // 修改用户状态
  async changeStatus(id: number, status: UserStatus): Promise<User> {
    return this.put<User>(`${id}/change_status`, { status })
  }

  // 分配角色
  async assignRoles(id: number, data: AssignRolesRequest): Promise<User> {
    return this.put<User>(`${id}/assign_roles`, data)
  }

  // 移除角色
  async removeRole(id: number, roleId: number): Promise<User> {
    return this.delete<User>(`${id}/remove_role`, { role_id: roleId })
  }

  // 获取所有角色
  async getRoles(): Promise<Role[]> {
    return this.get<Role[]>('roles')
  }

  // 获取权限列表
  async getPermissions(): Promise<{ permissions: string[]; descriptions: Record<string, string> }> {
    return this.get('permissions')
  }

  // 修改密码
  async changePassword(id: number, data: ChangePasswordRequest): Promise<void> {
    return this.put<void>(`${id}/change_password`, data)
  }

  // 重置密码
  async resetPassword(id: number): Promise<{ temp_password: string }> {
    return this.post<{ temp_password: string }>(`${id}/reset_password`)
  }

  // 获取用户统计数据
  async getStats(): Promise<SystemStats> {
    return this.get<SystemStats>('stats')
  }

  // 获取审计日志
  async getAuditLogs(params?: { page?: number; per_page?: number }): Promise<AuditLog[]> {
    return this.get<AuditLog[]>('audit_logs', params)
  }

  // 批量操作
  async batchUpdate(userIds: number[], data: Partial<UpdateUserRequest>): Promise<void> {
    return this.post<void>('batch_update', { user_ids: userIds, ...data })
  }

  async batchDelete(userIds: number[]): Promise<void> {
    return this.post<void>('batch_delete', { user_ids: userIds })
  }

  async batchChangeStatus(userIds: number[], status: UserStatus): Promise<void> {
    return this.post<void>('batch_change_status', { user_ids: userIds, status })
  }
}

// 导出单例实例
const userApi = new UserApi()
export default userApi
