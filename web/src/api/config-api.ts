import { BaseApi } from './base-api'

export interface Config {
  id?: number
  use_email_notification: boolean
  smtp_server: string
  smtp_port: number
  email_notification_email: string
  email_notification_pwd: string
  email_notification_name: string
  email_notification_display_name: string
  email_notification_use_tls: boolean
  qy_wechat_notification_key: string
  qy_wechat_notification_url: string
  adjust_api_token: string
  adjust_api_server: string
  facebook_app_id: string
  facebook_app_secret: string
  facebook_access_token: string
  facebook_token_expired_at: string
  website_base_url: string
  facebook_auth_callback_url: string
  created_at?: string
  updated_at?: string
}

export interface ConfigResponse {
  config: Config
}

export interface TestConnectionResponse {
  success: boolean
  message: string
}

// 配置API类
export class ConfigApi extends BaseApi {
  constructor() {
    super('config')
  }

  /**
   * 获取系统配置（单例，永远只有一条数据）
   */
  async getConfig(): Promise<Config> {
    return this.get<Config>('')
  }

  /**
   * 更新系统配置
   */
  async updateConfig(config: Partial<Config>): Promise<Config> {
    return this.put<Config>('', config)
  }

  /**
   * 测试邮件连接
   */
  async testEmailConnection(): Promise<TestConnectionResponse> {
    return this.post<TestConnectionResponse>('test_email')
  }

  /**
   * 测试企业微信连接
   */
  async testWechatConnection(): Promise<TestConnectionResponse> {
    return this.post<TestConnectionResponse>('test_wechat')
  }

  /**
   * 测试 Adjust API 连接
   */
  async testAdjustConnection(): Promise<TestConnectionResponse> {
    return this.post<TestConnectionResponse>('test_adjust')
  }

  /**
   * 测试 Facebook 凭证
   */
  async testFacebookConnection(): Promise<TestConnectionResponse> {
    return this.post<TestConnectionResponse>('test_facebook')
  }

  /**
   * 获取 Facebook 授权 URL
   */
  async getFacebookAuthUrl(): Promise<{ success: boolean; auth_url?: string; message?: string }> {
    return this.get<{ success: boolean; auth_url?: string; message?: string }>('facebook_auth_url')
  }
}

// 导出单例实例
const configApi = new ConfigApi()
export default configApi
