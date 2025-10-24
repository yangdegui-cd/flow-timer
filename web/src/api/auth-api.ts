import { BaseApi } from './base-api'
import type {
  User,
  AuthResponse,
  LoginRequest,
  RegisterRequest,
  ChangePasswordRequest,
  UpdateProfileRequest,
  UserInfoResponse,
  OAuthActionResponse,
  ProfileUpdateResponse
} from '@/data/types/auth-types'

// 认证API类
export class AuthApi extends BaseApi {
  constructor() {
    super('auth')
  }

  // 用户注册
  async register(data: RegisterRequest): Promise<AuthResponse> {
    return this.post<AuthResponse>('register', data)
  }

  // 用户登录
  async login(data: LoginRequest): Promise<AuthResponse> {
    return this.post<AuthResponse>('login', data)
  }

  // 用户退出
  async logout(): Promise<OAuthActionResponse> {
    return BaseApi.apiRequest<OAuthActionResponse>('DELETE', '/auth/logout')
  }

  // 获取当前用户信息
  async me(): Promise<UserInfoResponse> {
    return this.get<UserInfoResponse>('me')
  }

  // 修改密码
  async changePassword(data: ChangePasswordRequest): Promise<OAuthActionResponse> {
    return this.put<OAuthActionResponse>('change_password', data)
  }

  // 更新个人信息
  async updateProfile(data: UpdateProfileRequest): Promise<ProfileUpdateResponse> {
    return this.put<ProfileUpdateResponse>('update_profile', data)
  }

  // 绑定OAuth账号
  async bindOAuth(): Promise<OAuthActionResponse> {
    return this.post<OAuthActionResponse>('bind_oauth')
  }

  // 解绑OAuth账号
  async unbindOAuth(provider: string): Promise<OAuthActionResponse> {
    return BaseApi.apiRequest<OAuthActionResponse>('DELETE', `/auth/unbind_oauth/${provider}`)
  }

  // GitHub OAuth登录
  githubLogin(): void {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    // 设置登录模式
    localStorage.setItem('oauth_mode', 'login')
    window.location.href = `${backendUrl}/auth/github`
  }

  // 微信OAuth登录
  wechatLogin(): void {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    // 设置登录模式
    localStorage.setItem('oauth_mode', 'login')
    window.location.href = `${backendUrl}/auth/wechat`
  }
}

// 导出单例实例
const authApi = new AuthApi()
export default authApi