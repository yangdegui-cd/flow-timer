import request from "@/request";

// 类型定义
export interface ApiResponse<T = any> {
  code: number
  data: T
  msg: string
}

// 通用API请求函数
export function ApiRequest<T = any>(
  method: string,
  url: string,
  data?: any,
  params?: any,
  headers?: Record<string, string>
): Promise<ApiResponse<T>> {
  return request({
    url,
    method: method.toLowerCase(),
    data,
    params,
    headers
  });
}

// 兼容旧的API函数
export function ApiShow(resource: string, id: string | number) {
  return request({
    url: `${resource}/${id}`,
    method: 'get',
  });
}

export function ApiCreate(resource: string, data: any) {
  return request({
    url: `${resource}`,
    method: 'post',
    data: data
  });
}

export function ApiUpdate(resource: string, id: string | number, data: any) {
  return request({
    url: `${resource}/${id}`,
    method: 'put',
    data: data
  });
}

export function ApiDelete(resource: string, id: string | number) {
  return request({
    url: `${resource}/${id}`,
    method: 'delete',
  });
}

export function ApiList(resource: string, params: any = {}) {
  return request({
    url: `${resource}`,
    method: 'get',
    params: { query: JSON.stringify(params) }
  });
}
