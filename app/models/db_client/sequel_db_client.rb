# frozen_string_literal: true

require 'sequel'

# Sequel 数据库客户端
class SequelDbClient < DatasourceClient
  attr_reader :connection

  def initialize(meta_datasource)
    super(meta_datasource)
    @connection = nil
  end

  # 获取连接
  def get_connection(database_name = nil)
    return @connection if @connection && connection_valid?
    
    @connection = Sequel.connect(build_connection_url(database_name), test: true)
  end

  # 测试连接
  def test_connection
    begin
      connection = get_connection
      
      # 根据数据库类型执行测试查询
      result = case @meta_datasource.db_type
               when 'mysql', 'mariadb'
                 test_mysql_connection(connection)
               when 'postgresql'
                 test_postgresql_connection(connection)
               when 'sqlite'
                 test_sqlite_connection(connection)
               when 'oracle'
                 test_oracle_connection(connection)
               when 'sqlserver'
                 test_sqlserver_connection(connection)
               when 'hive'
                 test_hive_connection(connection)
               when 'clickhouse'
                 test_clickhouse_connection(connection)
               else
                 { success: false, message: "不支持的数据库类型: #{@meta_datasource.db_type}" }
               end
      
      close
      result
      
    rescue => e
      log_error("数据库连接测试失败", e)
      {
        success: false,
        message: "连接失败: #{e.message}",
        error: e.class.name,
        test_time: Time.current.iso8601
      }
    end
  end

  # 执行SQL语句（非查询）
  def execute(sql, options = {})
    connection = get_connection(options[:database])
    start_time = Time.current
    
    affected_rows = connection.run(sql)
    
    {
      success: true,
      rows_affected: affected_rows,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  rescue => e
    log_error("SQL执行失败", e)
    {
      success: false,
      message: "SQL执行失败: #{e.message}",
      error: e.class.name,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  end

  # 查询数据
  def query(sql, options = {})
    connection = get_connection(options[:database])
    start_time = Time.current
    
    dataset = connection.fetch(sql)
    max_rows = options[:max_rows] || 1000
    rows = dataset.limit(max_rows).all
    
    columns = rows.empty? ? [] : rows.first.keys.map(&:to_s)
    
    {
      success: true,
      data: rows,
      columns: columns,
      rows_returned: rows.size,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  rescue => e
    log_error("SQL查询失败", e)
    {
      success: false,
      message: "SQL查询失败: #{e.message}",
      error: e.class.name,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  end

  # 关闭连接
  def close
    @connection&.disconnect if @connection && connection_valid?
    @connection = nil
  end

  # 获取数据库列表
  def get_databases(catalog = nil)
    connection = get_connection
    
    case @meta_datasource.db_type
    when 'mysql', 'mariadb'
      connection.fetch("SHOW DATABASES").map { |row| row[:Database] }
    when 'postgresql'
      connection.fetch("SELECT datname FROM pg_database WHERE datistemplate = false").map { |row| row[:datname] }
    when 'sqlite'
      ['main'] # SQLite 只有一个数据库
    when 'oracle'
      # Oracle 通常使用schema概念，可以查询用户拥有的schema
      connection.fetch("SELECT DISTINCT OWNER FROM ALL_TABLES ORDER BY OWNER").map { |row| row[:OWNER] }
    when 'sqlserver'
      connection.fetch("SELECT name FROM sys.databases WHERE database_id > 4").map { |row| row[:name] }
    else
      []
    end
  rescue => e
    log_error("获取数据库列表失败", e)
    []
  end

  # 获取Schema列表
  def get_schemas(database_name, catalog = nil)
    connection = get_connection(database_name)
    
    case @meta_datasource.db_type
    when 'postgresql'
      connection.fetch("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')").map { |row| row[:schema_name] }
    when 'mysql', 'mariadb'
      [] # MySQL 没有 schema 概念
    when 'oracle'
      connection.fetch("SELECT DISTINCT OWNER FROM ALL_TABLES WHERE OWNER = '#{database_name.upcase}' ORDER BY OWNER").map { |row| row[:OWNER] }
    when 'sqlserver'
      connection.fetch("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA").map { |row| row[:SCHEMA_NAME] }
    else
      []
    end
  rescue => e
    log_error("获取Schema列表失败", e)
    []
  end

  # 获取Catalog列表（不适用于Sequel支持的数据库）
  def get_catalogs
    []
  end

  # 获取表列表
  def get_tables(database_name, schema_name = nil, catalog = nil)
    connection = get_connection(database_name)
    
    case @meta_datasource.db_type
    when 'mysql', 'mariadb'
      sql = schema_name ? "SHOW TABLES FROM `#{schema_name}`" : "SHOW TABLES"
      connection.fetch(sql).map { |row| row.values.first }
    when 'postgresql'
      sql = if schema_name
              "SELECT tablename FROM pg_tables WHERE schemaname = '#{schema_name}'"
            else
              "SELECT tablename FROM pg_tables WHERE schemaname NOT IN ('information_schema', 'pg_catalog')"
            end
      connection.fetch(sql).map { |row| row[:tablename] }
    when 'sqlite'
      connection.fetch("SELECT name FROM sqlite_master WHERE type='table'").map { |row| row[:name] }
    when 'oracle'
      owner_clause = schema_name ? "OWNER = '#{schema_name.upcase}'" : "OWNER = USER"
      connection.fetch("SELECT TABLE_NAME FROM ALL_TABLES WHERE #{owner_clause}").map { |row| row[:TABLE_NAME] }
    when 'sqlserver'
      schema_clause = schema_name ? "TABLE_SCHEMA = '#{schema_name}'" : "TABLE_SCHEMA != 'INFORMATION_SCHEMA'"
      connection.fetch("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE #{schema_clause}").map { |row| row[:TABLE_NAME] }
    else
      []
    end
  rescue => e
    log_error("获取表列表失败", e)
    []
  end

  # 获取表结构
  def describe_table(table_name, database_name = nil, schema_name = nil, catalog = nil)
    connection = get_connection(database_name)
    
    case @meta_datasource.db_type
    when 'mysql', 'mariadb'
      full_table_name = schema_name ? "`#{schema_name}`.`#{table_name}`" : "`#{table_name}`"
      connection.fetch("DESCRIBE #{full_table_name}").all
    when 'postgresql'
      schema_clause = schema_name ? "table_schema = '#{schema_name}'" : "table_schema NOT IN ('information_schema', 'pg_catalog')"
      connection.fetch("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = '#{table_name}' AND #{schema_clause}").all
    when 'sqlite'
      connection.fetch("PRAGMA table_info(#{table_name})").all
    when 'oracle'
      owner_clause = schema_name ? "OWNER = '#{schema_name.upcase}'" : "OWNER = USER"
      connection.fetch("SELECT COLUMN_NAME, DATA_TYPE, NULLABLE, DATA_DEFAULT FROM ALL_TAB_COLUMNS WHERE TABLE_NAME = '#{table_name.upcase}' AND #{owner_clause}").all
    when 'sqlserver'
      schema_clause = schema_name ? "TABLE_SCHEMA = '#{schema_name}'" : "TABLE_SCHEMA != 'INFORMATION_SCHEMA'"
      connection.fetch("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '#{table_name}' AND #{schema_clause}").all
    else
      []
    end
  rescue => e
    log_error("获取表结构失败", e)
    []
  end

  private

  # 检查连接是否有效
  def connection_valid?
    return false unless @connection
    
    begin
      # 通过执行简单查询来检查连接是否有效
      @connection.fetch("SELECT 1").first
      true
    rescue
      false
    end
  end

  # 构建连接URL
  def build_connection_url(database_name = nil)
    host = @meta_datasource.host
    port = @meta_datasource.port
    username = @meta_datasource.username
    password = decrypt_password
    
    case @meta_datasource.db_type
    when 'mysql', 'mariadb'
      db_name = database_name || 'mysql'
      "mysql2://#{username}:#{password}@#{host}:#{port}/#{db_name}"
    when 'postgresql'
      db_name = database_name || 'postgres'
      "postgres://#{username}:#{password}@#{host}:#{port}/#{db_name}"
    when 'sqlite'
      database_path = extra_config['database_path'] || 'test.db'
      "sqlite://#{database_path}"
    when 'oracle'
      service_name = extra_config['service_name'] || 'ORCL'
      "oracle://#{username}:#{password}@#{host}:#{port}/#{service_name}"
    when 'sqlserver'
      db_name = database_name || 'master'
      "tinytds://#{username}:#{password}@#{host}:#{port}/#{db_name}"
    when 'hive'
      db_name = database_name || 'default'
      "hive://#{username}:#{password}@#{host}:#{port}/#{db_name}"
    when 'clickhouse'
      db_name = database_name || 'default'
      "clickhouse://#{username}:#{password}@#{host}:#{port}/#{db_name}"
    else
      raise "不支持的数据库类型: #{@meta_datasource.db_type}"
    end
  end

  # MySQL/MariaDB 连接测试
  def test_mysql_connection(connection)
    connection.fetch("SELECT 1 AS test").first
    databases = connection.fetch("SHOW DATABASES").map { |row| row[:Database] }
    
    {
      success: true,
      message: "MySQL/MariaDB 连接成功",
      databases: databases,
      test_time: Time.current.iso8601
    }
  end

  # PostgreSQL 连接测试
  def test_postgresql_connection(connection)
    connection.fetch("SELECT 1 AS test").first
    databases = connection.fetch("SELECT datname FROM pg_database WHERE datistemplate = false").map { |row| row[:datname] }
    
    {
      success: true,
      message: "PostgreSQL 连接成功",
      databases: databases,
      test_time: Time.current.iso8601
    }
  end

  # SQLite 连接测试
  def test_sqlite_connection(connection)
    connection.fetch("SELECT 1 AS test").first
    
    {
      success: true,
      message: "SQLite 连接成功",
      databases: ['main'],
      test_time: Time.current.iso8601
    }
  end

  # Oracle 连接测试
  def test_oracle_connection(connection)
    connection.fetch("SELECT 1 FROM dual").first
    
    {
      success: true,
      message: "Oracle 连接成功",
      test_time: Time.current.iso8601
    }
  end

  # SQL Server 连接测试
  def test_sqlserver_connection(connection)
    connection.fetch("SELECT 1 AS test").first
    databases = connection.fetch("SELECT name FROM sys.databases WHERE database_id > 4").map { |row| row[:name] }
    
    {
      success: true,
      message: "SQL Server 连接成功",
      databases: databases,
      test_time: Time.current.iso8601
    }
  end

  # Hive 连接测试
  def test_hive_connection(connection)
    # Hive 基本连接测试
    connection.fetch("SELECT 1").first
    
    {
      success: true,
      message: "Hive 连接成功",
      test_time: Time.current.iso8601
    }
  end

  # ClickHouse 连接测试
  def test_clickhouse_connection(connection)
    connection.fetch("SELECT 1").first
    
    {
      success: true,
      message: "ClickHouse 连接成功",
      test_time: Time.current.iso8601
    }
  end
end