/**
 * URL参数同步工具使用示例
 */

import { ref } from 'vue'
import { useSyncUrlParams } from './syncUrlParams'

// ============= 示例1: 基本使用 =============
export function example1() {
  const filters = ref({
    keyword: '',
    category: '',
    page: 1
  })

  // 自动双向同步filters和URL参数
  useSyncUrlParams(filters)

  // 当修改filters时,URL会自动更新
  // filters.value.keyword = 'test'
  // URL变为: ?keyword=test

  // 当URL改变时(如用户点击浏览器后退),filters会自动更新
}

// ============= 示例2: 类型转换 =============
export function example2() {
  const filters = ref({
    project_id: null as number | null,
    page: 1,
    per_page: 20,
    is_active: true,
    tags: [] as string[]
  })

  useSyncUrlParams(filters, {
    // 这些字段从URL读取时转换为数字
    numberFields: ['project_id', 'page', 'per_page'],
    // 这些字段从URL读取时转换为布尔值
    booleanFields: ['is_active'],
    // 这些字段从URL读取时转换为数组
    arrayFields: ['tags']
  })

  // URL: ?project_id=123&page=2&is_active=true&tags=vue,react
  // 解析后:
  // filters.value = {
  //   project_id: 123,      // 数字
  //   page: 2,              // 数字
  //   per_page: 20,
  //   is_active: true,      // 布尔值
  //   tags: ['vue', 'react'] // 数组
  // }
}

// ============= 示例3: 排除字段 =============
export function example3() {
  const filters = ref({
    keyword: '',
    page: 1,
    localCache: 'some-data', // 不需要同步到URL
    tempValue: null          // 不需要同步到URL
  })

  useSyncUrlParams(filters, {
    // 排除这些字段,不同步到URL
    exclude: ['localCache', 'tempValue']
  })

  // 修改 keyword 会更新URL
  // 修改 localCache 不会影响URL
}

// ============= 示例4: 自定义序列化/反序列化 =============
export function example4() {
  const filters = ref({
    start_date: '',
    end_date: '',
    range: [] as Date[]
  })

  useSyncUrlParams(filters, {
    // 自定义序列化:对象到URL字符串
    serialize: (value, key) => {
      if (key === 'range' && Array.isArray(value) && value.length === 2) {
        // 日期范围转换为字符串
        return `${value[0].toISOString()},${value[1].toISOString()}`
      }
      return null // 使用默认序列化
    },

    // 自定义反序列化:URL字符串到对象
    deserialize: (value, key) => {
      if (key === 'range' && typeof value === 'string') {
        // 字符串转换回日期范围
        const [start, end] = value.split(',')
        return [new Date(start), new Date(end)]
      }
      return value // 使用默认反序列化
    }
  })
}

// ============= 示例5: 在AutomationLogsTab中使用 =============
export function example5_AutomationLogsTab() {
  const filters = ref({
    project_id: null as number | null,
    action_type: '',
    status: '',
    start_date: '',
    end_date: '',
    search: '',
    page: 1,
    per_page: 20
  })

  // 配置同步
  useSyncUrlParams(filters, {
    numberFields: ['project_id', 'page', 'per_page']
  })

  // 用户操作示例:
  // 1. 用户修改筛选条件
  //    filters.value.action_type = '规则触发'
  //    → URL自动变为: ?action_type=规则触发&page=1&per_page=20

  // 2. 用户刷新页面或分享URL
  //    URL: ?action_type=规则触发&page=2
  //    → filters自动恢复为: { action_type: '规则触发', page: 2, ... }

  // 3. 用户点击浏览器后退
  //    → filters自动恢复到上一个状态
}

// ============= 示例6: 手动控制同步 =============
export function example6() {
  const filters = ref({
    keyword: '',
    page: 1
  })

  const { syncToUrl, syncFromUrl } = useSyncUrlParams(filters)

  // 手动同步到URL(通常不需要,自动同步已经够用)
  function handleSearch() {
    filters.value.page = 1
    syncToUrl()
  }

  // 手动从URL同步(通常不需要,自动同步已经够用)
  function handleReset() {
    syncFromUrl()
  }
}

// ============= 完整的实际应用示例 =============
export function fullExample() {
  // 在Vue组件的setup中使用
  const filters = ref({
    project_id: null as number | null,
    action_type: '',
    status: '',
    start_date: '',
    end_date: '',
    search: '',
    page: 1,
    per_page: 20
  })

  // 启用URL同步
  useSyncUrlParams(filters, {
    numberFields: ['project_id', 'page', 'per_page']
  })

  // 其他组件逻辑
  const loadData = async () => {
    // 使用filters的值加载数据
    // 由于URL同步,刷新页面后filters会保持之前的值
    console.log('Loading with filters:', filters.value)
  }

  const resetFilters = () => {
    // 重置filters
    filters.value = {
      project_id: null,
      action_type: '',
      status: '',
      start_date: '',
      end_date: '',
      search: '',
      page: 1,
      per_page: 20
    }
    // URL会自动清空查询参数
  }

  return {
    filters,
    loadData,
    resetFilters
  }
}
