/**
 * 元数据管理相关默认数据配置
 */

import type { MetaHost, MetaDatasource, MetaHdfs } from '@/data/types/meta-types'
import { DATABASE_DEFAULT_PORTS } from '@/data/constants/meta-constants'

// 主机配置默认数据
export const createMetaHostDefaults = (): Partial<MetaHost> => ({
  name: '',
  description: '',
  hostname: '',
  port: 22,
  username: '',
  auth_type: 'password',
  password: '',
  ssh_key: '',
  ssh_port: 22,
  connection_timeout: 30,
  max_connections: 10,
  status: 'inactive',
  environment: 'development',
  tags: '',
  notes: ''
})

// 数据源配置默认数据  
export const createMetaDatasourceDefaults = (databaseType: string = 'mysql'): Partial<MetaDatasource> => ({
  name: '',
  description: '',
  database_type: databaseType as any,
  host: '',
  port: DATABASE_DEFAULT_PORTS[databaseType as keyof typeof DATABASE_DEFAULT_PORTS] || 3306,
  database_name: '',
  username: '',
  password: '',
  connection_params: {},
  pool_size: 10,
  timeout: 30,
  ssl_enabled: false,
  ssl_config: {},
  status: 'inactive',
  environment: 'development',
  tags: '',
  notes: ''
})

// HDFS 配置默认数据
export const createMetaHdfsDefaults = (): Partial<MetaHdfs> => ({
  name: '',
  description: '',
  namenode_host: '',
  namenode_port: 9000,
  webhdfs_port: 50070,
  username: '',
  authentication_type: 'simple',
  kerberos_principal: '',
  kerberos_keytab: '',
  default_fs: '',
  ha_enabled: false,
  nameservices: '',
  namenodes: [],
  status: 'inactive',
  environment: 'development',
  tags: '',
  notes: ''
})