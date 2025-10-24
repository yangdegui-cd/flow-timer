/**
 * 元数据管理相关常量和选项配置
 */

import type { Environment, MetaStatus } from '@/data/types/meta-types'

// 环境选项
export const ENVIRONMENT_OPTIONS = [
  { label: '开发', value: 'development' as Environment },
  { label: '测试', value: 'test' as Environment },
  { label: '生产', value: 'production' as Environment }
] as const

// 状态配置
export const META_STATUS_CONFIG = {
  active: { label: '正常', severity: 'success' as const },
  inactive: { label: '停用', severity: 'secondary' as const },
  error: { label: '异常', severity: 'danger' as const },
  testing: { label: '测试中', severity: 'info' as const }
} as const

// 认证类型选项
export const AUTH_TYPE_OPTIONS = [
  { label: '密码认证', value: 'password' },
  { label: '密钥认证', value: 'ssh_key' }
] as const

// 数据库类型选项
export const DATABASE_TYPE_OPTIONS = [
  { label: 'MySQL', value: 'mysql', icon: 'mysql' },
  { label: 'PostgreSQL', value: 'postgresql', icon: 'postgresql' },
  { label: 'Oracle', value: 'oracle', icon: 'oracle' },
  { label: 'SQL Server', value: 'mssql', icon: 'mssql' },
  { label: 'SQLite', value: 'sqlite', icon: 'sqlite' },
  { label: 'Hive', value: 'hive', icon: 'hive' },
  { label: 'Trino', value: 'trino', icon: 'trino' },
  { label: 'ClickHouse', value: 'clickhouse', icon: 'clickhouse' }
] as const

// HDFS 认证类型选项
export const HDFS_AUTH_TYPE_OPTIONS = [
  { label: '简单认证', value: 'simple' },
  { label: 'Kerberos认证', value: 'kerberos' }
] as const

// 数据库默认端口配置
export const DATABASE_DEFAULT_PORTS = {
  mysql: 3306,
  postgresql: 5432,
  oracle: 1521,
  mssql: 1433,
  sqlite: 0, // SQLite 不需要端口
  hive: 10000,
  trino: 8080,
  clickhouse: 8123
} as const

// 连接池大小选项
export const POOL_SIZE_OPTIONS = [
  { label: '5', value: 5 },
  { label: '10', value: 10 },
  { label: '15', value: 15 },
  { label: '20', value: 20 },
  { label: '30', value: 30 },
  { label: '50', value: 50 }
] as const

// 超时时间选项 (秒)
export const TIMEOUT_OPTIONS = [
  { label: '5秒', value: 5 },
  { label: '10秒', value: 10 },
  { label: '30秒', value: 30 },
  { label: '60秒', value: 60 },
  { label: '120秒', value: 120 },
  { label: '300秒', value: 300 }
] as const