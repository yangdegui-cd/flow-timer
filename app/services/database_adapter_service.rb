# 兼容层：将旧的 DatabaseAdapterService 调用转换为新的 db_client 架构
class DatabaseAdapterService
  class << self
    # 测试数据库连接
    def test_connection(database_config)
      meta_datasource = build_meta_datasource_from_config(database_config)
      client = DatasourceClient.build(meta_datasource)
      
      begin
        client.test_connection
      ensure
        client.close
      end
    end

    # 获取数据库列表
    def get_databases(database_config, catalog = nil)
      meta_datasource = build_meta_datasource_from_config(database_config)
      client = DatasourceClient.build(meta_datasource)
      
      begin
        client.get_databases(catalog)
      ensure
        client.close
      end
    end

    # 获取Schema列表
    def get_schemas(database_config, database_name, catalog = nil)
      meta_datasource = build_meta_datasource_from_config(database_config)
      client = DatasourceClient.build(meta_datasource)
      
      begin
        client.get_schemas(database_name, catalog)
      ensure
        client.close
      end
    end

    # 获取Catalog列表
    def get_catalogs(database_config)
      meta_datasource = build_meta_datasource_from_config(database_config)
      client = DatasourceClient.build(meta_datasource)
      
      begin
        client.get_catalogs
      ensure
        client.close
      end
    end

    # 执行SQL语句
    def execute_sql(database_config, sql, options = {})
      meta_datasource = build_meta_datasource_from_config(database_config)
      client = DatasourceClient.build(meta_datasource)
      
      begin
        if sql.strip.upcase.start_with?('SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN')
          client.query(sql, options)
        else
          client.execute(sql, options)
        end
      ensure
        client.close
      end
    end

    private

    # 从配置哈希构建临时的 MetaDatasource 对象
    def build_meta_datasource_from_config(config)
      # 创建一个临时的 MetaDatasource 对象，不保存到数据库
      MetaDatasource.new(
        name: 'temp_connection',
        db_type: config[:db_type] || config['db_type'],
        host: config[:host] || config['host'],
        port: config[:port] || config['port'],
        username: config[:username] || config['username'],
        password: config[:password] || config['password'],
        extra_config: config[:extra_config] || config['extra_config'] || {}
      )
    end
  end
end