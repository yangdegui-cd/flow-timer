# frozen_string_literal: true

# 数据库客户端抽象基类
class DatasourceClient
  attr_reader :meta_datasource
  
  def initialize(meta_datasource)
    @meta_datasource = meta_datasource
  end

  # 测试连接
  def test_connection
    raise NotImplementedError, "Subclasses must implement the test_connection method"
  end

  # 执行SQL语句（INSERT, UPDATE, DELETE等）
  def execute(sql, options = {})
    raise NotImplementedError, "Subclasses must implement the execute method"
  end

  # 查询数据（SELECT语句）
  def query(sql, options = {})
    raise NotImplementedError, "Subclasses must implement the query method"
  end

  # 关闭连接
  def close
    raise NotImplementedError, "Subclasses must implement the close method"
  end

  # 获取数据库列表
  def get_databases(catalog = nil)
    raise NotImplementedError, "Subclasses must implement the get_databases method"
  end

  # 获取Schema列表
  def get_schemas(database_name, catalog = nil)
    raise NotImplementedError, "Subclasses must implement the get_schemas method"
  end

  # 获取Catalog列表（主要用于Trino）
  def get_catalogs
    raise NotImplementedError, "Subclasses must implement the get_catalogs method"
  end

  # 获取表列表
  def get_tables(database_name, schema_name = nil, catalog = nil)
    raise NotImplementedError, "Subclasses must implement the get_tables method"
  end

  # 获取表结构
  def describe_table(table_name, database_name = nil, schema_name = nil, catalog = nil)
    raise NotImplementedError, "Subclasses must implement the describe_table method"
  end

  # 工厂方法：根据数据源类型创建对应的客户端
  def self.build(meta_datasource)
    case meta_datasource.db_type.to_s.downcase
    when 'mysql', 'mariadb', 'postgresql', 'sqlite', 'oracle', 'sqlserver', 'hive', 'clickhouse'
      SequelDbClient.new(meta_datasource)
    when 'trino'
      TrinoDbClient.new(meta_datasource)
    else
      raise "不支持的数据库类型: #{meta_datasource.db_type}"
    end
  end

  protected

  # 解密密码
  def decrypt_password
    password = @meta_datasource.password
    return password unless password && password.length > 0
    
    begin
      Base64.decode64(password)
    rescue
      # 如果解码失败，假设密码未加密
      password
    end
  end

  # 获取额外配置
  def extra_config
    @meta_datasource.extra_config || {}
  end

  # 记录错误日志
  def log_error(message, exception = nil)
    Rails.logger.error(message)
    if exception
      Rails.logger.error("异常类型: #{exception.class.name}")
      Rails.logger.error("错误信息: #{exception.message}")
      exception.backtrace&.first(10)&.each { |line| Rails.logger.error(line) }
    end
  end
end