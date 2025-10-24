/**
 * COS 相关常量和选项配置
 */

import type { 
  CosRegion, 
  CosStorageClass, 
  CosAcl, 
  CosConfigType, 
  CosEnvironment, 
  SourceType,
  AuthenticationType 
} from '@/data/types/cos-types'

// COS 地域选项
export const COS_REGION_OPTIONS = [
  { label: '广州', value: 'ap-guangzhou' as CosRegion },
  { label: '上海', value: 'ap-shanghai' as CosRegion },
  { label: '北京', value: 'ap-beijing' as CosRegion },
  { label: '成都', value: 'ap-chengdu' as CosRegion },
  { label: '重庆', value: 'ap-chongqing' as CosRegion },
  { label: '深圳金融', value: 'ap-shenzhen-fsi' as CosRegion },
  { label: '上海金融', value: 'ap-shanghai-fsi' as CosRegion },
  { label: '北京金融', value: 'ap-beijing-fsi' as CosRegion },
  { label: '香港', value: 'ap-hongkong' as CosRegion },
  { label: '新加坡', value: 'ap-singapore' as CosRegion },
  { label: '孟买', value: 'ap-mumbai' as CosRegion },
  { label: '首尔', value: 'ap-seoul' as CosRegion },
  { label: '曼谷', value: 'ap-bangkok' as CosRegion },
  { label: '东京', value: 'ap-tokyo' as CosRegion },
  { label: '硅谷', value: 'na-siliconvalley' as CosRegion },
  { label: '弗吉尼亚', value: 'na-ashburn' as CosRegion },
  { label: '多伦多', value: 'na-toronto' as CosRegion },
  { label: '法兰克福', value: 'eu-frankfurt' as CosRegion },
  { label: '莫斯科', value: 'eu-moscow' as CosRegion }
] as const

// COS 存储类型选项
export const COS_STORAGE_CLASS_OPTIONS = [
  { label: '标准存储', value: 'STANDARD' as CosStorageClass },
  { label: '低频存储', value: 'STANDARD_IA' as CosStorageClass },
  { label: '智能分层存储', value: 'INTELLIGENT_TIERING' as CosStorageClass },
  { label: '归档存储', value: 'ARCHIVE' as CosStorageClass },
  { label: '深度归档存储', value: 'DEEP_ARCHIVE' as CosStorageClass }
] as const

// COS ACL 权限选项
export const COS_ACL_OPTIONS = [
  { label: '私有读写', value: 'private' as CosAcl },
  { label: '公有读私有写', value: 'public-read' as CosAcl },
  { label: '公有读写', value: 'public-read-write' as CosAcl }
] as const

// COS 配置类型选项
export const COS_CONFIG_TYPE_OPTIONS = [
  { label: '手动配置', value: 'manual' as CosConfigType },
  { label: '使用元配置', value: 'metadata' as CosConfigType }
] as const

// 环境选项
export const ENVIRONMENT_OPTIONS = [
  { label: '开发', value: 'development' as CosEnvironment },
  { label: '测试', value: 'test' as CosEnvironment },
  { label: '生产', value: 'production' as CosEnvironment }
] as const

// 源类型选项
export const SOURCE_TYPE_OPTIONS = [
  { label: '自定义', value: 'custom' as SourceType },
  { label: '元数据', value: 'metadata' as SourceType },
  { label: '本机', value: 'localhost' as SourceType }
] as const

// 认证类型选项
export const AUTHENTICATION_TYPE_OPTIONS = [
  { label: '密码', value: 'password' as AuthenticationType },
  { label: '密钥', value: 'pem' as AuthenticationType }
] as const

// COS 状态配置
export const COS_STATUS_CONFIG = {
  active: { label: '正常', severity: 'success' as const },
  inactive: { label: '停用', severity: 'secondary' as const },
  error: { label: '异常', severity: 'danger' as const },
  testing: { label: '测试中', severity: 'info' as const }
} as const

// 存储类型标签映射
export const COS_STORAGE_CLASS_LABELS = {
  'STANDARD': '标准存储',
  'STANDARD_IA': '低频存储', 
  'INTELLIGENT_TIERING': '智能分层存储',
  'ARCHIVE': '归档存储',
  'DEEP_ARCHIVE': '深度归档存储'
} as const

// ACL 标签映射
export const COS_ACL_LABELS = {
  'private': '私有读写',
  'public-read': '公有读私有写',
  'public-read-write': '公有读写'
} as const

// 默认端口配置
export const DEFAULT_PORTS = {
  SSH: 22,
  FTP: 21,
  SFTP: 22,
  MYSQL: 3306,
  POSTGRESQL: 5432,
  ORACLE: 1521,
  MSSQL: 1433,
  CLICKHOUSE: 8123,
  HIVE: 10000,
  TRINO: 8080
} as const