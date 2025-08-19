class FtTaskExecution < ApplicationRecord
  # 禁用create和update字段，执行记录只能通过程序创建
  self.create_fields = []
  self.update_fields = []
  self.show_fields = %w[id task_id execution_id status error_message data_quality started_at finished_at duration_seconds execution_type queue data_time system_params custom_params resque_job_id created_at updated_at]
  self.search_fields = %w[execution_id status execution_type]

  has_one :ft_task, class_name: 'FtTask', foreign_key: 'task_id', primary_key: 'task_id'

  # 由于ft_task可能不存在（如已删除），所以设置optional: true

  enum status: {
    pending: 'pending',
    running: 'running',
    completed: 'completed',
    failed: 'failed',
    cancelled: 'cancelled'
  }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_task, ->(task_id) { where(task_id: task_id) }
  scope :by_status, ->(status) { where(status: status) }

  before_create :generate_execution_id

  def running!
    update!(
      status: 'running',
      started_at: Time.current
    )
  end

  def completed!(result = nil)
    duration = started_at ? (Time.current - started_at).to_i : 0
    update!(
      status: 'completed',
      result: result&.to_json,
      finished_at: Time.current,
      duration_seconds: duration
    )
  end

  def failed!(error_message)
    duration = started_at ? (Time.current - started_at).to_i : 0
    update!(
      status: 'failed',
      error_message: error_message,
      finished_at: Time.current,
      duration_seconds: duration
    )
  end

  def cancelled!
    duration = started_at ? (Time.current - started_at).to_i : 0
    update!(
      status: 'cancelled',
      finished_at: Time.current,
      duration_seconds: duration
    )
  end

  def increment_retry!
    increment!(:retry_count)
  end

  def duration_formatted
    return '-' unless duration_seconds

    if duration_seconds < 60
      "#{duration_seconds}秒"
    elsif duration_seconds < 3600
      "#{duration_seconds / 60}分#{duration_seconds % 60}秒"
    else
      hours = duration_seconds / 3600
      minutes = (duration_seconds % 3600) / 60
      seconds = duration_seconds % 60
      "#{hours}时#{minutes}分#{seconds}秒"
    end
  end

  def html_json
    as_json(only: self.class.show_fields).merge({
                                                  ft_task: {
                                                    flow_id: ft_task.flow_id,
                                                    flow_name: ft_task.ft_flow.name,
                                                    task_type: ft_task.task_type,
                                                    task_id: ft_task.task_id,
                                                    task_name: ft_task.name,
                                                  },
                                                  duration_formatted: duration_formatted
                                                })
  end

  private

  def generate_execution_id
    self.execution_id ||= SecureRandom.uuid if execution_id.blank?
  end
end
