# frozen_string_literal: true

class ResqueMonitorBroadcastJob < ApplicationJob
  queue_as :default

  def perform
    # 广播 Resque 监控数据更新
    broadcast_stats_update
  rescue => e
    Rails.logger.error "ResqueMonitorBroadcastJob error: #{e.message}"
  end

  private

  def broadcast_stats_update
    # 获取当前统计数据
    stats = fetch_current_stats
    
    # 只广播概览统计，避免发送过多数据
    ActionCable.server.broadcast 'resque_monitor', {
      type: 'update',
      payload: {
        stats: stats
      },
      timestamp: Time.current
    }
  end

  def fetch_current_stats
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
      Rails.logger.error "Error fetching stats for broadcast: #{e.message}"
      { error: e.message }
    end
  end
end