/**
 * 执行SQL节点配置
 */

import type { SqlExecuteNodeConfig } from '@/data/types/database-types'
import { SQL_EXECUTE_NODE_DEFAULT } from '@/data/constants/database-constants'

export interface ExecuteSqlNodeSetting {
  // 连接配置
  connection_type: 'metadata' | 'custom'
  metadata_id?: number
  custom_connection?: {
    name: string
    type: string
    host: string
    port: number
    username: string
    password: string
    description?: string
  }

  // 数据库选择
  catalog?: string
  database?: string
  schema?: string

  // SQL配置
  sql: string
  timeout: number
  max_rows: number

  // 结果处理
  output_format: 'json' | 'csv' | 'none'
  save_result: boolean
  result_table?: string
}

// 节点配置验证
export const validateExecuteSqlNode = (config: Partial<ExecuteSqlNodeSetting>): string[] => {
  const errors: string[] = []

  // 验证连接配置
  if (!config.connection_type) {
    errors.push('请选择连接方式')
  }

  if (config.connection_type === 'metadata') {
    if (!config.metadata_id) {
      errors.push('请选择数据库连接')
    }
  } else if (config.connection_type === 'custom') {
    if (!config.custom_connection) {
      errors.push('请配置自定义连接信息')
    } else {
      const conn = config.custom_connection
      if (!conn.host?.trim()) errors.push('请输入主机地址')
      if (!conn.port || conn.port <= 0) errors.push('请输入有效端口号')
      if (!conn.username?.trim()) errors.push('请输入用户名')
      if (!conn.password?.trim()) errors.push('请输入密码')
    }
  }

  // 验证SQL
  if (!config.sql?.trim()) {
    errors.push('请输入SQL语句')
  }

  // 验证超时时间
  if (!config.timeout || config.timeout <= 0) {
    errors.push('请设置有效的超时时间')
  }

  // 验证最大行数
  if (!config.max_rows || config.max_rows <= 0) {
    errors.push('请设置有效的最大返回行数')
  }

  // 验证结果保存配置
  if (config.save_result && !config.result_table?.trim()) {
    errors.push('启用结果保存时请指定结果表名')
  }

  return errors
}

// 节点执行前预检
export const preCheckExecuteSqlNode = (config: ExecuteSqlNodeSetting): Promise<{
  success: boolean
  message: string
  warnings?: string[]
}> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const warnings: string[] = []

      // 检查SQL语句类型
      const sqlUpper = config.sql.trim().toUpperCase()

      if (sqlUpper.startsWith('DELETE') || sqlUpper.startsWith('DROP') || sqlUpper.startsWith('TRUNCATE')) {
        warnings.push('检测到危险SQL操作，请确认无误后执行')
      }

      if (sqlUpper.includes('*') && !sqlUpper.includes('LIMIT')) {
        warnings.push('使用SELECT *且未设置LIMIT可能返回大量数据')
      }

      if (config.max_rows > 5000) {
        warnings.push('返回行数设置较大，可能影响性能')
      }

      if (config.timeout > 600) {
        warnings.push('超时时间设置较长，可能影响流程执行')
      }

      resolve({
        success: true,
        message: '节点配置检查通过',
        warnings: warnings.length > 0 ? warnings : undefined
      })
    }, 500)
  })
}


// 节点图标和颜色配置
export const executeSqlNodeMeta = {
  type: 'execute_sql',
  label: '执行SQL',
  icon: 'pi pi-play',
  color: '#8b5cf6',
  category: 'database',
  description: '执行SQL语句并返回结果',
  inputs: ['任意'],
  outputs: ['数据表', '执行结果'],
  configurable: true,
  version: '1.0.0'
}

// 导出节点配置（兼容nodes-setting.ts格式）
const execute_sql = {
  view: {
    icon: "pi pi-database",
    name: "执行SQL",
    node_type: "common",
    node_subtype: "execute_sql",
    hide_source: false,
    hide_target: false,
  },
  config: {

  }

}

export default execute_sql
