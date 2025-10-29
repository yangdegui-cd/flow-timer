import { BaseApi } from './base-api'


// 认证API类
export class MetricsApi extends BaseApi {
  constructor() {
    super('api/metrics')
  }
}

// 导出单例实例
const metricsApi = new MetricsApi()
export default metricsApi
