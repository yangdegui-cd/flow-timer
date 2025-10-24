/**
 * 流程管理相关默认数据工厂函数
 */

import type { 
  FlowFormData, 
  TaskFormData, 
  ScriptTaskConfig, 
  HttpTaskConfig,
  DatabaseTaskConfig,
  NotificationTaskConfig 
} from '../types'

// 创建流程表单默认数据
export const createFlowDefaults = (): FlowFormData => ({
  name: '',
  description: '',
  trigger_type: 'manual',
  priority: 'normal',
  cron_expression: '',
  webhook_url: '',
  is_enabled: true,
  tags: []
})

// 创建任务表单默认数据
export const createTaskDefaults = (): TaskFormData => ({
  name: '',
  description: '',
  type: 'script',
  order: 1,
  config: {},
  timeout: 300,
  max_retries: 3,
  depends_on: [],
  condition: '',
  is_enabled: true
})

// 创建脚本任务配置默认数据
export const createScriptTaskConfigDefaults = (): ScriptTaskConfig => ({
  script_type: 'shell',
  script_content: '',
  working_directory: '',
  environment_variables: {}
})

// 创建HTTP任务配置默认数据
export const createHttpTaskConfigDefaults = (): HttpTaskConfig => ({
  method: 'GET',
  url: '',
  headers: {},
  body: '',
  expected_status: [200]
})

// 创建数据库任务配置默认数据
export const createDatabaseTaskConfigDefaults = (): DatabaseTaskConfig => ({
  connection_id: 0,
  query: '',
  query_type: 'select'
})

// 创建通知任务配置默认数据
export const createNotificationTaskConfigDefaults = (): NotificationTaskConfig => ({
  type: 'email',
  recipients: [],
  subject: '',
  message: '',
  webhook_url: ''
})

// 根据任务类型创建对应的配置默认数据
export const createTaskConfigDefaults = (taskType: string) => {
  switch (taskType) {
    case 'script':
      return createScriptTaskConfigDefaults()
    case 'http':
      return createHttpTaskConfigDefaults()
    case 'database':
      return createDatabaseTaskConfigDefaults()
    case 'notification':
      return createNotificationTaskConfigDefaults()
    default:
      return {}
  }
}