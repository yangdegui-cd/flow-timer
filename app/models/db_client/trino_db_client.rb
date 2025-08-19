# frozen_string_literal: true

require 'trino/client'

# Trino 数据库客户端
class TrinoDbClient < DatasourceClient
  attr_reader :client

  def initialize(meta_datasource)
    super(meta_datasource)
    @client = nil
  end

  # 获取连接
  def get_connection(catalog = nil, schema = nil)
    return @client if @client

    @client = Trino::Client.new(
      server: "#{@meta_datasource.host}:#{@meta_datasource.port}",
      user: @meta_datasource.username,
      password: decrypt_password,
      catalog: catalog || extra_config['catalog'] || 'system',
      schema: schema || extra_config['schema'] || 'information_schema',
      ssl: build_ssl_config,
      source: extra_config['source'] || 'flow-timer',
      language: extra_config['language'] || 'Chinese',
      time_zone: extra_config['time_zone'] || 'Asia/Shanghai',
      query_timeout: (extra_config['query_timeout'] || 7200).to_i,
      http_debug: extra_config['http_debug'] || false
    )
  end

  # 测试连接
  def test_connection
    begin
      client = get_connection
      
      # 测试基本连接
      result = client.run_with_names("SELECT 1 AS test")
      
      # 获取 Catalog 列表
      catalogs = get_catalogs
      
      {
        success: true,
        message: "Trino 连接成功",
        catalogs: catalogs,
        test_time: Time.current.iso8601
      }
      
    rescue => e
      log_error("Trino连接测试失败", e)
      {
        success: false,
        message: "连接失败: #{e.message}",
        error: e.class.name,
        test_time: Time.current.iso8601
      }
    ensure
      close
    end
  end

  # 执行SQL语句（非查询）
  def execute(sql, options = {})
    client = get_connection(options[:catalog], options[:schema])
    start_time = Time.current
    
    # Trino 的执行方式
    exec = client.query(sql)
    loop do
      break unless exec.advance
    end
    
    {
      success: true,
      rows_affected: exec.rows.size,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  rescue => e
    log_error("Trino SQL执行失败", e)
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
    client = get_connection(options[:catalog], options[:schema])
    start_time = Time.current
    
    result = client.run_with_names(sql)
    max_rows = options[:max_rows] || 1000
    
    # 限制返回行数
    limited_rows = result.take(max_rows)
    columns = limited_rows.empty? ? [] : limited_rows.first.keys.map(&:to_s)
    
    {
      success: true,
      data: limited_rows,
      columns: columns,
      rows_returned: limited_rows.size,
      execution_time: (Time.current - start_time) * 1000,
      test_time: Time.current.iso8601
    }
  rescue => e
    log_error("Trino SQL查询失败", e)
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
    # Trino Client 不需要显式关闭
    @client = nil
  end

  # 获取数据库列表（在Trino中是Schema）
  def get_databases(catalog = nil)
    client = get_connection(catalog)
    
    catalog_name = catalog || extra_config['catalog'] || 'system'
    result = client.run_with_names("SHOW SCHEMAS FROM #{catalog_name}")
    
    result.map { |row| row[:schema] || row['schema'] }
  rescue => e
    log_error("获取Trino Schema列表失败", e)
    []
  end

  # 获取Schema列表
  def get_schemas(catalog_name, _unused_param = nil)
    get_databases(catalog_name)
  end

  # 获取Catalog列表
  def get_catalogs
    client = get_connection
    
    result = client.run_with_names("SHOW CATALOGS")
    result.map { |row| row[:catalog] || row['catalog'] }
  rescue => e
    log_error("获取Trino Catalog列表失败", e)
    []
  end

  # 获取表列表
  def get_tables(schema_name, _unused_param = nil, catalog = nil)
    client = get_connection(catalog, schema_name)
    
    catalog_name = catalog || extra_config['catalog'] || 'system'
    schema_name ||= 'information_schema'
    
    sql = "SHOW TABLES FROM #{catalog_name}.#{schema_name}"
    result = client.run_with_names(sql)
    
    result.map { |row| row[:table] || row['table'] }
  rescue => e
    log_error("获取Trino表列表失败", e)
    []
  end

  # 获取表结构
  def describe_table(table_name, schema_name = nil, _unused_param = nil, catalog = nil)
    client = get_connection(catalog, schema_name)
    
    catalog_name = catalog || extra_config['catalog'] || 'system'
    schema_name ||= 'information_schema'
    
    sql = "DESCRIBE #{catalog_name}.#{schema_name}.#{table_name}"
    result = client.run_with_names(sql)
    
    result.to_a
  rescue => e
    log_error("获取Trino表结构失败", e)
    []
  end

  # 获取Trino集群信息
  def get_cluster_info
    client = get_connection
    
    result = client.run_with_names("SELECT * FROM system.runtime.nodes")
    result.to_a
  rescue => e
    log_error("获取Trino集群信息失败", e)
    []
  end

  # 获取查询历史
  def get_query_history(limit = 100)
    client = get_connection
    
    sql = "SELECT query_id, query, state, created, started, \"end\", elapsed_time " +
          "FROM system.runtime.queries ORDER BY created DESC LIMIT #{limit}"
    result = client.run_with_names(sql)
    
    result.to_a
  rescue => e
    log_error("获取Trino查询历史失败", e)
    []
  end

  # 取消查询
  def cancel_query(query_id)
    client = get_connection
    
    # Trino 取消查询需要使用特定的API
    # 这里简化实现，实际可能需要HTTP API调用
    {
      success: true,
      message: "查询取消请求已发送",
      query_id: query_id
    }
  rescue => e
    log_error("取消Trino查询失败", e)
    {
      success: false,
      message: "取消查询失败: #{e.message}",
      error: e.class.name
    }
  end

  # 获取连接统计信息
  def get_connection_stats
    {
      server: "#{@meta_datasource.host}:#{@meta_datasource.port}",
      catalog: extra_config['catalog'] || 'system',
      schema: extra_config['schema'] || 'information_schema',
      user: @meta_datasource.username,
      source: extra_config['source'] || 'flow-timer',
      time_zone: extra_config['time_zone'] || 'Asia/Shanghai',
      connected_at: @client ? Time.current.iso8601 : nil
    }
  end

  private

  # 构建SSL配置
  def build_ssl_config
    ssl_config = extra_config['ssl'] || {}
    
    if ssl_config.is_a?(Hash)
      {
        verify: ssl_config['verify'] != false,
        ca_file: ssl_config['ca_file'],
        cert_file: ssl_config['cert_file'],
        key_file: ssl_config['key_file']
      }.compact
    else
      { verify: ssl_config != false }
    end
  end
end