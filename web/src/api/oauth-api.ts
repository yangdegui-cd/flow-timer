/**
 * OAuth 相关 API
 */

import { BaseApi } from './base-api'
import type {
  OAuthProvider,
  OAuthUser,
  OAuthBindRequest,
  OAuthCallbackParams,
  OAuthMode,
  OAuthResponse
} from '@/data/types/oauth-types'

// OAuth API类
export class OAuthApi extends BaseApi {
  constructor() {
    super('auth')
  }

  /**
   * 获取当前用户的OAuth绑定信息
   */
  async getProviders(): Promise<OAuthProvider[]> {
    const response = await this.get<{ sys_user?: { oauth_providers?: OAuthProvider[] } }>('me')
    return response.sys_user?.oauth_providers || []
  }

  /**
   * 绑定OAuth账号
   */
  async bindProvider(data: OAuthBindRequest): Promise<OAuthResponse> {
    return this.post<OAuthResponse>('bind_oauth', data)
  }

  /**
   * 解绑OAuth账号
   */
  async unbindProvider(provider: string): Promise<OAuthResponse> {
    return BaseApi.apiRequest<OAuthResponse>('DELETE', `/auth/unbind_oauth/${provider}`)
  }

  /**
   * 获取GitHub授权URL
   */
  getGitHubAuthUrl(): string {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    return `${backendUrl}/auth/github`
  }

  /**
   * 获取微信授权URL
   */
  getWechatAuthUrl(): string {
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    return `${backendUrl}/auth/wechat`
  }

  /**
   * 处理OAuth回调
   */
  async handleCallback(provider: string, params: URLSearchParams): Promise<void | OAuthResponse> {
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
    const mode = (localStorage.getItem('oauth_mode') || 'login') as OAuthMode
    localStorage.removeItem('oauth_mode')

    if (mode === 'bind') {
      return this.bindProvider({ provider, auth_code: code })
    } else {
      // 登录模式：直接跳转到后端回调处理
      const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
      window.location.href = `${backendUrl}/auth/${provider}/callback?code=${code}&state=${state || ''}`
      return Promise.resolve()
    }
  }

  /**
   * 设置OAuth模式
   */
  setOAuthMode(mode: OAuthMode): void {
    localStorage.setItem('oauth_mode', mode)
  }
}

// 导出单例实例
const oauthApi = new OAuthApi()
export default oauthApi