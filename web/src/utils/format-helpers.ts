/**
 * 格式化辅助函数
 */

/**
 * 根据配置格式化数值
 * @param value 原始值
 * @param displayConfig 展示配置 {format: 'currency'|'percent'|'number', decimals: number}
 * @param unit 单位
 */
export function formatValue(value: any, displayConfig?: any, unit?: string): string {
  if (value === null || value === undefined || value === '') return '-'
  if (isNaN(value)) return String(value)

  const config = displayConfig || {}
  const decimals = config.decimals !== undefined ? config.decimals : 2
  const numValue = Number(value)

  switch (config.format) {
    case 'currency':
      // 货币格式
      return formatCurrency(numValue, decimals, unit)
    case 'percent':
      // 百分比格式
      return formatPercent(numValue, decimals)
    case 'number':
    default:
      return formatNumber(numValue, decimals)
  }
}

/**
 * 格式化货币
 */
export function formatCurrency(value: number, decimals: number = 2, unit?: string): string {
  const symbol = getCurrencySymbol(unit)
  return `${symbol}${formatNumber(value, decimals)}`
}

/**
 * 获取货币符号
 */
function getCurrencySymbol(unit?: string): string {
  if (!unit) return '$'

  const currencyMap: Record<string, string> = {
    '$': '$',
    '¥': '¥',
    '元': '¥',
    'USD': '$',
    'CNY': '¥',
    'EUR': '€',
    'GBP': '£'
  }

  return currencyMap[unit] || unit
}

/**
 * 格式化百分比
 */
export function formatPercent(value: number, decimals: number = 2): string {
  return `${formatNumber(value, decimals)}%`
}

/**
 * 格式化数字（添加千分位分隔符）
 */
export function formatNumber(value: number, decimals: number = 0): string {
  if (isNaN(value)) return '-'

  const fixed = value.toFixed(decimals)
  const parts = fixed.split('.')

  // 添加千分位分隔符
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',')

  return parts.join('.')
}

/**
 * 截断长文本并添加省略号
 */
export function ellipsis(text: string, maxLength: number = 30): string {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}
