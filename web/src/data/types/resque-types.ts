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
