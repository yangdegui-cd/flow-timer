/**
 * 流程管理相关常量定义
 */

import type { FlowStatus, FlowTriggerType, FlowPriority, TaskStatus, TaskType } from '../types'

// 流程状态选项
export const FLOW_STATUS_OPTIONS = [
  { label: '草稿', value: 'draft' as FlowStatus },
  { label: '活跃', value: 'active' as FlowStatus },
  { label: '暂停', value: 'paused' as FlowStatus },
  { label: '已归档', value: 'archived' as FlowStatus }
] as const

// 流程触发类型选项
export const FLOW_TRIGGER_TYPE_OPTIONS = [
  { label: '手动执行', value: 'manual' as FlowTriggerType },
  { label: '定时执行', value: 'scheduled' as FlowTriggerType },
  { label: 'Webhook触发', value: 'webhook' as FlowTriggerType },
  { label: '事件触发', value: 'event' as FlowTriggerType }
] as const

// 流程优先级选项
export const FLOW_PRIORITY_OPTIONS = [
  { label: '低', value: 'low' as FlowPriority },
  { label: '普通', value: 'normal' as FlowPriority },
  { label: '高', value: 'high' as FlowPriority },
  { label: '紧急', value: 'urgent' as FlowPriority }
] as const

// 任务状态选项
export const TASK_STATUS_OPTIONS = [
  { label: '等待中', value: 'pending' as TaskStatus },
  { label: '运行中', value: 'running' as TaskStatus },
  { label: '已完成', value: 'completed' as TaskStatus },
  { label: '失败', value: 'failed' as TaskStatus },
  { label: '跳过', value: 'skipped' as TaskStatus },
  { label: '已取消', value: 'cancelled' as TaskStatus }
] as const

// 任务类型选项
export const TASK_TYPE_OPTIONS = [
  { label: '脚本执行', value: 'script' as TaskType },
  { label: 'HTTP请求', value: 'http' as TaskType },
  { label: '数据库操作', value: 'database' as TaskType },
  { label: '文件操作', value: 'file' as TaskType },
  { label: '通知', value: 'notification' as TaskType },
  { label: '条件判断', value: 'condition' as TaskType },
  { label: '延时等待', value: 'delay' as TaskType }
] as const

// 流程状态标签映射
export const FLOW_STATUS_LABELS = {
  draft: '草稿',
  active: '活跃',
  paused: '暂停',
  archived: '已归档'
} as const

// 流程状态颜色映射
export const FLOW_STATUS_COLORS = {
  draft: 'secondary',
  active: 'success',
  paused: 'warning',
  archived: 'info'
} as const

// 流程触发类型标签映射
export const FLOW_TRIGGER_TYPE_LABELS = {
  manual: '手动执行',
  scheduled: '定时执行',
  webhook: 'Webhook触发',
  event: '事件触发'
} as const

// 流程优先级标签映射
export const FLOW_PRIORITY_LABELS = {
  low: '低',
  normal: '普通',
  high: '高',
  urgent: '紧急'
} as const

// 流程优先级颜色映射
export const FLOW_PRIORITY_COLORS = {
  low: 'info',
  normal: 'secondary',
  high: 'warning',
  urgent: 'danger'
} as const

// 任务状态标签映射
export const TASK_STATUS_LABELS = {
  pending: '等待中',
  running: '运行中',
  completed: '已完成',
  failed: '失败',
  skipped: '跳过',
  cancelled: '已取消'
} as const

// 任务状态颜色映射
export const TASK_STATUS_COLORS = {
  pending: 'secondary',
  running: 'info',
  completed: 'success',
  failed: 'danger',
  skipped: 'warning',
  cancelled: 'contrast'
} as const

// 任务类型标签映射
export const TASK_TYPE_LABELS = {
  script: '脚本执行',
  http: 'HTTP请求',
  database: '数据库操作',
  file: '文件操作',
  notification: '通知',
  condition: '条件判断',
  delay: '延时等待'
} as const

// 脚本类型选项
export const SCRIPT_TYPE_OPTIONS = [
  { label: 'Shell', value: 'shell' },
  { label: 'Python', value: 'python' },
  { label: 'Node.js', value: 'nodejs' }
] as const

// HTTP方法选项
export const HTTP_METHOD_OPTIONS = [
  { label: 'GET', value: 'GET' },
  { label: 'POST', value: 'POST' },
  { label: 'PUT', value: 'PUT' },
  { label: 'DELETE', value: 'DELETE' },
  { label: 'PATCH', value: 'PATCH' }
] as const

// 数据库查询类型选项
export const DATABASE_QUERY_TYPE_OPTIONS = [
  { label: '查询', value: 'select' },
  { label: '插入', value: 'insert' },
  { label: '更新', value: 'update' },
  { label: '删除', value: 'delete' }
] as const

// 通知类型选项
export const NOTIFICATION_TYPE_OPTIONS = [
  { label: '邮件', value: 'email' },
  { label: 'Webhook', value: 'webhook' },
  { label: 'Slack', value: 'slack' }
] as const

// 常用 Cron 表达式
export const COMMON_CRON_EXPRESSIONS = [
  { label: '每分钟', value: '* * * * *' },
  { label: '每5分钟', value: '*/5 * * * *' },
  { label: '每15分钟', value: '*/15 * * * *' },
  { label: '每30分钟', value: '*/30 * * * *' },
  { label: '每小时', value: '0 * * * *' },
  { label: '每6小时', value: '0 */6 * * *' },
  { label: '每12小时', value: '0 */12 * * *' },
  { label: '每天凌晨', value: '0 0 * * *' },
  { label: '每周一凌晨', value: '0 0 * * 1' },
  { label: '每月1号凌晨', value: '0 0 1 * *' }
] as const