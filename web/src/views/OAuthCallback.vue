<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { handleOAuthCallback } from '@/api/oauth-api'

const route = useRoute()
const router = useRouter()
const toast = useToast()

const loading = ref(true)
const error = ref<string | null>(null)

onMounted(async () => {
  try {
    const provider = route.params.provider as string
    
    if (!provider) {
      throw new Error('缺少OAuth提供商参数')
    }
    
    // 获取URL参数
    const urlParams = new URLSearchParams(window.location.search)
    
    // 处理OAuth回调
    await handleOAuthCallback(provider, urlParams)
    
    // 绑定模式：显示成功消息并跳转回设置页面
    const mode = localStorage.getItem('oauth_mode') || 'login'
    
    if (mode === 'bind') {
      toast.add({
        severity: 'success',
        summary: '绑定成功',
        detail: `${provider} 账号绑定成功`,
        life: 3000
      })
      
      // 跳转回设置页面
      router.push('/settings/account')
    } else {
      // 登录模式：由后端处理，这里不应该到达
      console.log('Login mode should be handled by backend')
    }
    
  } catch (err: any) {
    console.error('OAuth callback error:', err)
    error.value = err.message || 'OAuth认证失败'
    
    toast.add({
      severity: 'error',
      summary: 'OAuth认证失败',
      detail: error.value,
      life: 5000
    })
    
    // 3秒后跳转到登录页面
    setTimeout(() => {
      router.push('/login')
    }, 3000)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50">
    <div class="max-w-md w-full mx-4">
      <div class="bg-white rounded-lg shadow-md p-8 text-center">
        <!-- 加载状态 -->
        <div v-if="loading" class="space-y-4">
          <div class="mx-auto w-12 h-12 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin"></div>
          <h3 class="text-lg font-medium text-gray-900">正在处理OAuth认证...</h3>
          <p class="text-sm text-gray-600">请稍候，正在验证您的账号信息</p>
        </div>
        
        <!-- 错误状态 -->
        <div v-else-if="error" class="space-y-4">
          <div class="mx-auto w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
            <i class="pi pi-times text-red-600 text-xl"></i>
          </div>
          <h3 class="text-lg font-medium text-gray-900">认证失败</h3>
          <p class="text-sm text-red-600">{{ error }}</p>
          <p class="text-xs text-gray-500">页面将在3秒后自动跳转到登录页面</p>
        </div>
        
        <!-- 成功状态 -->
        <div v-else class="space-y-4">
          <div class="mx-auto w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
            <i class="pi pi-check text-green-600 text-xl"></i>
          </div>
          <h3 class="text-lg font-medium text-gray-900">认证成功</h3>
          <p class="text-sm text-gray-600">正在跳转...</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>