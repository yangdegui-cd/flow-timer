class FtTask < ApplicationRecord
  self.create_fields = [:name, :description, :flow_id, :catalog_id, :task_type, :period_type, :cron_expression, :effective_time, :lose_efficacy_time, :params, :queue, :priority, :dependents]
  self.update_fields = [:name, :description, :task_type, :period_type, :cron_expression, :effective_time, :lose_efficacy_time, :params, :queue, :priority, :status, :dependents]
  self.show_fields = [:id, :task_id, :name, :description, :flow_id, :catalog_id, :status, :task_type, :period_type, :cron_expression, :effective_time, :lose_efficacy_time, :params, :queue, :priority, :dependents, :created_at, :updated_at]
  self.search_fields = [:name, :description]

  # 序列化设置

  before_create :set_task_id
  has_one :catalog
  belongs_to :ft_flow, foreign_key: :flow_id, primary_key: :flow_id
  has_many :ft_task_executions, class_name: 'FtTaskExecution', foreign_key: :task_id, primary_key: :task_id, dependent: :destroy

  validates :name, presence: true
  validates :flow_id, presence: true

  enum task_type: {
    disposable: 'disposable',
    periodic: 'periodic',
    dependent: 'dependent'
  }

  enum status: {
    active: 'active',
    paused: 'paused',
    discard: 'discard',
    overdue: 'overdue',
  }

  enum period_type: {
    hourly: 'hourly',
    daily: 'daily',
    weekly: 'weekly',
    monthly: 'monthly',
    cron: 'cron'
  }

  def set_task_id
    self.task_id ||= SecureRandom.uuid
    self.catalog_id ||= Catalog.default_catalog_id("TASK")
    self.status ||= 'paused'
    self.queue ||= 'default'
    self.priority ||= 0
    self.dependents ||= []
  end

  def system_params(data_time)
    date = data_time[0..9].to_date
    hour = nil
    hour = data_time[11..12].to_i if hourly?
    {
      today: date.to_s,
      yesterday: (date - 1.day).to_s,
      tomorrow: (date + 1.day).to_s,
      hour: hour,
      month: date.strftime('%Y-%m'),
      year: date.year.to_s,
      beginning_of_month: date.beginning_of_month.to_s,
      end_of_month: date.end_of_month.to_s,
    }
  end

  def activate!
    self.active!
    enqueue
  end

  def deactivate!
    self.paused!
    Resque.remove_schedule(self.task_id)
  end

  def discard!
    self.discard!
    Resque.remove_schedule(self.task_id)
  end

  def enqueue(data_time = nil)
    return unless self.active?
    params = resque_job_params(data_time)
    if self.disposable?
      Resque.enqueue_at(self.effective_time, FtTaskExecutionJob, params)
    elsif self.periodic?
      config = {
        class: :FtTaskExecutionJob,
        queue: self.queue,
        args: params,
        cron: self.cron_expression,
        brocking: false,
        persist: true,
        first_at: self.effective_time,
      }
      config[:last_at] = self.lose_efficacy_time if self.lose_efficacy_time
      Resque.set_schedule(self.task_id, config)
    end
  end

  def enqueue_with_dependencies(date_time, execution_type)
    return unless self.dependent?
    Resque.enqueue(FtTaskExecutionJob, resque_job_params(date_time, execution_type))
  end


  def execute_now(date_time = nil)
    Resque.enqueue(FtTaskExecutionJob, resque_job_params(date_time, 'manumotive'))
  end

  # Get last execution
  def last_execution
    ft_task_executions.order(created_at: :desc).first
  end

  # Get execution history
  def execution_history(limit = 10)
    ft_task_executions.order(created_at: :desc).limit(limit)
  end

  # Check if task is currently being executed
  def currently_executing?
    ft_task_executions.where(status: 'running').exists?
  end

  # Get execution statistics
  def execution_stats
    executions = ft_task_executions
    total = executions.count

    return { total: 0 } if total == 0

    by_status = executions.group(:status).count
    avg_duration = executions.where.not(duration_seconds: nil).average(:duration_seconds)&.to_f&.round(2)
    success_rate = total > 0 ? ((by_status['completed'] || 0).to_f / total * 100).round(2) : 0

    {
      total: total,
      by_status: by_status,
      average_duration_seconds: avg_duration,
      success_rate_percent: success_rate,
      last_execution: last_execution&.html_json
    }
  end

  def resque_job_params(data_time, execution_type = 'system', run_dependencies = true)
    {
      task_id: self.task_id,
      date_time: data_time,
      execution_type: execution_type,
      run_dependencies: run_dependencies
    }
  end

  # Enhanced html_json to include execution info
  def html_json
    base_json = as_json(only: self.class.show_fields)
    base_json.merge({
                      ft_flow: ft_flow&.as_json(only: [:id, :flow_id, :name, :description]),
                      last_execution: last_execution&.html_json,
                      execution_stats: execution_stats,
                      currently_executing: currently_executing?
                    })
  end

  def next_dependents
    FtTask.dependent.select{|t| t.dependents.include?(self.task_id)}
  end

  def can_run_with_dependencies?(data_time)
    return false unless dependent?
    return false if dependents.blank?

    # 检查所有依赖任务是否都已成功完成
    dependents.all? do |task_id|
      dependent_task = FtTask.find_by(task_id: task_id)
      next false unless dependent_task
      # 检查依赖任务在指定时间是否有成功的执行记录
      dependent_task.ft_task_executions
                   .where(data_time: data_time, status: 'completed')
                   .exists?
    end
  end

end
