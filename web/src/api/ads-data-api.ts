import { BaseApi } from './base-api'

export interface AdsDataItem {
  id: number
  date: string
  campaign_name: string
  impressions: number
  clicks: number
  spend: number
  ctr: number
  cpm: number
  cpc: number
  conversions: number
  reach: number
  ads_account_name: string
  platform_name: string
  calculated_ctr: number
  calculated_cpm: number
  calculated_cpc: number
}

export interface AdsDataResponse {
  data: AdsDataItem[]
  pagination: {
    current_page: number
    per_page: number
    total_count: number
    total_pages: number
  }
}

export interface AdsAccount {
  id: number
  name: string
  account_id: string
  platform: string
  project: string
  data_count: number
}

export interface AdsStatsResponse {
  total_stats: {
    impressions: number
    clicks: number
    spend: number
    reach: number
    conversions: number
    conversion_value: number
  }
  average_stats: {
    avg_ctr: number
    avg_cpm: number
    avg_cpc: number
    avg_conversion_rate: number
    avg_cost_per_conversion: number
    avg_roas: number
  }
  daily_stats: Array<{
    date: string
    impressions: number
    clicks: number
    spend: number
    conversions: number
  }>
  campaign_stats: Array<{
    campaign_name: string
    impressions: number
    clicks: number
    spend: number
    conversions: number
    ctr: number
    cpm: number
  }>
  summary: {
    total_records: number
    date_range: {
      start_date: string
      end_date: string
    }
    unique_campaigns: number
    total_accounts: number
  }
}

export interface Campaign {
  id: string
  name: string
}

class AdsDataApi extends BaseApi {
  constructor() {
    super('api/ads_data')
  }

  // 获取广告数据列表
  async getAdsData(params?: {
    ads_account_id?: number
    start_date?: string
    end_date?: string
    campaign_name?: string
    page?: number
    per_page?: number
    order_by?: string
    order_direction?: string
  }): Promise<AdsDataResponse> {
    return this.get<AdsDataResponse>('', params)
  }

  // 获取统计数据
  async getStats(params?: {
    ads_account_id?: number
    start_date?: string
    end_date?: string
  }): Promise<AdsStatsResponse> {
    return this.get<AdsStatsResponse>('stats', params)
  }

  // 获取广告账户列表
  async getAccounts(): Promise<AdsAccount[]> {
    return this.get<AdsAccount[]>('accounts')
  }

  // 获取活动列表
  async getCampaigns(params?: {
    ads_account_id?: number
  }): Promise<Campaign[]> {
    return this.get<Campaign[]>('campaigns', params)
  }
}

export const adsDataApi = new AdsDataApi()
export default adsDataApi