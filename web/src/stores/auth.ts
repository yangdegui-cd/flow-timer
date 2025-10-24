import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import authApi from '@/api/auth-api'
import type { User } from '@/data/types/auth'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('auth_token'))
  const loading = ref(false)

  // Getters
  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const hasRole = computed(() => (roleName: string) => {
    return user.value?.roles.some(role => role.name === roleName) || false
  })
  const hasPermission = computed(() => (permission: string) => {
    return user.value?.permissions.map(v => v.code).includes(permission) || false
  })
  const isAdmin = computed(() => hasRole.value('admin'))

  // Actions
  async function login(email: string, password: string) {
    try {
      loading.value = true
      const data = await authApi.login({ email, password })
      token.value = data.token
      user.value = data.user
      localStorage.setItem('auth_token', data.token)
      return { success: true }
    } catch (error: any) {
      return { success: false, message: error.msg || '登录失败' }
    } finally {
      loading.value = false
    }
  }

  async function register(email: string, password: string, name: string) {
    try {
      loading.value = true
      const data = await authApi.register({ email, password, name })
      token.value = data.token
      user.value = data.user
      localStorage.setItem('auth_token', data.token)
      return { success: true, message: data.message }
    } catch (error: any) {
      return { success: false, message: error.message || '注册失败' }
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      if (token.value) {
        await authApi.logout()
      }
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      token.value = null
      user.value = null
      localStorage.removeItem('auth_token')
    }
  }

  async function fetchUser() {
    if (!token.value) return false

    try {
      const data = await authApi.me()
      user.value = data.sys_user
      return true
    } catch (error) {
      await logout()
      return false
    }
  }

  async function updateProfile(data: { name: string; avatar_url?: string }) {
    try {
      const response = await authApi.updateProfile(data)
      user.value = response.user
      return { success: true, message: response.message }
    } catch (error: any) {
      return { success: false, message: error.msg || '更新失败' }
    }
  }

  async function changePassword(currentPassword: string, newPassword: string) {
    try {
      await authApi.changePassword({
        current_password: currentPassword,
        new_password: newPassword
      })
      return { success: true }
    } catch (error: any) {
      return { success: false, message: error.message || '密码修改失败' }
    }
  }

  // 初始化时检查用户状态
  async function init() {
    if (token.value) {
      await fetchUser()
    }
  }

  return {
    // State
    user,
    token,
    loading,

    // Getters
    isAuthenticated,
    hasRole,
    hasPermission,
    isAdmin,

    // Actions
    login,
    register,
    logout,
    fetchUser,
    updateProfile,
    changePassword,
    init
  }
})

// 在请求拦截器中自动添加token
// 这部分将在request.ts中处理
