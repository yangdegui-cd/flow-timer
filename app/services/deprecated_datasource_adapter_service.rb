# DEPRECATED: 此服务已弃用，请使用 app/models/db_client/ 下的新架构
# 
# 原有的 DatasourceAdapterService 已被重构为基于 db_client 的模块化架构：
# - DatasourceClient (抽象基类)
# - SequelDbClient (Sequel 数据库客户端)
# - TrinoDbClient (Trino 专用客户端)
# 
# 新架构提供了更好的：
# - 代码组织和可维护性
# - 类型安全和错误处理
# - 扩展性和定制化
# - 连接池管理
# 
# 迁移指南：
# 1. 使用 MetaDatasource#get_db_client 获取客户端实例
# 2. 通过客户端调用相应方法：
#    - client.test_connection()
#    - client.get_databases(catalog)
#    - client.get_schemas(database_name, catalog)
#    - client.execute(sql, options)
#    - client.query(sql, options)
# 3. 记得在使用完毕后调用 client.close()
#
# 此文件将在未来版本中移除

class DeprecatedDatasourceAdapterService
  def initialize(*args)
    Rails.logger.warn "DEPRECATED: DatasourceAdapterService 已弃用，请使用 db_client 架构"
    raise "DatasourceAdapterService 已弃用，请使用 app/models/db_client/ 下的新架构"
  end

  def self.method_missing(method_name, *args, &block)
    Rails.logger.warn "DEPRECATED: DatasourceAdapterService.#{method_name} 已弃用，请使用 db_client 架构"
    raise "DatasourceAdapterService 已弃用，请使用 app/models/db_client/ 下的新架构"
  end
end

# 为了兼容性，提供别名
DatasourceAdapterService = DeprecatedDatasourceAdapterService