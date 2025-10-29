import { BaseApi } from './base-api'

export interface SyncAccountsResponse {
  synced: number
  created: number
  updated: number
}

// Facebook API类
export class FacebookApi extends BaseApi {
  constructor() {
    super('facebook')
  }

  /**
   * 同步 Facebook 广告账户
   */
  async syncAccounts(): Promise<SyncAccountsResponse> {
    return this.post<SyncAccountsResponse>('sync_accounts')
  }
}

// 导出单例实例
const facebookApi = new FacebookApi()
export default facebookApi
