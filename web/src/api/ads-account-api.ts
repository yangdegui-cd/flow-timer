import { BaseApi } from './base-api'
import type {
  AdsAccount,
  AdsAccountCreateRequest,
  AdsAccountUpdateRequest,
  AdsAccountListResponse,
  AuthorizeResponse
} from '../data/types/ads-account-types'

export class AdsAccountApi extends BaseApi {
  constructor() {
    super('ads_accounts')
  }

  // 获取广告账户列表
  getAdsAccounts(projectId: number): Promise<AdsAccountListResponse> {
    return BaseApi.apiRequest<AdsAccountListResponse>('GET', `/projects/${projectId}/ads_accounts`)
  }

  // 获取单个广告账户
  getAdsAccount(id: number): Promise<{ data: AdsAccount }> {
    return this.get(`${id}`)
  }

  // 创建广告账户
  createAdsAccount(data: AdsAccountCreateRequest): Promise<{ data: AdsAccount }> {
    return this.post('', data)
  }

  // 更新广告账户
  updateAdsAccount(id: number, data: AdsAccountUpdateRequest): Promise<{ data: AdsAccount }> {
    return this.put(`${id}`, data)
  }

  // 删除广告账户
  deleteAdsAccount(id: number): Promise<void> {
    return this.delete(`${id}`)
  }

  // 启用/禁用广告账户
  toggleAdsAccount(id: number, active: boolean): Promise<{ data: AdsAccount }> {
    return this.patch(`${id}/toggle`, { active })
  }

  // 刷新令牌
  refreshToken(id: number): Promise<{ data: AdsAccount }> {
    return this.post(`${id}/refresh_token`)
  }

  // 同步账户数据
  syncAccount(id: number): Promise<void> {
    return this.post(`${id}/sync`)
  }

  // Facebook授权
  authorizeWithFacebook(projectId: number): Promise<AuthorizeResponse> {
    return this.post('facebook/authorize', { project_id: projectId })
  }

  // 获取按平台分组的账户
  getAccountsByPlatform(projectId: number): Promise<{ data: Record<string, AdsAccount[]> }> {
    return BaseApi.apiRequest<{ data: Record<string, AdsAccount[]> }>('GET', `/projects/${projectId}/ads_accounts/by_platform`)
  }

  // 获取可用于绑定的广告账户
  getAvailableAccounts(projectId: number): Promise<{ data: AdsAccount[] }> {
    return BaseApi.apiRequest<{ data: AdsAccount[] }>('GET', `/projects/${projectId}/ads_accounts/available`)
  }

  // 绑定账户到项目
  bindAccount(projectId: number, accountId: number): Promise<{ data: AdsAccount }> {
    return BaseApi.apiRequest<{ data: AdsAccount }>('POST', `/projects/${projectId}/ads_accounts/${accountId}/bind`)
  }

  // 解绑账户
  unbindAccount(projectId: number, accountId: number): Promise<void> {
    return BaseApi.apiRequest<void>('DELETE', `/projects/${projectId}/ads_accounts/${accountId}/unbind`)
  }
}

export const adsAccountApi = new AdsAccountApi()