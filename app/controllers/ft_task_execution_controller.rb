class FtTaskExecutionController < ApplicationController
  include DefaultCrud
  include Result

  private

  def disable_create_update
    render json: {
      success: false,
      message: '执行记录不允许手动创建或修改，请使用执行接口'
    }, status: :forbidden
  end

  public

  # 重写index方法以包含关联数据和排序
  def index
    query = JSON.parse(params[:query] || "{}").deep_symbolize_keys
    @resources = resource_class.includes(:ft_task).where(query).order(created_at: :desc).limit(100)
    data = @resources.map(&:html_json)
    render json: ok(data)
  end

  def show_result
    execution = resource_class.find(params[:id])
    result = execution.result
    if result.present?
      render json: ok(result)
    else
      render json: error('No result found for this execution')
    end
  end

  # 执行任务 POST /ft_task_execution/execute
  def execute
    ft_task_id = params[:ft_task_id]
    job_args = params[:job_args] || {}
    delay_seconds = params[:delay_seconds]&.to_i || 0

    unless ft_task_id.present?
      return render json: error('ft_task_id is required')
    end

    ft_task = FtTask.find_by(id: ft_task_id)
    unless ft_task
      return render json: error("FtTask not found: #{ft_task_id}")
    end

    begin
      # Create execution record
      execution = FtTaskExecution.create!(
        task_id: ft_task.task_id,
        queue: 'task_execution',
        system_params: {},
        custom_params: job_args
      )

      # Schedule the job
      if delay_seconds > 0
        # Delayed execution
        job_id = Resque.enqueue_in(
          delay_seconds.seconds,
          FtTaskExecutionJob,
          ft_task_id,
          execution.execution_id,
          job_args
        )
        execution.update!(resque_job_id: job_id) if job_id
        render json: ok(execution.html_json, "Task scheduled for execution in #{delay_seconds} seconds")
      else
        # Immediate execution
        job_id = Resque.enqueue(
          FtTaskExecutionJob,
          ft_task_id,
          execution.execution_id,
          job_args
        )
        execution.update!(resque_job_id: job_id) if job_id
        render json: ok(execution.html_json, "Task queued for immediate execution")
      end
    rescue => e
      Rails.logger.error("Failed to execute task: #{e.message}")
      render json: error("Failed to execute task: #{e.message}")
    end
  end


  # 批量执行任务 POST /ft_task_execution/batch_execute
  def batch_execute
    task_ids = params[:task_ids]
    job_args = params[:job_args] || {}
    delay_seconds = params[:delay_seconds]&.to_i || 0

    unless task_ids.present? && task_ids.is_a?(Array)
      return render json: error('task_ids array is required')
    end

    results = []
    errors = []

    task_ids.each do |ft_task_id|
      begin
        ft_task = FtTask.find_by(id: ft_task_id)
        unless ft_task
          errors << "FtTask not found: #{ft_task_id}"
          next
        end

        # Create execution record
        ft_task = FtTask.find_by(id: ft_task_id)
        next unless ft_task

        execution = FtTaskExecution.create!(
          task_id: ft_task.task_id,
          queue: 'task_execution',
          system_params: {},
          custom_params: job_args
        )

        # Schedule the job
        if delay_seconds > 0
          job_id = Resque.enqueue_in(
            delay_seconds.seconds,
            FtTaskExecutionJob,
            ft_task_id,
            execution.execution_id,
            job_args
          )
        else
          job_id = Resque.enqueue(
            FtTaskExecutionJob,
            ft_task_id,
            execution.execution_id,
            job_args
          )
        end

        execution.update!(resque_job_id: job_id) if job_id
        results << execution.html_json

      rescue => e
        errors << "Task #{ft_task_id}: #{e.message}"
      end
    end

    if errors.empty?
      render json: ok(results, "#{results.size} tasks queued successfully")
    else
      partial_result(results, errors)
    end
  end

  # 取消任务执行 POST /ft_task_execution/:id/cancel
  def cancel
    execution = resource_class.find(params[:id])

    unless execution.pending?
      return render json: error('Only pending executions can be cancelled')
    end

    begin
      # Try to remove from Resque queue if possible
      if execution.resque_job_id.present?
        # Note: Removing specific jobs from Resque queue is complex
        # This is a simplified approach
        Rails.logger.info("Attempting to cancel job: #{execution.resque_job_id}")
      end

      execution.cancelled!
      render json: ok(execution.html_json, 'Task execution cancelled')
    rescue => e
      render json: error("Failed to cancel task execution: #{e.message}")
    end
  end

  # 重新执行任务 POST /ft_task_execution/:id/retry
  def retry
    execution = resource_class.find(params[:id])

    unless execution.failed?
      return render json: error('Only failed executions can be retried')
    end

    begin
      # Increment retry count
      execution.increment_retry!

      # Create new execution record for the retry
      new_execution = FtTaskExecution.create!(
        task_id: execution.task_id,
        queue: execution.queue || 'task_execution',
        system_params: execution.system_params,
        custom_params: execution.custom_params
      )

      # Schedule the retry
      job_id = Resque.enqueue(
        FtTaskExecutionJob,
        execution.ft_task&.id,
        new_execution.execution_id,
        execution.custom_params
      )
      new_execution.update!(resque_job_id: job_id) if job_id

      render json: ok(new_execution.html_json, 'Task execution retried')
    rescue => e
      render json: error("Failed to retry task execution: #{e.message}")
    end
  end

  # 获取任务执行统计 GET /ft_task_execution/stats
  def stats
    total = resource_class.count
    by_status = resource_class.group(:status).count
    recent_24h = resource_class.where('created_at >= ?', 24.hours.ago).count
    avg_duration = resource_class.where.not(duration_seconds: nil).average(:duration_seconds)&.to_f&.round(2)

    stats = {
      total: total,
      by_status: by_status,
      recent_24h: recent_24h,
      average_duration_seconds: avg_duration,
      queue_info: queue_stats
    }

    render json: ok(stats)
  end

  private

  def queue_stats
    begin
      {
        total_queues: Resque.queues.size,
        queues: Resque.queues.map { |q| { name: q, size: Resque.size(q) } },
        workers: Resque.workers.size,
        working: Resque.working.size,
        failed: Resque::Failure.count
      }
    rescue => e
      { error: "Unable to fetch queue stats: #{e.message}" }
    end
  end

  def partial_result(successes, errors)
    render json: {
      success: true,
      data: successes,
      errors: errors,
      message: "Partial success: #{successes.size} succeeded, #{errors.size} failed"
    }, status: :ok
  end
end
