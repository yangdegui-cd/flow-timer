<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'

const route = useRoute()
const router = useRouter()
const toast = useToast()

const errorMessage = ref('')

const errorMessages: Record<string, string> = {
  'account_disabled': '账户已被禁用，请联系管理员',
  'authentication_failed': 'OAuth认证失败，请重试',
  'access_denied': '用户拒绝了授权请求',
  'invalid_request': '无效的OAuth请求',
  'server_error': '服务器内部错误，请稍后重试'
}

onMounted(() => {
  const error = route.query.error as string
  errorMessage.value = errorMessages[error] || 'OAuth认证失败，请重试'
  
  toast.add({
    severity: 'error',
    summary: 'OAuth认证失败',
    detail: errorMessage.value,
    life: 5000
  })
  
  // 5秒后自动跳转到登录页面
  setTimeout(() => {
    router.push('/auth/login')
  }, 5000)
})

const goToLogin = () => {
  router.push('/auth/login')
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50">
    <div class="max-w-md w-full mx-4">
      <div class="bg-white rounded-lg shadow-md p-8 text-center">
        <div class="space-y-4">
          <!-- 错误图标 -->
          <div class="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
            <i class="pi pi-times text-red-600 text-2xl"></i>
          </div>
          
          <!-- 错误标题 -->
          <h3 class="text-xl font-semibold text-gray-900">OAuth认证失败</h3>
          
          <!-- 错误消息 -->
          <p class="text-sm text-gray-600">{{ errorMessage }}</p>
          
          <!-- 操作按钮 -->
          <div class="space-y-3 pt-4">
            <Button
              label="重新登录"
              icon="pi pi-sign-in"
              class="w-full"
              @click="goToLogin"
            />
          </div>
          
          <!-- 自动跳转提示 -->
          <p class="text-xs text-gray-400">5秒后将自动跳转到登录页面</p>
        </div>
      </div>
    </div>
  </div>
</template>