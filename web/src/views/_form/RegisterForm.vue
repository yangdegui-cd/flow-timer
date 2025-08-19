<template>
  <Card class="w-full max-w-md">
    <template #header>
      <div class="text-center px-8 pt-8">
        <h1 class="text-3xl font-bold text-surface-900 mb-2">创建账号</h1>
        <p class="text-surface-600">注册新账号开始使用系统</p>
      </div>
    </template>

    <template #content>
      <div class="px-8 pb-2">
        <form @submit.prevent="handleRegister" class="space-y-6">
          <!-- 姓名输入 -->
          <div>
            <FloatLabel variant="on">
              <InputText
                id="name"
                v-model="name"
                class="w-full"
                :invalid="errors.name"
                @blur="validateName"
              />
              <label for="name">姓名</label>
            </FloatLabel>
            <small v-if="errors.name" class="text-red-500">{{ errors.name }}</small>
          </div>

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
                :invalid="errors.password"
                input-class="w-full"
                toggleMask
                :feedback="true"
                @blur="validatePassword"
              />
              <label for="password">密码</label>
            </FloatLabel>
            <small v-if="errors.password" class="text-red-500">{{ errors.password }}</small>
            <div v-else class="text-sm text-surface-500 mt-1">
              密码至少6位，包含字母和数字
            </div>
          </div>

          <!-- 确认密码 -->
          <div>
            <FloatLabel variant="on">
              <Password
                id="confirmPassword"
                v-model="confirmPassword"
                class="w-full"
                input-class="w-full"
                :invalid="errors.confirmPassword"
                :feedback="false"
                toggleMask
                @blur="validateConfirmPassword"
              />
              <label for="confirmPassword">确认密码</label>
            </FloatLabel>
            <small v-if="errors.confirmPassword" class="text-red-500">{{ errors.confirmPassword }}</small>
          </div>

          <!-- 服务条款 -->
          <div class="flex items-start space-x-3">
            <Checkbox
              id="agreeTerms"
              v-model="agreeTerms"
              binary
              class="mt-1"
            />
            <label for="agreeTerms" class="text-sm text-surface-600 cursor-pointer leading-relaxed">
              我已阅读并同意
              <a href="#" class="text-primary-500 hover:text-primary-600 underline">用户协议</a>
              和
              <a href="#" class="text-primary-500 hover:text-primary-600 underline">隐私政策</a>
            </label>
          </div>
          <small v-if="errors.agreeTerms" class="text-red-500 -mt-4 block">{{ errors.agreeTerms }}</small>

          <!-- 注册按钮 -->
          <Button
            type="submit"
            label="创建账号"
            class="w-full"
            :loading="loading"
            :disabled="!isFormValid"
          />

          <!-- 分割线 -->
          <Divider align="center">
            <span class="text-surface-400 text-sm">或</span>
          </Divider>

          <!-- OAuth 注册 -->
          <div class="space-y-3">
            <Button
              @click="handleGithubLogin"
              class="w-full"
              outlined
              icon="pi pi-github"
              label="使用 GitHub 注册"
            />

            <Button
              @click="handleWechatLogin"
              class="w-full"
              outlined
              icon="pi pi-comments"
              label="使用微信注册"
            />
          </div>

          <!-- 登录链接 -->
          <div class="text-center pt-4">
            <span class="text-surface-600 text-sm">已有账号？</span>
            <a @click="$emit('switch-to-login')" class="text-primary-500 hover:text-primary-600 text-sm font-medium cursor-pointer ml-1">
              立即登录
            </a>
          </div>
        </form>
      </div>
    </template>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import AuthApi from '@/api/auth-api'

import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'
import Checkbox from 'primevue/checkbox'
import Divider from 'primevue/divider'

// Emits
defineEmits<{
  'switch-to-login': []
}>()

// Stores & Router
const authStore = useAuthStore()
const router = useRouter()
const toast = useToast()

// Form data
const name = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const agreeTerms = ref(false)
const loading = ref(false)

// Form validation
const errors = ref({
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
  agreeTerms: ''
})

const validateName = () => {
  if (!name.value.trim()) {
    errors.value.name = '请输入姓名'
  } else if (name.value.trim().length < 2) {
    errors.value.name = '姓名至少2个字符'
  } else {
    errors.value.name = ''
  }
}

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
  } else if (!/(?=.*[a-zA-Z])(?=.*[0-9])/.test(password.value)) {
    errors.value.password = '密码必须包含字母和数字'
  } else {
    errors.value.password = ''
  }

  // 重新验证确认密码
  if (confirmPassword.value) {
    validateConfirmPassword()
  }
}

const validateConfirmPassword = () => {
  if (!confirmPassword.value) {
    errors.value.confirmPassword = '请确认密码'
  } else if (password.value !== confirmPassword.value) {
    errors.value.confirmPassword = '两次输入的密码不一致'
  } else {
    errors.value.confirmPassword = ''
  }
}

const validateAgreeTerms = () => {
  if (!agreeTerms.value) {
    errors.value.agreeTerms = '请阅读并同意用户协议和隐私政策'
  } else {
    errors.value.agreeTerms = ''
  }
}

const isFormValid = computed(() => {
  return (
    name.value.trim() &&
    email.value &&
    password.value &&
    confirmPassword.value &&
    agreeTerms.value &&
    !errors.value.name &&
    !errors.value.email &&
    !errors.value.password &&
    !errors.value.confirmPassword &&
    !errors.value.agreeTerms
  )
})

// Register handler
const handleRegister = async () => {
  validateName()
  validateEmail()
  validatePassword()
  validateConfirmPassword()
  validateAgreeTerms()

  if (!isFormValid.value) return

  loading.value = true

  try {
    const result = await authStore.register(email.value, password.value, name.value.trim())

    if (result.success) {
      toast.add({
        severity: 'success',
        summary: '注册成功',
        detail: result.message,
        life: 3000
      })

      // 跳转到首页
      router.push('/')
    } else {
      toast.add({
        severity: 'error',
        summary: '注册失败',
        detail: result.message,
        life: 5000
      })
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '注册失败',
      detail: error.message || '网络错误，请稍后重试',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// OAuth handlers
const handleGithubLogin = () => {
  AuthApi.githubLogin()
}

const handleWechatLogin = () => {
  AuthApi.wechatLogin()
}
</script>
