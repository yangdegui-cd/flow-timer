/**
 * 元数据管理相关类型定义
 */

// 通用状态类型
export type MetaStatus = 'active' | 'inactive' | 'error' | 'testing'

// 环境类型
export type Environment = 'development' | 'test' | 'production'

// 用户信息接口
export interface UserInfo {
  id: number
  name: string
}

// 基础元数据接口
export interface BaseMeta {
  id: number
  name: string
  description?: string
  status: MetaStatus
  environment?: Environment
  tags?: string
  notes?: string
  last_test_at?: string
  test_result?: string
  needs_testing: boolean
  created_at: string
  updated_at: string
  created_by_user?: UserInfo
  updated_by_user?: UserInfo
}

// 主机资源接口
export interface MetaHost extends BaseMeta {
  hostname: string
  port: number
  username: string
  auth_type: 'password' | 'ssh_key'
  password?: string
  ssh_key?: string
  ssh_port?: number
  connection_timeout?: number
  max_connections?: number
}

// 数据源接口
export interface MetaDatasource extends BaseMeta {
  database_type: 'mysql' | 'postgresql' | 'oracle' | 'mssql' | 'sqlite' | 'hive' | 'trino' | 'clickhouse'
  host: string
  port: number
  database_name: string
  username: string
  password: string
  connection_params?: Record<string, any>
  pool_size?: number
  timeout?: number
  ssl_enabled?: boolean
  ssl_config?: Record<string, any>
}

// HDFS 配置接口
export interface MetaHdfs extends BaseMeta {
  namenode_host: string
  namenode_port: number
  webhdfs_port?: number
  username: string
  authentication_type: 'simple' | 'kerberos'
  kerberos_principal?: string
  kerberos_keytab?: string
  default_fs: string
  ha_enabled: boolean
  nameservices?: string
  namenodes?: string[]
}