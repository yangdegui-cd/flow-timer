import dayjs from 'dayjs'

export const formatDate = (date: string | Date, format: string = 'YYYY-MM-DD'): string => {
  if (!date) return ''
  return dayjs(date).format(format)
}

export const formatDateTime = (date: string | Date): string => {
  return formatDate(date, 'YYYY-MM-DD HH:mm:ss')
}

export const formatRelativeTime = (date: string | Date): string => {
  if (!date) return ''
  return dayjs(date).fromNow()
}

export const isToday = (date: string | Date): boolean => {
  return dayjs(date).isSame(dayjs(), 'day')
}

export const isValidDate = (date: any): boolean => {
  return dayjs(date).isValid()
}