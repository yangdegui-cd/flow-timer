/**
 * 数据库连接管理API
 */

import { ApiList, ApiCreate, ApiUpdate, ApiDelete, ApiShow } from './base-api'
import type { 
  Database, 
  DatabaseForm, 
  DatabaseTestResult,
  DatabaseListParams 
} from '@/data/types/database-types'

/**
 * 数据库连接API类
 */
class DatabaseApi {
  private static tableName = 'ft_database_connections'

  /**
   * 获取数据库连接列表
   */
  static async list(params?: DatabaseListParams) {
    const queryParams: Record<string, any> = {}
    
    if (params?.page) queryParams.page = params.page
    if (params?.per_page) queryParams.per_page = params.per_page
    if (params?.type) queryParams.type = params.type
    if (params?.status) queryParams.status = params.status
    if (params?.name) queryParams.name = params.name

    return ApiList(this.tableName, queryParams).then(data => ({
      code: 200,
      data: {
        databases: data.items || data.databases || [],
        pagination: data.pagination || {
          current_page: 1,
          per_page: 10,
          total_count: data.items?.length || 0,
          total_pages: 1
        }
      }
    })).catch(err => {
      throw { message: err.message || '获取数据库连接列表失败' }
    })
  }

  /**
   * 获取单个数据库连接详情
   */
  static async show(id: number) {
    return ApiShow(this.tableName, id).then(data => ({
      code: 200,
      data: {
        database: data
      }
    })).catch(err => {
      throw { message: err.message || '获取数据库连接详情失败' }
    })
  }

  /**
   * 创建数据库连接
   */
  static async create(database: DatabaseForm) {
    const payload = {
      name: database.name,
      type: database.type,
      host: database.host,
      port: database.port,
      username: database.username,
      password: database.password,
      description: database.description,
      extra_config: database.extra_config || {}
    }

    return ApiCreate(this.tableName, payload).then(data => ({
      code: 200,
      data: {
        database: data,
        message: '数据库连接创建成功'
      }
    })).catch(err => {
      throw { message: err.message || '创建数据库连接失败' }
    })
  }

  /**
   * 更新数据库连接
   */
  static async update(id: number, database: Partial<DatabaseForm>) {
    const payload: Record<string, any> = {}
    
    if (database.name !== undefined) payload.name = database.name
    if (database.type !== undefined) payload.type = database.type
    if (database.host !== undefined) payload.host = database.host
    if (database.port !== undefined) payload.port = database.port
    if (database.username !== undefined) payload.username = database.username
    if (database.password !== undefined) payload.password = database.password
    if (database.description !== undefined) payload.description = database.description
    if (database.extra_config !== undefined) payload.extra_config = database.extra_config

    return ApiUpdate(this.tableName, id, payload).then(data => ({
      code: 200,
      data: {
        database: data,
        message: '数据库连接更新成功'
      }
    })).catch(err => {
      throw { message: err.message || '更新数据库连接失败' }
    })
  }

  /**
   * 删除数据库连接
   */
  static async delete(id: number) {
    return ApiDelete(this.tableName, id).then(() => ({
      code: 200,
      data: {
        message: '数据库连接删除成功'
      }
    })).catch(err => {
      throw { message: err.message || '删除数据库连接失败' }
    })
  }

  /**
   * 测试数据库连接
   */
  static async testConnection(database: Database | DatabaseForm): Promise<DatabaseTestResult> {
    const payload = {
      type: database.type,
      host: database.host,
      port: database.port,
      username: database.username,
      password: database.password,
      extra_config: database.extra_config || {}
    }

    // 这里应该调用后端的连接测试接口
    // 暂时使用模拟数据
    return new Promise((resolve) => {
      setTimeout(() => {
        const isSuccess = Math.random() > 0.2 // 80% 成功率
        
        if (isSuccess) {
          resolve({
            success: true,
            message: '连接测试成功',
            databases: ['test_db', 'demo_db', 'analytics'],
            catalogs: database.type === 'trino' ? ['hive', 'mysql', 'postgresql'] : undefined,
            test_time: new Date().toISOString()
          })
        } else {
          resolve({
            success: false,
            message: '连接测试失败',
            error: '无法连接到数据库服务器，请检查连接配置',
            test_time: new Date().toISOString()
          })
        }
      }, 2000) // 模拟网络延迟
    })
  }

  /**
   * 获取可用数据库列表（基于已有连接）
   */
  static async getDatabases(connectionId: number, catalog?: string) {
    // 这里应该调用后端接口获取指定连接的数据库列表
    // 暂时使用模拟数据
    return new Promise<string[]>((resolve) => {
      setTimeout(() => {
        const databases = ['information_schema', 'test_db', 'demo_db', 'analytics', 'warehouse']
        resolve(databases)
      }, 1000)
    })
  }

  /**
   * 获取可用Catalog列表（主要用于Trino）
   */
  static async getCatalogs(connectionId: number) {
    // 这里应该调用后端接口获取Catalog列表
    // 暂时使用模拟数据
    return new Promise<string[]>((resolve) => {
      setTimeout(() => {
        const catalogs = ['hive', 'mysql', 'postgresql', 'system']
        resolve(catalogs)
      }, 1000)
    })
  }

  /**
   * 获取可用Schema列表
   */
  static async getSchemas(connectionId: number, database?: string, catalog?: string) {
    // 这里应该调用后端接口获取Schema列表
    // 暂时使用模拟数据
    return new Promise<string[]>((resolve) => {
      setTimeout(() => {
        const schemas = ['public', 'default', 'dbo', 'analytics']
        resolve(schemas)
      }, 800)
    })
  }

  /**
   * 执行SQL语句
   */
  static async executeSQL(connectionId: number, sql: string, options?: {
    database?: string
    catalog?: string
    schema?: string
    timeout?: number
    max_rows?: number
  }) {
    const payload = {
      connection_id: connectionId,
      sql: sql,
      database: options?.database,
      catalog: options?.catalog,
      schema: options?.schema,
      timeout: options?.timeout || 300,
      max_rows: options?.max_rows || 1000
    }

    // 这里应该调用后端的SQL执行接口
    // 暂时使用模拟数据
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        const isSuccess = Math.random() > 0.1 // 90% 成功率
        
        if (isSuccess) {
          resolve({
            success: true,
            rows_affected: 0,
            rows_returned: 3,
            data: [
              { id: 1, name: 'Alice', age: 25 },
              { id: 2, name: 'Bob', age: 30 },
              { id: 3, name: 'Charlie', age: 35 }
            ],
            columns: ['id', 'name', 'age'],
            execution_time: 1.23
          })
        } else {
          reject({
            message: 'SQL执行失败: 语法错误或权限不足'
          })
        }
      }, 2000) // 模拟SQL执行时间
    })
  }
}

export default DatabaseApi
export type { Database, DatabaseForm, DatabaseTestResult }
