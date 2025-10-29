import axios from 'axios'
import router from "@/router";

// @ts-ignore
const baseURL = import.meta.env.VITE_BASE_API || '/dev'

const service = axios.create({
  baseURL, // api 的 base_url
  timeout: 100000, // request timeout
})

// request interceptor
service.interceptors.request.use(
  config => {
    // 添加JWT token
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
      config.headers['ngrok-skip-browser-warning'] = '69420'
    }

    // 如果有自定义headers，合并它们
    if (config.headers && config.headers.custom) {
      Object.assign(config.headers, config.headers.custom)
      delete config.headers.custom
    }

    return config
  },
  error => {
    console.log(error) // for debug
    return Promise.reject(error)
  }
)

// response interceptor
service.interceptors.response.use(
  response => {
    const responseStatus = response.data
    // 如果响应有包装结构且有错误码
    if (responseStatus.code && responseStatus.code !== 200) {
      if (responseStatus.code === 401) {
        // Token过期或无效，清除token并跳转到登录页
        localStorage.removeItem('auth_token')
        router.push({ path: '/auth/login' })
      } else {
        return Promise.reject(responseStatus)
      }
    } else if (responseStatus.code && responseStatus.data) {
      // 有包装结构，返回data
      return Promise.resolve(responseStatus.data)
    } else {
      // 直接返回原始数据（Rails API的情况）
      return Promise.resolve(responseStatus)
    }
  },
  err => {
    console.error('Request error:', err)
    if (err.response) {
      if (err.response.status === 401) {
        localStorage.removeItem('auth_token')
        router.push({ path: '/auth/login' })
      }
      return Promise.reject(err.response)
    }
    return Promise.reject(err.message || err)
  }
)


export default service
