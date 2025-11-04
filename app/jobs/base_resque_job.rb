class BaseResqueJob
  # Resque configuration
  @queue = :default


  def perform(*args)
    raise NotImplementedError, 'Subclasses must implement perform method'
  end

  protected

  def log_info(message)
    Rails.logger.info("[#{self.class.name}] #{message}")
  end

  def log_error(message, error = nil)
    Rails.logger.error("[#{self.class.name}] #{message}")
    Rails.logger.error(error.full_message) if error
  end

  def update_execution_status(execution_id, status, **options)
    execution = FtTaskExecution.find_by(execution_id: execution_id)
    return unless execution

    case status
    when 'running'
      execution.running!
    when 'completed'
      execution.mark_as_completed!(options[:result])
    when 'failed'
      execution.mark_as_failed!(options[:error_message])
    when 'cancelled'
      execution.mark_as_cancelled!
    end
  rescue => e
    Rails.logger.error("Failed to update execution status: #{e.message}")
  end
end
