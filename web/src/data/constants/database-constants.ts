/**
 * 数据库相关常量定义
 */

import type { DatabaseType } from '../types/database-types'

// 数据库类型配置
export const DATABASE_TYPES: Record<DatabaseType, {
  label: string
  icon: string
  color: string
  default_port: number
  description: string
  extra_fields?: string[]  // 需要额外配置的字段
}> = {
  mysql: {
    label: 'MySQL',
    icon: 'pi pi-database',
    color: '#f59e0b',
    default_port: 3306,
    description: 'MySQL关系型数据库',
    extra_fields: ['charset', 'collation']
  },
  oracle: {
    label: 'Oracle',
    icon: 'pi pi-circle',
    color: '#dc2626',
    default_port: 1521,
    description: 'Oracle企业级数据库',
    extra_fields: ['service_name', 'sid']
  },
  hive: {
    label: 'Hive',
    icon: 'pi pi-server',
    color: '#f97316',
    default_port: 10000,
    description: 'Apache Hive数据仓库',
    extra_fields: ['auth_mechanism', 'kerberos_service']
  },
  postgresql: {
    label: 'PostgreSQL',
    icon: 'pi pi-database',
    color: '#3b82f6',
    default_port: 5432,
    description: 'PostgreSQL开源数据库',
    extra_fields: ['sslmode', 'connect_timeout']
  },
  mariadb: {
    label: 'MariaDB',
    icon: 'pi pi-database',
    color: '#059669',
    default_port: 3306,
    description: 'MariaDB开源数据库',
    extra_fields: ['charset', 'collation']
  },
  trino: {
    label: 'Trino',
    icon: 'pi pi-chart-bar',
    color: '#8b5cf6',
    default_port: 8080,
    description: '分布式SQL查询引擎',
    extra_fields: ['catalog', 'schema', 'source']
  },
  clickhouse: {
    label: 'ClickHouse',
    icon: 'pi pi-bolt',
    color: '#eab308',
    default_port: 8123,
    description: '列式数据库管理系统',
    extra_fields: ['database', 'compression']
  },
  sqlserver: {
    label: 'SQL Server',
    icon: 'pi pi-microsoft',
    color: '#0ea5e9',
    default_port: 1433,
    description: 'Microsoft SQL Server',
    extra_fields: ['instance', 'integrated_security']
  }
}

// 数据库状态配置
export const DATABASE_STATUS_CONFIG = {
  active: {
    label: '正常',
    severity: 'success' as const,
    color: '#10b981'
  },
  inactive: {
    label: '未连接',
    severity: 'warning' as const,
    color: '#f59e0b'
  },
  error: {
    label: '错误',
    severity: 'danger' as const,
    color: '#ef4444'
  },
  testing: {
    label: '测试中',
    severity: 'info' as const,
    color: '#3b82f6'
  }
}

// 数据库类型选项（用于下拉选择）
export const DATABASE_TYPE_OPTIONS = Object.entries(DATABASE_TYPES).map(([key, config]) => ({
  label: config.label,
  value: key as DatabaseType,
  icon: config.icon,
  color: config.color,
  description: config.description
}))



// SQL编辑器配置
export const SQL_EDITOR_CONFIG = {
  theme: 'vs-dark',
  language: 'sql',
  options: {
    fontSize: 14,
    lineNumbers: 'on',
    wordWrap: 'on',
    minimap: { enabled: false },
    scrollBeyondLastLine: false,
    automaticLayout: true,
    tabSize: 2,
    insertSpaces: true
  }
}

// 常用SQL模板
export const SQL_TEMPLATES = [
  {
    name: '查询模板',
    sql: 'SELECT * FROM table_name WHERE condition LIMIT 10;'
  },
  {
    name: '插入模板',
    sql: 'INSERT INTO table_name (column1, column2) VALUES (value1, value2);'
  },
  {
    name: '更新模板',
    sql: 'UPDATE table_name SET column1 = value1 WHERE condition;'
  },
  {
    name: '删除模板',
    sql: 'DELETE FROM table_name WHERE condition;'
  },
  {
    name: '创建表模板',
    sql: `CREATE TABLE table_name (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);`
  }
]
