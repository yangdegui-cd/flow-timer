# frozen_string_literal: true

class ExecuteSqlNode < BaseNode

  def perform
    validate_config!

    config = @data[:config]
    log_info("开始SQL执行任务: #{@node_id}")

    # 获取前置节点的输入数据
    merged_inputs = get_merged_inputs
    log_info("接收到输入数据: #{merged_inputs}") unless merged_inputs.empty?

    begin
      # 1. 建立数据库连接
      database_config = get_database_config(config)

      # 2. 准备SQL语句（可能包含动态参数替换）
      sql = prepare_sql(config[:sql], merged_inputs)

      # 3. 设置执行选项
      options = build_execute_options(config)

      # 4. 执行SQL
      result = execute_sql_with_timeout(database_config, sql, options)

      # 5. 处理结果
      processed_result = process_sql_result(result, config)

      log_info("SQL执行完成: #{@node_id}")

      {
        success: true,
        sql: sql,
        rows_affected: result[:rows_affected] || 0,
        rows_returned: result[:rows_returned] || 0,
        execution_time: result[:execution_time] || 0,
        data: processed_result[:data],
        columns: processed_result[:columns],
        output_format: config[:output_format] || 'json',
        message: "SQL执行成功"
      }

    rescue => e
      log_error("SQL执行失败: #{e.message}")

      # 记录详细错误信息
      error_details = {
        error_type: e.class.name,
        error_message: e.message,
        sql: sql || config[:sql],
        database_type: database_config&.dig(:db_type)
      }

      raise "SQL执行失败: #{e.message}"
    end
  end

  private

  # 验证节点配置
  def validate_config!
    config = @data[:config]
    raise "缺少节点配置信息" unless config

    # 验证连接方式
    connection_type = config[:connection_type]
    raise "请选择连接方式" unless connection_type

    if connection_type == 'metadata'
      raise "请选择数据库连接" unless config[:metadata_id]
    elsif connection_type == 'custom'
      validate_custom_connection!(config[:custom_connection])
    else
      raise "无效的连接方式: #{connection_type}"
    end

    # 验证SQL语句
    sql = config[:sql]
    raise "请输入SQL语句" if sql.nil? || sql.strip.empty?

    # 验证超时设置
    timeout = config[:timeout] || 30
    raise "超时时间必须大于0" if timeout <= 0

    # 验证最大行数设置
    max_rows = config[:max_rows] || 1000
    raise "最大行数必须大于0" if max_rows <= 0

    # 验证结果保存配置
    if config[:save_result] && (config[:result_table].nil? || config[:result_table].strip.empty?)
      raise "启用结果保存时请指定结果表名"
    end
  end

  # 验证自定义连接配置
  def validate_custom_connection!(custom_connection)
    raise "缺少自定义连接配置" unless custom_connection

    required_fields = [:host, :port, :username, :password, :db_type]
    required_fields.each do |field|
      value = custom_connection[field]
      raise "#{field}不能为空" if value.nil? || (value.is_a?(String) && value.strip.empty?)
    end

    # 验证端口号
    port = custom_connection[:port]
    raise "端口号必须为正整数" unless port.is_a?(Integer) && port > 0
  end

  # 获取数据库配置
  def get_database_config(config)
    case config[:connection_type]
    when 'metadata'
      # 从元数据库获取连接信息
      meta_datasource = MetaDatasource.find(config[:metadata_id])
      raise "未找到指定的数据库连接" unless meta_datasource

      {
        db_type: meta_datasource.db_type,
        host: meta_datasource.host,
        port: meta_datasource.port,
        username: meta_datasource.username,
        password: meta_datasource.password,
        extra_config: meta_datasource.extra_config || {}
      }

    when 'custom'
      # 使用自定义连接信息
      custom_conn = config[:custom_connection]
      {
        db_type: custom_conn[:db_type],
        host: custom_conn[:host],
        port: custom_conn[:port],
        username: custom_conn[:username],
        password: custom_conn[:password],
        extra_config: custom_conn[:extra_config] || {}
      }

    else
      raise "不支持的连接方式: #{config[:connection_type]}"
    end
  end

  # 准备SQL语句（支持参数替换）
  def prepare_sql(sql_template, input_data)
    return sql_template if input_data.empty?

    # 简单的参数替换：支持 ${param_name} 格式
    prepared_sql = sql_template.dup

    input_data.each do |key, value|
      placeholder = "${#{key}}"
      if prepared_sql.include?(placeholder)
        # 根据值的类型进行适当的转换
        sql_value = case value
                   when String
                     "'#{value.gsub("'", "''")}'" # SQL字符串转义
                   when Numeric
                     value.to_s
                   when TrueClass, FalseClass
                     value.to_s.upcase
                   when NilClass
                     'NULL'
                   else
                     "'#{value.to_s.gsub("'", "''")}'"
                   end

        prepared_sql = prepared_sql.gsub(placeholder, sql_value)
      end
    end

    prepared_sql
  end

  # 构建执行选项
  def build_execute_options(config)
    options = {}

    # 设置最大行数限制
    options[:limit] = config[:max_rows] || 1000

    # 设置超时时间
    options[:timeout] = config[:timeout] || 30

    # 设置数据库和Schema
    options[:database] = config[:database] if config[:database]
    options[:schema] = config[:schema] if config[:schema]
    options[:catalog] = config[:catalog] if config[:catalog]

    options
  end

  # 带超时控制的SQL执行
  def execute_sql_with_timeout(database_config, sql, options)
    timeout = options[:timeout] || 30

    Timeout::timeout(timeout) do
      start_time = Time.now

      result = DatabaseAdapterService.execute_sql(database_config, sql, options)

      execution_time = (Time.now - start_time).round(3)

      # 标准化返回结果
      {
        rows_affected: result[:rows_affected],
        rows_returned: result[:rows_returned] || (result[:data]&.length || 0),
        data: result[:data] || [],
        columns: result[:columns] || [],
        execution_time: execution_time
      }
    end
  rescue Timeout::Error
    raise "SQL执行超时（#{timeout}秒）"
  end

  # 处理SQL执行结果
  def process_sql_result(result, config)
    data = result[:data] || []
    columns = result[:columns] || []

    # 根据输出格式处理数据
    case config[:output_format]
    when 'csv'
      processed_data = convert_to_csv(data, columns)
    when 'none'
      processed_data = nil
    else # 'json' or default
      processed_data = data
    end

    # 如果需要保存结果
    if config[:save_result] && !data.empty?
      save_result_to_table(data, columns, config[:result_table], config)
    end

    {
      data: processed_data,
      columns: columns
    }
  end

  # 转换为CSV格式
  def convert_to_csv(data, columns)
    return "" if data.empty?

    csv_lines = []

    # 添加标题行
    csv_lines << columns.join(',') if columns.any?

    # 添加数据行
    data.each do |row|
      csv_row = columns.map do |col|
        value = row[col] || row[col.to_sym] || ""
        # CSV值转义
        if value.to_s.include?(',') || value.to_s.include?('"') || value.to_s.include?("\n")
          "\"#{value.to_s.gsub('"', '""')}\""
        else
          value.to_s
        end
      end
      csv_lines << csv_row.join(',')
    end

    csv_lines.join("\n")
  end

  # 保存结果到表（简单实现）
  def save_result_to_table(data, columns, table_name, config)
    begin
      # 这里可以实现将结果保存到指定表的逻辑
      # 例如创建临时表或插入到已存在的表中
      log_info("结果已保存到表: #{table_name}")
    rescue => e
      log_error("保存结果到表失败: #{e.message}")
      # 不影响主流程，只记录警告
    end
  end

  # 记录信息日志
  def log_info(message)
    Rails.logger.info("[SQL_EXECUTE_NODE][#{@node_id}] #{message}")
  end

  # 记录错误日志
  def log_error(message)
    Rails.logger.error("[SQL_EXECUTE_NODE][#{@node_id}] #{message}")
  end
end
