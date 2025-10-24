import { BaseApi } from './base-api'

// 用户项目角色类型
export type ProjectRole = 'owner' | 'member' | 'viewer'

// 用户项目关联类型
export interface UserProject {
  id: number
  sys_user_id: number
  project_id: number
  role: ProjectRole
  assigned_at: string
  created_at: string
  updated_at: string
  role_name: string
  sys_user: {
    id: number
    name: string
    email: string
    status: string
    initials: string
  }
}

// 分配用户请求
export interface AssignUserRequest {
  sys_user_id: number
  project_id: number
  role: ProjectRole
}

// 批量分配请求
export interface BulkAssignRequest {
  project_id: number
  user_assignments: Array<{
    user_id: number
    role: ProjectRole
  }>
}

// 用户项目 API 类
class UserProjectApi extends BaseApi {
  constructor() {
    super('sys_user_projects')
  }

  // 获取项目的所有用户
  async getProjectUsers(projectId: number): Promise<UserProject[]> {
    return BaseApi.apiRequest<UserProject[]>('GET', `/sys_user_projects/project_users/${projectId}`)
  }

  // 分配用户到项目
  async assignUser(data: AssignUserRequest): Promise<UserProject> {
    return BaseApi.apiRequest<UserProject>('POST', '/sys_user_projects', { sys_user_project: data })
  }

  // 更新用户角色
  async updateUserRole(id: number, role: ProjectRole): Promise<UserProject> {
    return BaseApi.apiRequest<UserProject>('PUT', `/sys_user_projects/${id}`, { sys_user_project: { role } })
  }

  // 移除用户
  async removeUser(id: number): Promise<void> {
    return BaseApi.apiRequest<void>('DELETE', `/sys_user_projects/${id}`)
  }

  // 批量分配用户
  async bulkAssign(data: BulkAssignRequest): Promise<{ message: string }> {
    return BaseApi.apiRequest<{ message: string }>('POST', '/sys_user_projects/bulk_assign', data)
  }
}

// 导出单例实例
const userProjectApi = new UserProjectApi()
export default userProjectApi
export { UserProjectApi }
