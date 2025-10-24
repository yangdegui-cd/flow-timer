import { BaseApi } from './base-api'
import type {
  ResqueStats,
  ResqueQueue,
  ResqueWorker,
  ResqueFailedJobsResponse,
  ResqueScheduledJobs,
  ResqueDelayedJobsResponse
} from '@/data/types/resque-types'

// Resque监控API类
class ResqueMonitorApi extends BaseApi {
  constructor() {
    super('resque_monitor')
  }

  // 获取 Resque 统计信息
  async getStats(): Promise<ResqueStats> {
    return this.get<ResqueStats>('stats')
  }

  // 获取所有队列信息
  async getQueues(): Promise<ResqueQueue[]> {
    return this.get<ResqueQueue[]>('queues')
  }

  // 获取特定队列详情
  async getQueueDetail(name: string, start = 0, count = 20): Promise<ResqueQueue> {
    return this.get<ResqueQueue>(`queue/${name}`, { start, count })
  }

  // 获取所有 Worker 信息
  async getWorkers(): Promise<ResqueWorker[]> {
    return this.get<ResqueWorker[]>('workers')
  }

  // 获取失败任务列表
  async getFailedJobs(start = 0, count = 20): Promise<ResqueFailedJobsResponse> {
    return this.get<ResqueFailedJobsResponse>('failed_jobs', { start, count })
  }

  // 重试失败任务
  async retryFailedJob(id: number): Promise<void> {
    return this.post<void>(`failed/${id}/retry`)
  }

  // 清空所有失败任务
  async clearFailedJobs(): Promise<void> {
    return this.delete<void>('clear_failed')
  }

  // 删除队列
  async removeQueue(name: string): Promise<void> {
    return this.delete<void>(`queue/${name}`)
  }

  // 清空队列
  async clearQueue(name: string): Promise<void> {
    return this.delete<void>(`queue/${name}/clear`)
  }

  // 重启所有 Worker
  async restartWorkers(): Promise<void> {
    return this.post<void>('restart_workers')
  }

  // 获取队列详细信息（包含更多任务）
  async getQueueDetails(name: string, start = 0, count = 50): Promise<ResqueQueue> {
    return this.get<ResqueQueue>(`queue/${name}/details`, { start, count })
  }

  // 重新排队所有失败任务
  async requeueAllFailedJobs(): Promise<void> {
    return this.post<void>('requeue_all_failed')
  }

  // 删除单个失败任务
  async removeFailedJob(id: number): Promise<void> {
    return this.delete<void>(`failed/${id}`)
  }

  // resque-scheduler 相关 API
  // 获取调度任务信息
  async getScheduledJobs(): Promise<ResqueScheduledJobs> {
    return this.get<ResqueScheduledJobs>('scheduled_jobs')
  }

  // 获取延迟任务列表
  async getDelayedJobs(start = 0, count = 20): Promise<ResqueDelayedJobsResponse> {
    return this.get<ResqueDelayedJobsResponse>('delayed_jobs', { start, count })
  }

  // 清空所有延迟任务
  async clearDelayedJobs(): Promise<void> {
    return this.delete<void>('clear_delayed_jobs')
  }

  // 删除特定延迟任务
  async removeDelayedJob(timestamp: string, jobClass: string, args: any[]): Promise<void> {
    return this.delete<void>(`delayed/${timestamp}/${jobClass}`, { args: JSON.stringify(args) })
  }
}

// 导出单例实例
const resqueMonitorApi = new ResqueMonitorApi()
export default resqueMonitorApi
