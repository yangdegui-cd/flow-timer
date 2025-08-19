# frozen_string_literal: true

class ApplicationService
  # 基础服务类，提供日志记录功能
  # 所有服务类都应该继承自此类
  # 提供 log_info 和 log_error 方法来记录日志

  attr_reader :logs

  def initialize
    @logs = []
  end

  def log_info(message)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = "[#{self.class.name}][INFO] #{timestamp} - #{message}"
    @logs << log_entry
    Rails.logger.info(log_entry)
  end

  def log_error(message)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = "[#{self.class.name}][ERROR] #{timestamp} - #{message}"
    @logs << log_entry
    Rails.logger.error(log_entry)
  end

  def log_warn(message)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = "[#{self.class.name}][WARN] #{timestamp} - #{message}"
    @logs << log_entry
    Rails.logger.warn(log_entry)
  end
end
