/**
 * 数据库相关类型定义
 */

// 支持的数据库类型
export type DatabaseType = 'mysql' | 'oracle' | 'hive' | 'postgresql' | 'mariadb' | 'trino' | 'clickhouse' | 'sqlserver'

// 数据库连接状态
export type DatabaseStatus = 'active' | 'inactive' | 'error' | 'testing'

// 数据库连接信息
export interface Database {
  id?: number
  name: string                    // 连接名称
  db_type: DatabaseType          // 数据库类型
  host: string                   // 主机地址
  port: number                   // 端口号
  username: string               // 用户名
  password: string               // 密码
  description?: string           // 描述信息
  status?: DatabaseStatus        // 连接状态
  extra_config?: Record<string, any>  // 额外配置参数
  last_test_at?: string          // 最后测试时间
  test_result?: string           // 测试结果信息
  created_by?: number,            // 创建者ID
  updated_by?: number,            // 更新者ID
  created_at?: string
  updated_at?: string
  catalog_id?: number             // 所属Catalog ID
  catalog?: {                     // 所属Catalog信息
    id: number
    name: string
    description?: string
  }
}

// 数据库连接表单数据
export interface DatabaseForm {
  name: string
  db_type: DatabaseType
  host: string
  port: number
  username: string
  password: string
  description: string
  extra_config: Record<string, any>
  catalog_id?: number
}

// 数据库连接测试结果
export interface DatabaseTestResult {
  success: boolean
  message: string
  error?: string
  databases?: string[]           // 可用数据库列表
  catalogs?: string[]            // 可用Catalog列表（Trino）
  test_time: string
}

// 数据库查询参数
export interface DatabaseListParams {
  page?: number
  per_page?: number
  db_type?: DatabaseType
  status?: DatabaseStatus
  name?: string
}

// SQL执行节点配置
export interface SqlExecuteNodeConfig {
  // 连接方式: 'metadata' | 'custom'
  connection_type: 'metadata' | 'custom'

  // 使用元数据连接时
  metadata_id?: number

  // 自定义连接时
  custom_connection?: Omit<Database, 'id' | 'created_at' | 'updated_at'>

  // 数据库选择
  database?: string              // 数据库名
  catalog?: string               // Catalog名（Trino等）
  schema?: string                // Schema名

  // SQL配置
  sql: string                    // 执行的SQL语句
  timeout?: number               // 超时时间（秒）
  max_rows?: number              // 最大返回行数

  // 结果处理
  output_format?: 'json' | 'csv' | 'table'
  save_result?: boolean          // 是否保存结果
  result_table?: string          // 结果保存表名
}

// SQL执行结果
export interface SqlExecuteResult {
  success: boolean
  rows_affected?: number
  rows_returned?: number
  data?: any[]
  columns?: string[]
  execution_time: number
  error?: string
  warnings?: string[]
}
