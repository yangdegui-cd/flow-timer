/**
 * OAuth 相关 API
 */

import { ApiRequest } from './base-api'

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

export interface OAuthUser {
  id: number
  email: string
  name: string
  avatar_url?: string
  oauth_providers: OAuthProvider[]
}

/**
 * 获取当前用户的OAuth绑定信息
 */
export const getOAuthProviders = (): Promise<OAuthProvider[]> => {
  return ApiRequest('GET', 'auth/me')
    .then(response => response.sys_user?.oauth_providers || [])
}

/**
 * 绑定OAuth账号
 * @param provider OAuth提供商
 * @param authCode 授权码或临时数据
 */
export const bindOAuthProvider = (provider: string, authCode?: string): Promise<any> => {
  return ApiRequest('POST', 'auth/bind_oauth', {
    provider,
    auth_code: authCode
  })
}

/**
 * 解绑OAuth账号
 * @param provider OAuth提供商
 */
export const unbindOAuthProvider = (provider: string): Promise<any> => {
  return ApiRequest('DELETE', `auth/unbind_oauth/${provider}`)
}

/**
 * 获取GitHub授权URL
 */
export const getGitHubAuthUrl = (): string => {
  const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
  return `${backendUrl}/auth/github`
}

/**
 * 处理OAuth回调
 * @param provider OAuth提供商
 * @param params 回调参数
 */
export const handleOAuthCallback = (provider: string, params: URLSearchParams): Promise<any> => {
  const code = params.get('code')
  const state = params.get('state')
  const error = params.get('error')
  
  if (error) {
    throw new Error(`OAuth认证失败: ${error}`)
  }
  
  if (!code) {
    throw new Error('OAuth认证失败: 未获到授权码')
  }
  
  // 根据OAuth模式决定是登录还是绑定
  const mode = localStorage.getItem('oauth_mode') || 'login'
  localStorage.removeItem('oauth_mode')
  
  if (mode === 'bind') {
    return bindOAuthProvider(provider, code)
  } else {
    // 登录模式：直接跳转到后端回调处理
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    window.location.href = `${backendUrl}/auth/${provider}/callback?code=${code}&state=${state || ''}`
    return Promise.resolve()
  }
}

export default {
  getOAuthProviders,
  bindOAuthProvider,
  unbindOAuthProvider,
  getGitHubAuthUrl,
  handleOAuthCallback
}