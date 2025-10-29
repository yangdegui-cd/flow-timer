import { watch, type Ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'

/**
 * URL参数同步工具
 * 实现filters对象与URL query参数的双向同步
 *
 * @param filters - ref对象,包含筛选参数
 * @param options - 配置选项
 * @returns 同步控制函数
 */
export const useSyncUrlParams = <T extends Record<string, any>>(
  filters: Ref<T>,
  options?: {
    // 需要排除的字段,不同步到URL
    exclude?: string[]
    // 需要转换为数字的字段
    numberFields?: string[]
    // 需要转换为布尔值的字段
    booleanFields?: string[]
    // 需要转换为数组的字段
    arrayFields?: string[]
    // 自定义序列化函数
    serialize?: (value: any, key: string) => string | null
    // 自定义反序列化函数
    deserialize?: (value: string, key: string) => any
  }
) => {
  const router = useRouter()
  const route = useRoute()

  const {
    exclude = [],
    numberFields = [],
    booleanFields = [],
    arrayFields = [],
    serialize,
    deserialize
  } = options || {}

  // 标记是否正在更新,防止循环触发
  let isUpdating = false

  /**
   * 将filters对象序列化为URL query参数
   */
  const serializeFilters = (filters: T): Record<string, string> => {
    const query: Record<string, string> = {}

    Object.keys(filters).forEach(key => {
      // 跳过排除的字段
      if (exclude.includes(key)) return

      const value = filters[key]
      // 跳过null、undefined、空字符串
      if (value === null || value === undefined || value === '') return
      // 自定义序列化
      if (serialize) {
        const serialized = serialize(value, key)
        if (serialized !== null) {
          query[key] = serialized
        }
        return
      }
      // 数组类型
      if (arrayFields.includes(key) && Array.isArray(value)) {
        if (value.length > 0) {
          query[key] = value.join(',')
        }
        return
      }
      // Date对象转换为字符串
      if (value instanceof Date) {
        query[key] = value.toISOString()
        return
      }
      // 其他类型直接转字符串
      query[key] = String(value)
    })

    return query
  }

  /**
   * 从URL query参数反序列化为filters对象
   */
  const deserializeQuery = (query: Record<string, any>): Partial<T> => {
    const result: Partial<T> = {}

    Object.keys(query).forEach(key => {
      // 跳过排除的字段
      if (exclude.includes(key)) return

      const value = query[key]

      // 跳过空值
      if (value === null || value === undefined || value === '') return

      // 自定义反序列化
      if (deserialize) {
        result[key as keyof T] = deserialize(value, key)
        return
      }

      // 数字类型
      if (numberFields.includes(key)) {
        const num = Number(value)
        if (!isNaN(num)) {
          result[key as keyof T] = num as any
        }
        return
      }

      // 布尔类型
      if (booleanFields.includes(key)) {
        result[key as keyof T] = (value === 'true' || value === '1') as any
        return
      }

      // 数组类型
      if (arrayFields.includes(key)) {
        result[key as keyof T] = (typeof value === 'string' ? value.split(',') : [value]) as any
        return
      }

      // 其他类型保持原样
      result[key as keyof T] = value
    })

    return result
  }

  /**
   * 同步filters到URL
   */
  const syncToUrl = () => {
    if (isUpdating) return

    isUpdating = true

    const query = serializeFilters(filters.value)

    // 只有当query真正改变时才更新路由
    const currentQuery = route.query
    const queryChanged = JSON.stringify(query) !== JSON.stringify(currentQuery)

    if (queryChanged) {
      router.replace({
        query
      }).catch(() => {
        // 忽略导航重复错误
      })
    }

    isUpdating = false
  }

  /**
   * 从URL同步到filters
   */
  const syncFromUrl = () => {
    if (isUpdating) retur
    isUpdating = true
    const parsed = deserializeQuery(route.query)
    // 合并到filters,保留filters中未在URL中的字段
    Object.keys(parsed).forEach(key => {
      filters.value[key as keyof T] = parsed[key as keyof T] as any
    })
    isUpdating = false
  }

  // 监听filters变化,同步到URL
  watch(() => filters.value, () => syncToUrl(), { deep: true })

  // 监听URL变化,同步到filters
  watch(() => route.query, () => syncFromUrl(), { immediate: true })

  // 返回控制函数
  return {
    syncToUrl,
    syncFromUrl,
    serializeFilters,
    deserializeQuery
  }
}

export default useSyncUrlParams
