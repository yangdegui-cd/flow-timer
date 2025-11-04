import { BaseApi } from './base-api'
import { AdsDimension } from "@/data/types/ads-types";

// 计算参数接口
export interface CalculateParams {
  metric_ids: number[]
  start_date?: string
  end_date?: string
  project_id?: number
  platform?: string
  ads_account_id?: number
  time_dimension?: string
  dimensions?: string[]
}

// 计算结果接口
export interface CalculateResponse {
  results: any[]
  query_params?: any
  total_rows?: number
}

export interface DimensionResult {
  category: string,
  dimensions: AdsDimension[]
}

// 认证API类
export class MetricsApi extends BaseApi {
  constructor() {
    super('api/ads_metrics')
  }

  async listDimensions() {
    return this.get<DimensionResult[]>('dimensions')
  }
}

// 导出单例实例
const metricsApi = new MetricsApi()
export default metricsApi
