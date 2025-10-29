/**
 * 项目管理相关类型定义
 */
import type { User } from './user-types'

// SysUser类型（与User相同，但为了向后兼容保留）
export interface SysUser {
  id: number
  name: string
  email: string
  initials: string
  status?: string
}

// 项目状态类型
export type ProjectStatus = 'active' | 'inactive' | 'archived'

// 项目角色类型
export type ProjectRole = 'owner' | 'member' | 'viewer'

// 项目接口
export interface Project {
  id: number
  name: string
  start_date: string
  active_ads_automate: boolean
  description?: string
  status: ProjectStatus
  time_zone?: number
  adjust_game_token?: string
  sys_users?: User[]
  user_count?: number
  created_at: string
  updated_at: string
}

// 用户项目关联接口
export interface UserProject {
  id: number
  sys_user_id: number
  project_id: number
  role: ProjectRole
  assigned_at: string
  created_at: string
  updated_at: string
  sys_user?: User
  project?: Project
}

// 项目表单数据
export interface ProjectFormData {
  name: string
  start_date: string
  active_ads_automate: boolean
  description?: string
  status: ProjectStatus
  time_zone?: number
  adjust_game_token?: string
}

// 项目列表查询参数
export interface ProjectListParams {
  page?: number
  per_page?: number
  status?: ProjectStatus
  name?: string
  active_ads_automate?: boolean
}

// 项目列表响应
export interface ProjectListResponse {
  projects: Project[]
  pagination?: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

// 用户分配请求
export interface ProjectAssignment {
  user_ids: number[]
  role: ProjectRole
}

// 批量用户分配
export interface UserProjectAssignment {
  user_id: number
  role: ProjectRole
}

// 项目用户列表参数
export interface ProjectUserListParams {
  project_id: number
  role?: ProjectRole
  page?: number
  per_page?: number
}

// 用户项目列表参数
export interface UserProjectListParams {
  user_id: number
  status?: ProjectStatus
  page?: number
  per_page?: number
}

// 项目统计数据
export interface ProjectStats {
  total_projects: number
  active_projects: number
  inactive_projects: number
  archived_projects: number
  projects_with_ads_automate: number
  total_assigned_users: number
  average_users_per_project: number
}