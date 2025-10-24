/**
 * OAuth 相关类型定义
 */

// OAuth提供商接口
export interface OAuthProvider {
  provider: string
  provider_name: string
  display_info: {
    username?: string
    nickname?: string
    avatar?: string
    profile_url?: string
    openid?: string
  }
  connected_at: string
}

// OAuth用户接口
export interface OAuthUser {
  id: number
  email: string
  name: string
  avatar_url?: string
  oauth_providers: OAuthProvider[]
}

// OAuth绑定请求
export interface OAuthBindRequest {
  provider: string
  auth_code?: string
}

// OAuth回调参数
export interface OAuthCallbackParams {
  code?: string
  state?: string
  error?: string
}

// OAuth模式类型
export type OAuthMode = 'login' | 'bind'

// OAuth响应
export interface OAuthResponse {
  message: string
  provider?: OAuthProvider
}