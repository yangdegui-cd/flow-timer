import request from "@/request";

// 基础API响应类型
export interface ApiResponse<T = any> {
  code: number
  data: T
  msg: string
}

// 基础API类
export class BaseApi {
  protected resource: string

  constructor(resource: string) {
    this.resource = resource
  }

  // 通用API请求方法
  protected static apiRequest<T = any>(
    method: string,
    url: string,
    data?: any,
    params?: any,
    headers?: Record<string, string>
  ): Promise<T> {
    return request({
      url,
      method: method.toLowerCase(),
      data,
      params,
      headers
    });
  }

  // CRUD操作方法
  list<T = any>(params?: any): Promise<T[]> {
    return BaseApi.apiRequest<T[]>('GET', `/${this.resource}`, null, params)
  }

  show<T = any>(id: string | number): Promise<T> {
    return BaseApi.apiRequest<T>('GET', `/${this.resource}/${id}`)
  }

  create<T = any>(data: any): Promise<T> {
    return BaseApi.apiRequest<T>('POST', `/${this.resource}`, data)
  }

  update<T = any>(id: string | number, data: any): Promise<T> {
    return BaseApi.apiRequest<T>('PUT', `/${this.resource}/${id}`, data)
  }

  delete<T = any>(id: string | number): Promise<T> {
    return BaseApi.apiRequest<T>('DELETE', `/${this.resource}/${id}`)
  }

  // 自定义操作方法
  post<T = any>(action: string, data?: any, params?: any): Promise<T> {
    const url = action.startsWith('/') ? action : `/${this.resource}/${action}`
    return BaseApi.apiRequest<T>('POST', url, data, params)
  }

  get<T = any>(action: string, params?: any): Promise<T> {
    const url = action.startsWith('/') ? action : `/${this.resource}/${action}`
    return BaseApi.apiRequest<T>('GET', url, null, params)
  }

  put<T = any>(action: string, data?: any, params?: any): Promise<T> {
    const url = action.startsWith('/') ? action : `/${this.resource}/${action}`
    return BaseApi.apiRequest<T>('PUT', url, data, params)
  }

  patch<T = any>(action: string, data?: any, params?: any): Promise<T> {
    const url = action.startsWith('/') ? action : `/${this.resource}/${action}`
    return BaseApi.apiRequest<T>('PATCH', url, data, params)
  }
}


export default BaseApi
