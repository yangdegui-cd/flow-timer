<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const authStore = useAuthStore()

const loading = ref(true)

onMounted(async () => {
  try {
    const token = route.query.token as string
    const provider = route.query.provider as string
    
    if (!token) {
      throw new Error('未获取到认证token')
    }
    
    // 保存token并初始化用户信息
    localStorage.setItem('auth_token', token)
    await authStore.init()
    
    toast.add({
      severity: 'success',
      summary: 'OAuth登录成功',
      detail: `使用 ${provider} 账号登录成功`,
      life: 3000
    })
    
    // 跳转到首页
    router.push('/')
    
  } catch (error: any) {
    console.error('OAuth success handling error:', error)
    
    toast.add({
      severity: 'error',
      summary: 'OAuth登录失败',
      detail: error.message || 'OAuth认证处理失败',
      life: 5000
    })
    
    // 跳转到登录页面
    setTimeout(() => {
      router.push('/auth/login')
    }, 2000)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50">
    <div class="max-w-md w-full mx-4">
      <div class="bg-white rounded-lg shadow-md p-8 text-center">
        <div v-if="loading" class="space-y-4">
          <div class="mx-auto w-12 h-12 border-4 border-green-200 border-t-green-600 rounded-full animate-spin"></div>
          <h3 class="text-lg font-medium text-gray-900">OAuth登录成功</h3>
          <p class="text-sm text-gray-600">正在跳转到系统首页...</p>
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