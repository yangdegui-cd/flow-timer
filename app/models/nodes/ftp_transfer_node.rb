# frozen_string_literal: true

require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require 'zip'

class FtpTransferNode < BaseNode

  def perform
    validate_config!

    source_config = @data[:config][:source_setting]
    target_config = @data[:config][:target_setting]

    log_info("开始FTP传输任务: #{@node_id}")

    # 获取前置节点的输入数据（可能包含文件路径等）
    merged_inputs = get_merged_inputs
    log_info("接收到输入数据: #{merged_inputs}") unless merged_inputs.empty?

    # 1. 获取源文件
    source_files = get_source_files(source_config)

    # 2. 处理文件（合并、压缩等）
    processed_files = process_files(source_files, source_config)

    # 3. 传输到目标
    transfer_results = transfer_to_target(processed_files, target_config)

    # 4. 清理临时文件
    cleanup_temp_files(processed_files)

    log_info("FTP传输任务完成: #{@node_id}")

    {
      success: true,
      source_files_count: source_files.length,
      processed_files: processed_files.map { |f| File.basename(f) },
      transfer_results: transfer_results,
      message: "成功传输 #{processed_files.length} 个文件"
    }
  rescue => e
    log_error("FTP传输任务失败: #{e.message}")
    raise e
  end

  private

  # 验证配置
  def validate_config!
    config = @data[:config]
    raise "缺少配置信息" unless config

    source_setting = config[:source_setting]
    target_setting = config[:target_setting]

    raise "缺少源设置" unless source_setting
    raise "缺少目标设置" unless target_setting

    validate_host_setting(source_setting, "源")
    validate_host_setting(target_setting, "目标")

    if source_setting[:files].nil? || source_setting[:files].empty?
      raise "源文件列表不能为空"
    end

    if target_setting[:folder].nil? || target_setting[:folder].strip.empty?
      raise "目标目录不能为空"
    end
  end

  # 验证主机设置
  def validate_host_setting(setting, type)
    case setting[:source_type]
    when 'custom'
      host_setting = setting[:host_setting]
      raise "#{type}主机配置缺失" unless host_setting
      raise "#{type}主机地址不能为空" if host_setting[:host].nil? || host_setting[:host].strip.empty?
      raise "#{type}用户名不能为空" if host_setting[:username].nil? || host_setting[:username].strip.empty?

      if host_setting[:authentication_type] == 'password'
        raise "#{type}密码不能为空" if host_setting[:password].nil? || host_setting[:password].strip.empty?
      elsif host_setting[:authentication_type] == 'pem'
        raise "#{type}PEM密钥不能为空" if host_setting[:pem].nil? || host_setting[:pem].strip.empty?
      end
    when 'metadata'
      raise "#{type}未选择主机" unless setting[:choose_host]
    when 'localhost'
      # 本机不需要额外验证
    else
      raise "#{type}连接类型无效: #{setting[:source_type]}"
    end
  end

  # 获取源文件
  def get_source_files(source_config)
    case source_config[:source_type]
    when 'localhost'
      get_localhost_files(source_config[:files])
    when 'custom'
      get_remote_files(source_config[:host_setting], source_config[:files])
    when 'metadata'
      host_resource = MetaHost.find(source_config[:choose_host])
      get_remote_files(host_resource_to_config(host_resource), source_config[:files])
    else
      raise "不支持的源类型: #{source_config[:source_type]}"
    end
  end

  # 获取本地文件
  def get_localhost_files(file_patterns)
    files = []
    file_patterns.each do |pattern|
      if pattern.include?('*') || pattern.include?('?')
        # 通配符模式
        matched_files = Dir.glob(pattern)
        files.concat(matched_files)
      else
        # 具体文件路径
        if File.exist?(pattern)
          files << pattern
        else
          log_warn("文件不存在: #{pattern}") if respond_to?(:log_warn)
        end
      end
    end

    raise "没有找到任何源文件" if files.empty?
    files
  end

  # 获取远程文件
  def get_remote_files(host_config, file_patterns)
    temp_dir = create_temp_directory
    downloaded_files = []

    with_remote_connection(host_config) do |connection|
      file_patterns.each do |pattern|
        if pattern.include?('*') || pattern.include?('?')
          # 通配符模式 - 需要列出目录并匹配
          remote_files = list_remote_files(connection, pattern)
          remote_files.each do |remote_file|
            local_file = File.join(temp_dir, File.basename(remote_file))
            download_file(connection, remote_file, local_file)
            downloaded_files << local_file
          end
        else
          # 具体文件路径
          local_file = File.join(temp_dir, File.basename(pattern))
          download_file(connection, pattern, local_file)
          downloaded_files << local_file
        end
      end
    end

    raise "没有下载到任何文件" if downloaded_files.empty?
    downloaded_files
  end

  # 处理文件（合并、压缩等）
  def process_files(source_files, source_config)
    return source_files unless source_config[:multifile_merge] || source_config[:use_zip]

    temp_dir = source_config[:tmp_folder] || create_temp_directory
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)

    processed_files = []

    if source_config[:multifile_merge] && source_files.length > 1
      # 多文件合并
      merged_filename = source_config[:use_original_name] ?
        File.basename(source_files.first) :
        (source_config[:file_name] || 'merged_file')

      merged_file = File.join(temp_dir, merged_filename)

      File.open(merged_file, 'w') do |output|
        source_files.each do |source_file|
          File.open(source_file, 'r') do |input|
            output.write(input.read)
            output.write("\n") # 文件间分隔符
          end
        end
      end

      processed_files << merged_file
    else
      processed_files = source_files
    end

    if source_config[:use_zip]
      # 压缩文件
      zip_filename = "#{File.basename(processed_files.first, '.*')}.zip"
      zip_file = File.join(temp_dir, zip_filename)

      Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
        processed_files.each do |file|
          zipfile.add(File.basename(file), file)
        end
      end

      processed_files = [zip_file]
    end

    processed_files
  end

  # 传输到目标
  def transfer_to_target(files, target_config)
    case target_config[:source_type]
    when 'localhost'
      transfer_to_localhost(files, target_config[:folder])
    when 'custom'
      transfer_to_remote(files, target_config[:host_setting], target_config[:folder])
    when 'metadata'
      host_resource = MetaHost.find(target_config[:choose_host])
      transfer_to_remote(files, host_resource_to_config(host_resource), target_config[:folder])
    else
      raise "不支持的目标类型: #{target_config[:source_type]}"
    end
  end

  # 传输到本地
  def transfer_to_localhost(files, target_folder)
    FileUtils.mkdir_p(target_folder) unless Dir.exist?(target_folder)

    results = []
    files.each do |file|
      target_file = File.join(target_folder, File.basename(file))
      FileUtils.cp(file, target_file)
      results << {
        source: file,
        target: target_file,
        size: File.size(target_file),
        success: true
      }
    end
    results
  end

  # 传输到远程
  def transfer_to_remote(files, host_config, target_folder)
    results = []

    with_remote_connection(host_config) do |connection|
      # 确保目标目录存在
      ensure_remote_directory(connection, target_folder)

      files.each do |file|
        target_file = File.join(target_folder, File.basename(file)).gsub('\\', '/')
        upload_file(connection, file, target_file)
        results << {
          source: file,
          target: target_file,
          size: File.size(file),
          success: true
        }
      end
    end

    results
  end

  # 建立远程连接
  def with_remote_connection(host_config)
    if host_config[:port] == 22 || host_config[:authentication_type] == 'pem'
      # SFTP连接
      with_sftp_connection(host_config) { |sftp| yield sftp }
    else
      # FTP连接
      with_ftp_connection(host_config) { |ftp| yield ftp }
    end
  end

  # SFTP连接
  def with_sftp_connection(host_config)
    options = {
      password: host_config[:password],
      port: host_config[:port] || 22,
      timeout: 30
    }

    if host_config[:authentication_type] == 'pem'
      options.delete(:password)
      options[:key_data] = [host_config[:pem]]
    end

    Net::SFTP.start(host_config[:host], host_config[:username], options) do |sftp|
      yield sftp
    end
  end

  # FTP连接
  def with_ftp_connection(host_config)
    ftp = Net::FTP.new
    ftp.connect(host_config[:host], host_config[:port] || 21)
    ftp.login(host_config[:username], host_config[:password])
    ftp.passive = true

    begin
      yield ftp
    ensure
      ftp.close if ftp && !ftp.closed?
    end
  end

  # 下载文件
  def download_file(connection, remote_path, local_path)
    if connection.is_a?(Net::SFTP::Session)
      connection.download!(remote_path, local_path)
    else
      connection.getbinaryfile(remote_path, local_path)
    end
  end

  # 上传文件
  def upload_file(connection, local_path, remote_path)
    if connection.is_a?(Net::SFTP::Session)
      connection.upload!(local_path, remote_path)
    else
      connection.putbinaryfile(local_path, remote_path)
    end
  end

  # 列出远程文件
  def list_remote_files(connection, pattern)
    # 简化实现：这里需要根据具体需求实现通配符匹配
    dir_path = File.dirname(pattern)
    file_pattern = File.basename(pattern)

    files = []
    if connection.is_a?(Net::SFTP::Session)
      connection.dir.foreach(dir_path) do |entry|
        if File.fnmatch(file_pattern, entry.name)
          files << File.join(dir_path, entry.name).gsub('\\', '/')
        end
      end
    else
      connection.list(dir_path).each do |entry|
        filename = entry.split.last
        if File.fnmatch(file_pattern, filename)
          files << File.join(dir_path, filename).gsub('\\', '/')
        end
      end
    end
    files
  end

  # 确保远程目录存在
  def ensure_remote_directory(connection, dir_path)
    if connection.is_a?(Net::SFTP::Session)
      begin
        connection.stat!(dir_path)
      rescue Net::SFTP::StatusException
        connection.mkdir!(dir_path)
      end
    else
      begin
        connection.chdir(dir_path)
      rescue Net::FTPPermError
        connection.mkdir(dir_path)
      end
    end
  end

  # 将HostResource转换为配置
  def host_resource_to_config(host_resource)
    {
      host: host_resource.hostname,
      port: host_resource.port,
      username: host_resource.username,
      authentication_type: host_resource.auth_type || 'password',
      password: host_resource.password,
      pem: host_resource.ssh_key
    }
  end

  # 创建临时目录
  def create_temp_directory
    temp_dir = File.join(Rails.root, 'tmp', 'ftp_transfer', @node_id.to_s, Time.now.to_i.to_s)
    FileUtils.mkdir_p(temp_dir)
    temp_dir
  end

  # 清理临时文件
  def cleanup_temp_files(files)
    files.each do |file|
      begin
        if File.exist?(file) && file.include?('/tmp/ftp_transfer/')
          File.delete(file)
        end
      rescue => e
        log_warn("清理临时文件失败: #{file} - #{e.message}") if respond_to?(:log_warn)
      end
    end

    # 清理空的临时目录
    temp_base = File.join(Rails.root, 'tmp', 'ftp_transfer', @node_id.to_s)
    if Dir.exist?(temp_base) && Dir.empty?(temp_base)
      Dir.rmdir(temp_base)
    end
  end
end
