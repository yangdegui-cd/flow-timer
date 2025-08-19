import { createConsumer } from '@rails/actioncable'
import { ref, reactive } from 'vue'

interface ActionCableState {
  connected: boolean
  connecting: boolean
  error: string | null
  lastConnectedAt: Date | null
}

class ActionCableService {
  private consumer: any = null
  private subscriptions = new Map<string, any>()

  public state = reactive<ActionCableState>({
    connected: false,
    connecting: false,
    error: null,
    lastConnectedAt: null
  })

  /**
   * 初始化ActionCable连接
   */
  public initialize() {
    if (this.consumer) {
      return
    }

    this.state.connecting = true
    this.state.error = null

    try {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
      const host = window.location.hostname
      const port = window.location.hostname === 'localhost' ? '3000' : window.location.port
      const cableUrl = `${protocol}//${host}:${port}/cable`

      console.log('初始化ActionCable连接:', cableUrl)

      this.consumer = createConsumer(cableUrl)

      // ActionCable consumer 没有全局的连接事件监听器
      // 连接状态通过各个subscription的回调来管理
      console.log('ActionCable consumer 已创建:', cableUrl)

      // 重置连接状态
      this.state.connecting = false

    } catch (error) {
      console.error('ActionCable初始化失败:', error)
      this.state.connecting = false
      this.state.error = error instanceof Error ? error.message : '初始化失败'
    }
  }

  /**
   * 订阅频道
   * @param channelName 频道名称
   * @param params 频道参数
   * @param callbacks 回调函数
   */
  public subscribe(channelName: string, params: any = {}, callbacks: any = {}) {
    if (!this.consumer) {
      this.initialize()
    }

    const subscriptionKey = `${channelName}:${JSON.stringify(params)}`

    if (this.subscriptions.has(subscriptionKey)) {
      console.log(`频道 ${channelName} 已存在订阅`)
      return this.subscriptions.get(subscriptionKey)
    }

    console.log(`订阅频道: ${channelName}`, params)

    const self = this // 保存对服务实例的引用

    const subscription = this.consumer.subscriptions.create(
      { channel: channelName, ...params },
      {
        connected() {
          console.log(`频道 ${channelName} 连接成功`)
          // 更新全局连接状态
          self.state.connected = true
          self.state.connecting = false
          self.state.error = null
          self.state.lastConnectedAt = new Date()
          callbacks.connected?.()
        },

        disconnected() {
          console.log(`频道 ${channelName} 断开连接`)
          // 更新全局连接状态
          self.state.connected = false
          self.state.connecting = false
          callbacks.disconnected?.()
        },

        rejected() {
          console.log(`频道 ${channelName} 连接被拒绝`)
          // 更新全局连接状态
          self.state.connected = false
          self.state.connecting = false
          self.state.error = '连接被服务器拒绝'
          callbacks.rejected?.()
        },

        received(data: any) {
          callbacks.received?.(data)
        }
      }
    )

    this.subscriptions.set(subscriptionKey, subscription)
    return subscription
  }

  /**
   * 取消订阅频道
   * @param channelName 频道名称
   * @param params 频道参数
   */
  public unsubscribe(channelName: string, params: any = {}) {
    const subscriptionKey = `${channelName}:${JSON.stringify(params)}`
    const subscription = this.subscriptions.get(subscriptionKey)

    if (subscription) {
      console.log(`取消订阅频道: ${channelName}`)
      subscription.unsubscribe()
      this.subscriptions.delete(subscriptionKey)
    }
  }

  /**
   * 发送消息到频道
   * @param channelName 频道名称
   * @param action 动作名称
   * @param data 数据
   * @param params 频道参数
   */
  public perform(channelName: string, action: string, data: any = {}, params: any = {}) {
    const subscriptionKey = `${channelName}:${JSON.stringify(params)}`
    const subscription = this.subscriptions.get(subscriptionKey)

    if (subscription) {
      subscription.perform(action, data)
    } else {
      console.warn(`频道 ${channelName} 未找到订阅`)
    }
  }

  /**
   * 断开所有连接
   */
  public disconnect() {
    if (this.consumer) {
      console.log('断开所有ActionCable连接')

      // 取消所有订阅
      this.subscriptions.forEach((subscription, key) => {
        subscription.unsubscribe()
      })
      this.subscriptions.clear()

      // 断开consumer
      this.consumer.disconnect()
      this.consumer = null

      this.state.connected = false
      this.state.connecting = false
      this.state.error = null
    }
  }

  /**
   * 重新连接
   */
  public reconnect() {
    this.disconnect()
    this.initialize()
  }

  /**
   * 获取连接状态
   */
  public getConnectionState() {
    return {
      connected: this.state.connected,
      connecting: this.state.connecting,
      error: this.state.error,
      lastConnectedAt: this.state.lastConnectedAt
    }
  }

  /**
   * 检查是否已连接
   */
  public isConnected() {
    return this.state.connected
  }

  /**
   * 获取所有活跃订阅
   */
  public getActiveSubscriptions() {
    return Array.from(this.subscriptions.keys())
  }
}

// 创建全局单例
export const actionCableService = new ActionCableService()

// 导出类型
export type { ActionCableState }
export default ActionCableService
