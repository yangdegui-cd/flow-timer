class ResqueMonitorController < ApplicationController
  def stats
    info = Resque.info
    
    stats = {
      overview: {
        processed: info[:processed] || 0,
        failed: info[:failed] || 0,
        pending: info[:pending] || 0,
        queues: info[:queues] || 0,
        workers: info[:workers] || 0,
        working: info[:working] || 0
      },
      redis_info: Resque.redis.info,
      queue_stats: Resque.queues.map { |q| { name: q, size: Resque.size(q) } }
    }
    
    render json: ok(stats)
  end

  def queues
    queues_data = Resque.queues.map do |queue|
      {
        name: queue,
        size: Resque.size(queue),
        jobs: Resque.peek(queue, 0, 10).map { |job| format_job(job) }
      }
    end
    
    render json: ok(queues_data)
  end

  def queue_detail
    queue_name = params[:name]
    start = params[:start]&.to_i || 0
    count = params[:count]&.to_i || 20
    
    jobs = Resque.peek(queue_name, start, count).map { |job| format_job(job) }
    
    render json: ok({
      name: queue_name,
      size: Resque.size(queue_name),
      jobs: jobs
    })
  end

  def workers
    workers_data = Resque.workers.map do |worker|
      job = worker.job
      {
        id: worker.to_s,
        state: worker.state,
        started_at: worker.started,
        processed: worker.processed,
        failed: worker.failed,
        current_job: job ? format_job(job) : nil,
        host: worker.to_s.split(':')[0],
        pid: worker.to_s.split(':')[1],
        queues: worker.to_s.split(':')[2]&.split(',') || []
      }
    end
    
    render json: ok(workers_data)
  end

  def failed_jobs
    start = params[:start]&.to_i || 0
    count = params[:count]&.to_i || 20
    
    failed_jobs = if Resque::Failure.respond_to?(:all)
      Resque::Failure.all(start, count)
    else
      []
    end
    
    formatted_jobs = failed_jobs.map.with_index(start) do |job, index|
      {
        index: index,
        failed_at: job['failed_at'],
        exception: job['exception'],
        error: job['error'],
        backtrace: job['backtrace'],
        worker: job['worker'],
        queue: job['queue'],
        payload: job['payload'],
        retried_at: job['retried_at']
      }
    end
    
    render json: ok({
      total: Resque::Failure.respond_to?(:count) ? Resque::Failure.count : 0,
      jobs: formatted_jobs
    })
  end

  def retry_failed
    id = params[:id].to_i
    job = Resque::Failure.all(id, 1).first
    
    if job
      Resque::Job.create(job['queue'], job['payload']['class'], *job['payload']['args'])
      Resque::Failure.remove(id)
      render json: ok({ message: '任务已重新加入队列' })
    else
      render json: error('任务不存在')
    end
  end

  def clear_failed
    Resque::Failure.clear
    render json: ok({ message: '所有失败任务已清除' })
  end

  def remove_queue
    queue_name = params[:name]
    Resque.remove_queue(queue_name)
    render json: ok({ message: "队列 #{queue_name} 已删除" })
  end

  def clear_queue
    queue_name = params[:name]
    while Resque.size(queue_name) > 0
      Resque.pop(queue_name)
    end
    render json: ok({ message: "队列 #{queue_name} 已清空" })
  end

  def restart_workers
    # 这是一个危险操作，实际项目中需要更谨慎的权限控制
    Resque.workers.each(&:unregister_worker)
    render json: ok({ message: 'Worker重启信号已发送' })
  end

  # resque-scheduler 相关功能
  def scheduled_jobs
    if defined?(Resque::Scheduler)
      delayed_jobs = Resque.delayed_queue_schedule_size
      scheduled_jobs = Resque.schedule || {}
      
      render json: ok({
        delayed_jobs_count: delayed_jobs,
        scheduled_jobs: scheduled_jobs,
        scheduler_info: {
          enabled: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:enabled?) ? Resque::Scheduler.enabled? : true,
          started: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:started?) ? Resque::Scheduler.started? : true,
          master_lock: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:master_lock) ? Resque::Scheduler.master_lock : nil,
          supported: true
        }
      })
    else
      render json: ok({
        delayed_jobs_count: 0,
        scheduled_jobs: {},
        scheduler_info: {
          supported: false
        }
      })
    end
  end

  def delayed_jobs
    start = params[:start]&.to_i || 0
    count = params[:count]&.to_i || 20
    
    if defined?(Resque::Scheduler)
      delayed_timestamps = Resque.delayed_queue_peek(start, count)
      jobs = delayed_timestamps.map do |timestamp|
        jobs_at_timestamp = Resque.delayed_timestamp_peek(timestamp, 0, 10)
        {
          timestamp: timestamp,
          formatted_time: Time.at(timestamp.to_f).strftime('%Y-%m-%d %H:%M:%S'),
          jobs: jobs_at_timestamp.map { |job| format_job(job) }
        }
      end
      
      render json: ok({
        total: Resque.delayed_queue_schedule_size,
        jobs: jobs
      })
    else
      render json: ok({ total: 0, jobs: [] })
    end
  end

  def remove_delayed_job
    timestamp = params[:timestamp]
    job_class = params[:job_class]
    args = JSON.parse(params[:args] || '[]')
    
    if defined?(Resque::Scheduler)
      removed = Resque.remove_delayed(job_class, *args)
      render json: ok({ message: "已删除 #{removed} 个延迟任务" })
    else
      render json: error('resque-scheduler 未安装')
    end
  end

  def clear_delayed_jobs
    if defined?(Resque::Scheduler)
      Resque.reset_delayed_queue
      render json: ok({ message: '所有延迟任务已清除' })
    else
      render json: error('resque-scheduler 未安装')
    end
  end

  # 获取详细的队列信息
  def queue_details
    queue_name = params[:name]
    start = params[:start]&.to_i || 0
    count = params[:count]&.to_i || 50
    
    jobs = Resque.peek(queue_name, start, count).map { |job| format_job(job) }
    
    render json: ok({
      name: queue_name,
      size: Resque.size(queue_name),
      jobs: jobs,
      start: start,
      count: count
    })
  end

  # 重新排队所有失败任务
  def requeue_all_failed
    if Resque::Failure.respond_to?(:requeue_all)
      Resque::Failure.requeue_all
      render json: ok({ message: '所有失败任务已重新排队' })
    else
      render json: error('不支持批量重新排队')
    end
  end

  # 删除单个失败任务
  def remove_failed_job
    id = params[:id].to_i
    if Resque::Failure.respond_to?(:remove)
      Resque::Failure.remove(id)
      render json: ok({ message: '失败任务已删除' })
    else
      render json: error('不支持删除失败任务')
    end
  end

  private

  def format_job(job)
    {
      class: job['class'] || job[:class],
      args: job['args'] || job[:args],
      created_at: job['created_at'],
      queue: job['queue']
    }
  end
end