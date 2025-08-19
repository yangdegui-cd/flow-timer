# frozen_string_literal: true

class ResqueMonitorChannel < ApplicationCable::Channel
  def subscribed
    stream_from "resque_monitor"
    Rails.logger.info "ResqueMonitorChannel subscribed: #{connection.current_user&.id}"
  end

  def unsubscribed
    Rails.logger.info "ResqueMonitorChannel unsubscribed: #{connection.current_user&.id}"
  end

  def subscribe(data)
    Rails.logger.info "ResqueMonitorChannel subscribe action called with: #{data}"

    # 获取请求的标签页数据
    tabs = data['tabs'] || []

    # 收集数据
    response_data = {}

    if tabs.include?('stats')
      response_data['stats'] = fetch_stats
    end

    if tabs.include?('queues')
      response_data['queues'] = fetch_queues
    end

    if tabs.include?('workers')
      response_data['workers'] = fetch_workers
    end

    if tabs.include?('failed')
      response_data['failed_jobs'] = fetch_failed_jobs
    end

    if tabs.include?('scheduled')
      response_data['scheduled_jobs'] = fetch_scheduled_jobs
    end

    if tabs.include?('delayed')
      response_data['delayed_jobs'] = fetch_delayed_jobs
    end

    # 发送完整数据
    transmit({
               type: 'update',
               payload: response_data,
               timestamp: Time.current
             })
  rescue => e
    Rails.logger.error "ResqueMonitorChannel subscribe error: #{e.message}"
    transmit({
               type: 'error',
               payload: { message: e.message }
             })
  end

  def refresh(data = {})
    Rails.logger.info "ResqueMonitorChannel refresh action called"

    # 刷新所有数据
    subscribe({ 'tabs' => ['stats', 'queues', 'workers', 'failed', 'scheduled', 'delayed'] })
  end

  private

  def fetch_stats
    begin
      stats = {}

      # Redis 连接
      redis = Resque.redis

      # 基础统计
      stats[:overview] = {
        processed: Resque.info[:processed] || 0,
        failed: Resque.info[:failed] || 0,
        pending: Resque.info[:pending] || 0,
        queues: Resque.info[:queues] || 0,
        workers: Resque.info[:workers] || 0,
        working: Resque.info[:working] || 0
      }

      # Redis 信息
      redis_info = redis.info
      stats[:redis_info] = {
        redis_version: redis_info['redis_version'],
        used_memory_human: redis_info['used_memory_human'],
        connected_clients: redis_info['connected_clients'],
        uptime_in_seconds: redis_info['uptime_in_seconds'].to_i
      }

      stats
    rescue => e
      Rails.logger.error "Error fetching stats: #{e.message}"
      { error: e.message }
    end
  end

  def fetch_queues
    begin
      Resque.queues.map do |queue_name|
        queue_size = Resque.size(queue_name)
        jobs = []

        # 获取队列中的前几个任务
        if queue_size > 0
          jobs = Resque.peek(queue_name, 0, 10).map do |job|
            {
              class: job['class'],
              args: job['args'],
              created_at: job['created_at']
            }
          end
        end

        {
          name: queue_name,
          size: queue_size,
          jobs: jobs
        }
      end
    rescue => e
      Rails.logger.error "Error fetching queues: #{e.message}"
      []
    end
  end

  def fetch_workers
    begin
      Resque::Worker.all.map do |worker|
        {
          id: worker.to_s,
          state: worker.state,
          processed: worker.processed,
          failed: worker.failed,
          current_job: worker.job,
          queues: worker.queues
        }
      end
    rescue => e
      Rails.logger.error "Error fetching workers: #{e.message}"
      []
    end
  end

  def fetch_failed_jobs
    begin
      failed_jobs = Resque::Failure.all(0, 50)
      total = Resque::Failure.count

      jobs = failed_jobs.map.with_index do |job, index|
        {
          index: index,
          failed_at: job['failed_at'],
          payload: job['payload'],
          queue: job['queue'],
          exception: job['exception'],
          error: job['error'],
          backtrace: job['backtrace'],
          worker: job['worker']
        }
      end

      { jobs: jobs, total: total }
    rescue => e
      Rails.logger.error "Error fetching failed jobs: #{e.message}"
      { jobs: [], total: 0 }
    end
  end

  def fetch_scheduled_jobs
    if defined?(Resque::Scheduler)
      delayed_jobs = Resque.delayed_queue_schedule_size
      scheduled_jobs = Resque.schedule || {}

      {
        delayed_jobs_count: delayed_jobs,
        scheduled_jobs: scheduled_jobs,
        scheduler_info: {
          enabled: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:enabled?) ? Resque::Scheduler.enabled? : true,
          started: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:started?) ? Resque::Scheduler.started? : true,
          master_lock: defined?(Resque::Scheduler) && Resque::Scheduler.respond_to?(:master_lock) ? Resque::Scheduler.master_lock : nil,
          supported: true
        }
      }
    else
      {
        delayed_jobs_count: 0,
        scheduled_jobs: {},
        scheduler_info: {
          supported: false
        }
      }
    end
  end

  def fetch_delayed_jobs
    begin
      if defined?(Resque::Scheduler)
        delayed_jobs = []
        total = 0

        # 获取延迟队列中的任务
        timestamps = Resque.delayed_queue_peek(0, 10000)

        timestamps.each do |timestamp|
          jobs_at_time = Resque.delayed_timestamp_peek(timestamp, 0, 10000)
          delayed_jobs << {
            timestamp: timestamp,
            formatted_time: Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S'),
            jobs: jobs_at_time.map do |job|
              {
                class: job['class'],
                args: job['args'],
                queue: job['queue']
              }
            end
          }
        end

        total = Resque.delayed_queue_schedule_size
        { jobs: delayed_jobs, total: total }
      else
        { jobs: [], total: 0 }
      end
    rescue => e
      Rails.logger.error "Error fetching delayed jobs: #{e.message}"
      { jobs: [], total: 0 }
    end
  end
end
