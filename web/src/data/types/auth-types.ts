/**
 * 认证相关类型定义
 */

// 用户接口 (认证相关)
export interface User {
  id: number
  email: string
  name: string
  avatar_url?: string
  status: 'active' | 'inactive' | 'suspended'
  last_login_at?: string
  roles: Array<{
    id: number
    name: string
    display_name: string
  }>
  permissions: string[]
  oauth_providers: Array<{
    provider: string
    provider_name: string
    display_info: any
    connected_at: string
  }>
}

// 认证响应
export interface AuthResponse {
  token: string
  user: User
  message: string
}

// 登录请求
export interface LoginRequest {
  email: string
  password: string
}

// 注册请求
export interface RegisterRequest {
  email: string
  password: string
  name: string
}

// 修改密码请求
export interface ChangePasswordRequest {
  current_password: string
  new_password: string
}

// 更新个人资料请求
export interface UpdateProfileRequest {
  name: string
  avatar_url?: string
}

// 用户信息响应
export interface UserInfoResponse {
  user: User
}

// OAuth绑定/解绑响应
export interface OAuthActionResponse {
  message: string
}

// 个人资料更新响应
export interface ProfileUpdateResponse {
  user: User
  message: string
}