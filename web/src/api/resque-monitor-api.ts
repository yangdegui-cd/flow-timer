import request from '@/request'

export interface ResqueStats {
  overview: {
    processed: number
    failed: number
    pending: number
    queues: number
    workers: number
    working: number
  }
  redis_info: Record<string, any>
  queue_stats: Array<{ name: string; size: number }>
}

export interface ResqueQueue {
  name: string
  size: number
  jobs: ResqueJob[]
}

export interface ResqueJob {
  class: string
  args: any[]
  created_at?: string
  queue?: string
}

export interface ResqueWorker {
  id: string
  state: string
  started_at?: string
  processed: number
  failed: number
  current_job?: ResqueJob
  host: string
  pid: string
  queues: string[]
}

export interface ResqueFailedJob {
  failed_at: string
  exception: string
  error: string
  backtrace: string[]
  worker: string
  queue: string
  payload: {
    class: string
    args: any[]
  }
}

export interface ResqueFailedJobsResponse {
  total: number
  jobs: ResqueFailedJob[]
}

export interface ResqueScheduledJobs {
  delayed_jobs_count: number
  scheduled_jobs: Record<string, any>
  scheduler_info: {
    enabled?: boolean
    started?: boolean
    master_lock?: any
    supported: boolean
  }
}

export interface ResqueDelayedJob {
  timestamp: string
  formatted_time: string
  jobs: ResqueJob[]
}

export interface ResqueDelayedJobsResponse {
  total: number
  jobs: ResqueDelayedJob[]
}

// 获取 Resque 统计信息
export const ApiGetResqueStats = () => {
  return request.get<ResqueStats>('/resque_monitor/stats')
}

// 获取所有队列信息
export const ApiGetResqueQueues = () => {
  return request.get<ResqueQueue[]>('/resque_monitor/queues')
}

// 获取特定队列详情
export const ApiGetResqueQueueDetail = (name: string, start = 0, count = 20) => {
  return request.get<ResqueQueue>(`/resque_monitor/queue/${name}`, {
    params: { start, count }
  })
}

// 获取所有 Worker 信息
export const ApiGetResqueWorkers = () => {
  return request.get<ResqueWorker[]>('/resque_monitor/workers')
}

// 获取失败任务列表
export const ApiGetResqueFailedJobs = (start = 0, count = 20) => {
  return request.get<ResqueFailedJobsResponse>('/resque_monitor/failed_jobs', {
    params: { start, count }
  })
}

// 重试失败任务
export const ApiRetryFailedJob = (id: number) => {
  return request.post(`/resque_monitor/failed/${id}/retry`)
}

// 清空所有失败任务
export const ApiClearFailedJobs = () => {
  return request.delete('/resque_monitor/clear_failed')
}

// 删除队列
export const ApiRemoveQueue = (name: string) => {
  return request.delete(`/resque_monitor/queue/${name}`)
}

// 清空队列
export const ApiClearQueue = (name: string) => {
  return request.delete(`/resque_monitor/queue/${name}/clear`)
}

// 重启所有 Worker
export const ApiRestartWorkers = () => {
  return request.post('/resque_monitor/restart_workers')
}

// 获取队列详细信息（包含更多任务）
export const ApiGetResqueQueueDetails = (name: string, start = 0, count = 50) => {
  return request.get<ResqueQueue>(`/resque_monitor/queue/${name}/details`, {
    params: { start, count }
  })
}

// 重新排队所有失败任务
export const ApiRequeueAllFailedJobs = () => {
  return request.post('/resque_monitor/requeue_all_failed')
}

// 删除单个失败任务
export const ApiRemoveFailedJob = (id: number) => {
  return request.delete(`/resque_monitor/failed/${id}`)
}

// resque-scheduler 相关 API
// 获取调度任务信息
export const ApiGetResqueScheduledJobs = () => {
  return request.get<ResqueScheduledJobs>('/resque_monitor/scheduled_jobs')
}

// 获取延迟任务列表
export const ApiGetResqueDelayedJobs = (start = 0, count = 20) => {
  return request.get<ResqueDelayedJobsResponse>('/resque_monitor/delayed_jobs', {
    params: { start, count }
  })
}

// 清空所有延迟任务
export const ApiClearDelayedJobs = () => {
  return request.delete('/resque_monitor/clear_delayed_jobs')
}

// 删除特定延迟任务
export const ApiRemoveDelayedJob = (timestamp: string, jobClass: string, args: any[]) => {
  return request.delete(`/resque_monitor/delayed/${timestamp}/${jobClass}`, {
    data: { args: JSON.stringify(args) }
  })
}