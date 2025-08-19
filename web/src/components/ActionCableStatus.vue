<template>
  <div class="flex items-center gap-2">
    <i :class="`pi ${statusInfo.icon} ${statusInfo.color} text-sm`"></i>
    <div class="text-sm">
      <div class="text-gray-700 font-medium">{{ statusInfo.label }}</div>
      <div class="text-gray-500 text-xs">{{ statusInfo.description }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { actionCableService } from '@/services/actioncable'

const statusInfo = computed(() => {
  const state = actionCableService.getConnectionState()
  
  if (!state.connected) {
    if (state.connecting) {
      return {
        label: 'ActionCable连接中...',
        icon: 'pi-circle',
        color: 'text-yellow-500 animate-pulse',
        description: '正在建立连接'
      }
    } else if (state.error) {
      return {
        label: 'ActionCable连接错误',
        icon: 'pi-circle',
        color: 'text-red-500',
        description: state.error
      }
    } else {
      return {
        label: 'ActionCable已断开',
        icon: 'pi-circle',
        color: 'text-gray-500',
        description: '未连接到服务器'
      }
    }
  }
  
  return {
    label: 'ActionCable已连接',
    icon: 'pi-circle',
    color: 'text-green-500',
    description: `连接时间: ${state.lastConnectedAt?.toLocaleTimeString() || '未知'}`
  }
})
</script>