import { BaseApi } from './base-api'
import type {
  Project,
  ProjectFormData,
  ProjectListParams,
  ProjectAssignment,
  UserProjectAssignment,
  ProjectUserListParams,
  UserProjectListParams
} from '@/data/types/project-types'
import type { User } from '@/data/types/user-types'

// 项目API请求响应类型
export interface ProjectListResponse {
  projects: Project[]
  pagination?: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

export interface CreateProjectRequest extends ProjectFormData {}

export interface UpdateProjectRequest {
  name?: string
  start_date?: string
  active_ads_automate?: boolean
  description?: string
  status?: 'active' | 'inactive' | 'archived'
}

// 项目API类
class ProjectApi extends BaseApi {
  constructor() {
    super('projects')
  }

  // 分配用户到项目
  async assignUsers(id: number, data: ProjectAssignment): Promise<Project> {
    return this.post<Project>(`${id}/assign_users`, data)
  }

  // 获取用户的项目列表
  async getUserProjects(userId: number, params?: UserProjectListParams): Promise<Project[]> {
    return this.get<Project[]>(`/sys_user_projects/user_projects/${userId}`, params)
  }

  // 获取项目的用户列表
  async getProjectUsers(id: number, params?: ProjectUserListParams): Promise<User[]> {
    return this.get<User[]>(`/sys_user_projects/project_users/${id}`, params)
  }

  // 批量分配用户到项目
  async bulkAssign(id: number, userAssignments: UserProjectAssignment[]): Promise<void> {
    return this.post<void>('/sys_user_projects/bulk_assign', {
      project_id: id,
      user_assignments: userAssignments
    })
  }

  // 获取项目统计数据
  async getStats(): Promise<any> {
    return this.get<any>('stats')
  }
}

// 导出单例实例
const projectApi = new ProjectApi()
export default projectApi

// 也可以导出类，以便其他地方使用
export { ProjectApi }

// 项目状态选项
export const projectStatusOptions = [
  { label: '活跃', value: 'active' },
  { label: '非活跃', value: 'inactive' },
  { label: '已归档', value: 'archived' }
]

// 项目角色选项
export const projectRoleOptions = [
  { label: '所有者', value: 'owner' },
  { label: '成员', value: 'member' },
  { label: '查看者', value: 'viewer' }
]

// 项目状态标签样式
export const getProjectStatusSeverity = (status: string) => {
  switch (status) {
    case 'active':
      return 'success'
    case 'inactive':
      return 'warning'
    case 'archived':
      return 'danger'
    default:
      return 'info'
  }
}

// 项目角色标签样式
export const getProjectRoleSeverity = (role: string) => {
  switch (role) {
    case 'owner':
      return 'danger'
    case 'member':
      return 'success'
    case 'viewer':
      return 'info'
    default:
      return 'secondary'
  }
}
