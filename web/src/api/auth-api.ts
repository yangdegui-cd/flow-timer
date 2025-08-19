import { ApiRequest, type ApiResponse } from './base-api'

export interface User {
  id: number
  email: string
  name: string
  avatar_url?: string
  status: 'active' | 'inactive' | 'suspended'
  last_login_at?: string
  roles: Array<{
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

export interface AuthResponse {
  token: string
  user: User
  message: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  password: string
  name: string
}

export interface ChangePasswordRequest {
  current_password: string
  new_password: string
}

export interface UpdateProfileRequest {
  name: string
  avatar_url?: string
}

class AuthApi {
  // 用户注册
  static register(data: RegisterRequest): Promise<ApiResponse<AuthResponse>> {
    return ApiRequest<AuthResponse>('POST', '/auth/register', data)
  }

  // 用户登录
  static login(data: LoginRequest): Promise<ApiResponse<AuthResponse>> {
    return ApiRequest<AuthResponse>('POST', '/auth/login', data)
  }

  // 用户退出
  static logout(): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('DELETE', '/auth/logout')
  }

  // 获取当前用户信息
  static me(): Promise<ApiResponse<{ user: User }>> {
    return ApiRequest<{ user: User }>('GET', '/auth/me')
  }

  // 修改密码
  static changePassword(data: ChangePasswordRequest): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('PUT', '/auth/change_password', data)
  }

  // 更新个人信息
  static updateProfile(data: UpdateProfileRequest): Promise<ApiResponse<{ user: User; message: string }>> {
    return ApiRequest<{ user: User; message: string }>('PUT', '/auth/update_profile', data)
  }

  // 绑定OAuth账号
  static bindOAuth(): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('POST', '/auth/bind_oauth')
  }

  // 解绑OAuth账号
  static unbindOAuth(provider: string): Promise<ApiResponse<{ message: string }>> {
    return ApiRequest<{ message: string }>('DELETE', `/auth/unbind_oauth/${provider}`)
  }

  // GitHub OAuth登录
  static githubLogin(): void {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    // 设置登录模式
    localStorage.setItem('oauth_mode', 'login')
    window.location.href = `${backendUrl}/auth/github`
  }

  // 微信OAuth登录
  static wechatLogin(): void {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    // 设置登录模式
    localStorage.setItem('oauth_mode', 'login')
    window.location.href = `${backendUrl}/auth/wechat`
  }
}

export default AuthApi