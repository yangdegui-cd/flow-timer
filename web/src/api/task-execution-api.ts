import { ApiList, ApiShow } from './base-api'
import request from '@/request'

export interface TaskExecution {
  id: number
  ft_task_id: number
  execution_id: string
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled'
  result?: any
  error_message?: string
  started_at?: string
  finished_at?: string
  duration_seconds?: number
  job_class: string
  job_args?: any
  queue_name: string
  resque_job_id?: string
  retry_count: number
  created_at: string
  updated_at: string
  ft_task?: {
    id: number
    name: string
    description: string
  }
  duration_formatted?: string
  parsed_result?: any
  parsed_job_args?: any
}

export interface TaskExecutionStats {
  total: number
  by_status: Record<string, number>
  recent_24h: number
  average_duration_seconds?: number
  queue_info: {
    total_queues: number
    queues: Array<{ name: string; size: number }>
    workers: number
    working: number
    failed: number
  }
}

export interface ExecuteTaskRequest {
  ft_task_id: number
  job_args?: Record<string, any>
  delay_seconds?: number
}

export interface BatchExecuteTaskRequest {
  task_ids: number[]
  job_args?: Record<string, any>
  delay_seconds?: number
}

// 执行单个任务
export const ApiExecuteTask = (data: ExecuteTaskRequest) => {
  return request.post('/ft_task_execution/execute', data)
}

// 批量执行任务
export const ApiBatchExecuteTask = (data: BatchExecuteTaskRequest) => {
  return request.post('/ft_task_execution/batch_execute', data)
}

// 取消任务执行
export const ApiCancelTaskExecution = (id: number) => {
  return request.post(`/ft_task_execution/${id}/cancel`)
}

// 重试任务执行
export const ApiRetryTaskExecution = (id: number) => {
  return request.post(`/ft_task_execution/${id}/retry`)
}

// 获取任务执行列表
export const ApiGetTaskExecutions = (params?: any) => {
  return ApiList('ft_task_execution', params)
}

// 获取任务执行详情
export const ApiGetTaskExecution = (id: number) => {
  return ApiShow('ft_task_execution', id)
}

// 获取任务执行统计
export const ApiGetTaskExecutionStats = () => {
  return request.get('/ft_task_execution/stats')
}

// 删除任务执行记录 - 禁用状态
export const ApiDeleteTaskExecution = (id: number) => {
  throw new Error('执行记录不允许删除')
}

// 批量删除任务执行记录 - 禁用状态
export const ApiBatchDeleteTaskExecutions = (ids: number[]) => {
  throw new Error('执行记录不允许批量删除')
}

export const ApiGetTaskExecutionResult = (id: number) => {
  return request({
    url: "/ft_task_execution/show_result",
    method: 'get',
    params: { id }
  });
}
