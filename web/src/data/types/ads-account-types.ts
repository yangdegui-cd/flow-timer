export interface AdsAccount {
  id: number
  name: string
  account_id: string
  ads_platform_id: number
  project_id: number
  sys_user_id: number
  account_status: 'active' | 'suspended' | 'closed'
  currency: string | null
  timezone: string | null
  account_balance: number | null
  daily_budget: number | null
  active: boolean
  last_sync_at: string | null
  sync_frequency: number
  sync_status: 'success' | 'error' | 'pending'
  last_error: string | null
  token_expires_at: string | null
  config: Record<string, any> | null
  created_at: string
  updated_at: string

  // 关联数据
  ads_platform: AdsPlatform
  project: {
    id: number
    name: string
  }
  sys_user: {
    id: number
    username: string
    email: string
  }

  // 计算字段
  display_name: string
  masked_access_token: string | null
  last_sync_status: string
  token_expired: boolean
  needs_token_refresh: boolean
  sync_overdue: boolean
}

export interface AdsPlatform {
  id: number
  name: string
  slug: string
  api_version: string | null
  base_url: string | null
  oauth_url: string | null
  scopes: string[]
  auth_method: string
  description: string | null
  active: boolean
  created_at: string
  updated_at: string
}

export interface AdsAccountCreateRequest {
  name: string
  account_id: string
  ads_platform_id: number
  project_id: number
  access_token?: string
  refresh_token?: string
  app_id?: string
  app_secret?: string
  currency?: string
  timezone?: string
  sync_frequency?: number
  config?: Record<string, any>
}

export interface AdsAccountUpdateRequest {
  name?: string
  sync_frequency?: number
  active?: boolean
  config?: Record<string, any>
}

export interface AdsAccountListResponse {
  data: AdsAccount[]
  meta: {
    total: number
    page: number
    per_page: number
    total_pages: number
  }
}

export interface AuthorizeResponse {
  data: {
    auth_url: string
  }
}

export interface AccountsByPlatformResponse {
  data: Record<string, AdsAccount[]>
}