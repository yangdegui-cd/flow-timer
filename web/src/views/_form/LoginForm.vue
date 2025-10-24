<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import oauthApi from '@/api/oauth-api'
import GitHubLogin from '@/components/GitHubLogin.vue'

// Emits
defineEmits<{
  'switch-to-register': []
}>()

// Stores & Router
const authStore = useAuthStore()
const router = useRouter()
const toast = useToast()

// Form data
const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const loading = ref(false)

// Form validation
const errors = ref({
  email: '',
  password: ''
})

const validateEmail = () => {
  if (!email.value) {
    errors.value.email = '请输入邮箱地址'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value)) {
    errors.value.email = '请输入有效的邮箱地址'
  } else {
    errors.value.email = ''
  }
}

const validatePassword = () => {
  if (!password.value) {
    errors.value.password = '请输入密码'
  } else if (password.value.length < 6) {
    errors.value.password = '密码至少6位'
  } else {
    errors.value.password = ''
  }
}

const isFormValid = computed(() => {
  return email.value && password.value && !errors.value.email && !errors.value.password
})

// Login handler
const handleLogin = async () => {
  validateEmail()
  validatePassword()

  if (!isFormValid.value) return

  loading.value = true

  try {
    const result = await authStore.login(email.value, password.value)

    if (result.success) {
      toast.add({
        severity: 'success',
        summary: '登录成功',
        detail: result.message,
        life: 3000
      })

      // 跳转到首页或之前的页面
      const redirect = router.currentRoute.value.query.redirect as string || '/'
      router.push(redirect)
    } else {
      toast.add({
        severity: 'error',
        summary: '登录失败',
        detail: result.message,
        life: 5000
      })
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '登录失败',
      detail: error.message || '网络错误，请稍后重试',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// OAuth handlers
const handleGithubLogin = () => {
  oauthApi.githubLogin()
}

const handleWechatLogin = () => {
  oauthApi.wechatLogin()
}
</script>
<template>
  <Card class="w-full max-w-md">
    <template #header>
      <div class="text-center px-8 pt-8">
        <h1 class="text-3xl font-bold text-surface-900 mb-2">欢迎登录</h1>
        <p class="text-surface-600">请使用您的账号登录系统</p>
      </div>
    </template>

    <template #content>
      <div class="px-8 pb-8">
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- 邮箱输入 -->
          <div>
            <FloatLabel variant="on">
              <InputText
                id="email"
                v-model="email"
                type="email"
                class="w-full"
                :invalid="errors.email"
                @blur="validateEmail"
              />
              <label for="email">邮箱地址</label>
            </FloatLabel>
            <small v-if="errors.email" class="text-red-500">{{ errors.email }}</small>
          </div>
          <!-- 密码输入 -->
          <div>
            <FloatLabel variant="on">
              <Password
                id="password"
                v-model="password"
                class="w-full"
                inputClass="w-full"
                :invalid="!!errors.password"
                :feedback="false"
                toggleMask
                @blur="validatePassword"
              />
              <label for="password">密码</label>
            </FloatLabel>
          </div>

          <!-- 记住我 -->
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <Checkbox id="remember" v-model="rememberMe" binary />
              <label for="remember" class="ml-2 text-sm text-surface-600 cursor-pointer">记住我</label>
            </div>
            <a href="#" class="text-sm text-primary-500 hover:text-primary-600 transition-colors">
              忘记密码？
            </a>
          </div>

          <!-- 登录按钮 -->
          <Button
            type="submit"
            label="登录"
            class="w-full"
            :loading="loading"
            :disabled="!isFormValid"
          />

          <!-- 分割线 -->
          <Divider align="center">
            <span class="text-surface-400 text-sm">或</span>
          </Divider>

          <!-- OAuth 登录 -->
          <div class="space-y-3">
            <GitHubLogin 
              mode="login"
              @click="handleGithubLogin"
              class="w-full"
            />

            <Button
              @click="handleWechatLogin"
              class="w-full"
              outlined
              icon="pi pi-comments"
              label="使用微信登录"
            />
          </div>

          <!-- 注册链接 -->
          <div class="text-center pt-4">
            <span class="text-surface-600 text-sm">还没有账号？</span>
            <a @click="$emit('switch-to-register')" class="text-primary-500 hover:text-primary-600 text-sm font-medium cursor-pointer ml-1">
              立即注册
            </a>
          </div>
        </form>
      </div>
    </template>
  </Card>
</template>

