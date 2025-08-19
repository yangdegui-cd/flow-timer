<template>
  <sub-page title="个人资料" description="管理您的账户信息和安全设置" icon="pi pi-user" icon-color="text-blue-600">
    <div class="profile-page w-full h-full overflow-auto">
      <div class="max-w-4xl mx-auto">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 h-full overflow-hidden">
          <!-- 左侧：基本信息卡片 -->
          <div class="lg:col-span-1">
            <Card>
              <template #header>
                <div class="p-6 pb-0 text-center">
                  <Avatar
                      :label="user?.avatar_url ? undefined : user?.name.charAt(0)"
                      :image="user?.avatar_url"
                      shape="circle"
                      size="xlarge"
                      class="bg-primary-100 text-primary-600 mb-4"
                  />
                  <h3 class="text-xl font-semibold text-surface-900">{{ user?.name }}</h3>
                  <p class="text-surface-600">{{ user?.email }}</p>
                  <Tag
                      :value="getStatusLabel(user?.status)"
                      :severity="getStatusSeverity(user?.status)"
                      class="mt-2"
                  />
                </div>
              </template>

              <template #content>
                <div class="space-y-4">
                  <!-- 角色信息 -->
                  <div>
                    <div class="text-sm font-medium text-surface-700 mb-2">角色</div>
                    <div class="flex flex-wrap gap-2">
                      <Tag
                          v-for="role in user?.roles"
                          :key="role.name"
                          :value="role.display_name"
                          :severity="getRoleSeverity(role.name)"
                          size="small"
                      />
                    </div>
                  </div>

                  <!-- 账户信息 -->
                  <div class="space-y-2 text-sm">
                    <div>
                      <span class="text-surface-500">注册时间:</span>
                      <div class="font-medium">{{ formatDateTime(user?.created_at) }}</div>
                    </div>
                    <div>
                      <span class="text-surface-500">最后登录:</span>
                      <div v-if="user?.last_login_at" class="font-medium">
                        {{ formatDateTime(user?.last_login_at) }}
                      </div>
                      <div v-else class="text-surface-400">从未登录</div>
                    </div>
                  </div>
                </div>
              </template>
            </Card>
          </div>

          <!-- 右侧：详细信息和设置 -->
          <div class="lg:col-span-2 space-y-6 h-full overflow-auto">
            <!-- 基本信息编辑 -->
            <Card>
              <template #header>
                <div class="p-6 pb-0">
                  <h3 class="text-lg font-semibold text-surface-900">基本信息</h3>
                  <p class="text-surface-600 text-sm mt-1">更新您的个人基本信息</p>
                </div>
              </template>

              <template #content>
                <form @submit.prevent="updateProfile" class="space-y-4">
                  <div>
                    <FloatLabel variant="on">
                      <InputText
                          id="profileName"
                          v-model="profileForm.name"
                          class="w-full"
                          :class="{ 'p-invalid': profileErrors.name }"
                          required
                      />
                      <label for="profileName">姓名*</label>
                    </FloatLabel>
                    <small v-if="profileErrors.name" class="p-error">{{ profileErrors.name }}</small>
                  </div>

                  <div class="flex justify-end">
                    <Button
                        label="保存更改"
                        @click="updateProfile"
                        :loading="profileLoading"
                        size="small"
                    />
                  </div>
                </form>
              </template>
            </Card>

            <!-- 密码修改 -->
            <Card>
              <template #header>
                <div class="p-6 pb-0">
                  <h3 class="text-lg font-semibold text-surface-900">修改密码</h3>
                  <p class="text-surface-600 text-sm mt-1">定期更换密码以保证账户安全</p>
                </div>
              </template>

              <template #content>
                <form @submit.prevent="changePassword" class="space-y-4">
                  <div>
                    <FloatLabel variant="on">
                      <Password
                          id="currentPassword"
                          v-model="passwordForm.current_password"
                          class="w-full"
                          input-class="w-full"
                          :class="{ 'p-invalid': passwordErrors.current_password }"
                          :feedback="false"
                          toggleMask
                          required
                      />
                      <label for="currentPassword">当前密码*</label>
                    </FloatLabel>
                    <small v-if="passwordErrors.current_password" class="p-error">{{
                        passwordErrors.current_password
                      }}</small>
                  </div>

                  <div>
                    <FloatLabel variant="on">
                      <Password
                          id="newPassword"
                          v-model="passwordForm.new_password"
                          class="w-full"
                          input-class="w-full"
                          :class="{ 'p-invalid': passwordErrors.new_password }"
                          promptLabel="请输入密码"
                          weakLabel="弱"
                          mediumLabel="中"
                          strongLabel="强"
                          toggleMask
                          required
                      />
                      <label for="newPassword">新密码*</label>
                    </FloatLabel>
                    <small v-if="passwordErrors.new_password" class="p-error">{{ passwordErrors.new_password }}</small>
                  </div>

                  <div>
                    <FloatLabel variant="on">
                      <Password
                          id="confirmPassword"
                          v-model="passwordForm.confirm_password"
                          class="w-full"
                          input-class="w-full"
                          :class="{ 'p-invalid': passwordErrors.confirm_password }"
                          :feedback="false"
                          toggleMask
                          required
                      />
                      <label for="confirmPassword">确认新密码*</label>
                    </FloatLabel>
                    <small v-if="passwordErrors.confirm_password" class="p-error">{{
                        passwordErrors.confirm_password
                      }}</small>
                  </div>

                  <div class="flex justify-end">
                    <Button
                        label="修改密码"
                        @click="changePassword"
                        :loading="passwordLoading"
                        size="small"
                    />
                  </div>
                </form>
              </template>
            </Card>

            <!-- OAuth关联账号 -->
            <Card>
              <template #header>
                <div class="p-6 pb-0">
                  <h3 class="text-lg font-semibold text-surface-900">关联账号</h3>
                  <p class="text-surface-600 text-sm mt-1">管理第三方账号关联</p>
                </div>
              </template>

              <template #content>
                <div class="space-y-4">
                  <!-- GitHub -->
                  <div class="flex items-center justify-between p-4 border border-surface-200 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <i class="pi pi-github text-xl text-surface-700"></i>
                      <div>
                        <div class="font-medium">GitHub</div>
                        <div v-if="githubAccount" class="text-sm text-surface-500">
                          已连接 - {{ formatDateTime(githubAccount.connected_at) }}
                        </div>
                        <div v-else class="text-sm text-surface-500">未连接</div>
                      </div>
                    </div>
                    <Button
                        v-if="githubAccount"
                        label="解除绑定"
                        @click="unbindOAuth('github')"
                        size="small"
                        severity="danger"
                        outlined
                    />
                    <Button
                        v-else
                        label="立即连接"
                        @click="bindOAuth('github')"
                        size="small"
                        outlined
                    />
                  </div>

                  <!-- 微信 -->
                  <div class="flex items-center justify-between p-4 border border-surface-200 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <i class="pi pi-comments text-xl text-green-600"></i>
                      <div>
                        <div class="font-medium">微信</div>
                        <div v-if="wechatAccount" class="text-sm text-surface-500">
                          已连接 - {{ formatDateTime(wechatAccount.connected_at) }}
                        </div>
                        <div v-else class="text-sm text-surface-500">未连接</div>
                      </div>
                    </div>
                    <Button
                        v-if="wechatAccount"
                        label="解除绑定"
                        @click="unbindOAuth('wechat')"
                        size="small"
                        severity="danger"
                        outlined
                    />
                    <Button
                        v-else
                        label="立即连接"
                        @click="bindOAuth('wechat')"
                        size="small"
                        outlined
                    />
                  </div>
                </div>
              </template>
            </Card>
          </div>
        </div>
      </div>
    </div>
  </sub-page>

</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import AuthApi from '@/api/auth-api'

import Card from 'primevue/card'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'
import PageHeader from "@/views/layer/PageHeader.vue";
import SubPage from "@/views/layer/SubPage.vue";

// Stores & Services
const authStore = useAuthStore()
const toast = useToast()

// Data
const profileLoading = ref(false)
const passwordLoading = ref(false)

const profileForm = reactive({
  name: ''
})

const profileErrors = ref<Record<string, string>>({})

const passwordForm = reactive({
  current_password: '',
  new_password: '',
  confirm_password: ''
})

const passwordErrors = ref<Record<string, string>>({})

// Computed
const user = computed(() => authStore.user)

const githubAccount = computed(() => {
  return user.value?.oauth_providers.find(oauth => oauth.provider === 'github')
})

const wechatAccount = computed(() => {
  return user.value?.oauth_providers.find(oauth => oauth.provider === 'wechat')
})

// Methods
const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'active':
      return 'success'
    case 'inactive':
      return 'warning'
    case 'suspended':
      return 'danger'
    default:
      return 'secondary'
  }
}

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'active':
      return '活跃'
    case 'inactive':
      return '非活跃'
    case 'suspended':
      return '已禁用'
    default:
      return status
  }
}

const getRoleSeverity = (roleName: string) => {
  switch (roleName) {
    case 'admin':
      return 'danger'
    case 'developer':
      return 'info'
    case 'operator':
      return 'warning'
    default:
      return 'secondary'
  }
}

const formatDateTime = (dateString?: string) => {
  return dateString ? new Date(dateString).toLocaleString('zh-CN') : ''
}

const validateProfileForm = () => {
  profileErrors.value = {}

  if (!profileForm.name.trim()) {
    profileErrors.value.name = '姓名不能为空'
  }

  return Object.keys(profileErrors.value).length === 0
}

const validatePasswordForm = () => {
  passwordErrors.value = {}

  if (!passwordForm.current_password) {
    passwordErrors.value.current_password = '请输入当前密码'
  }

  if (!passwordForm.new_password) {
    passwordErrors.value.new_password = '请输入新密码'
  } else if (passwordForm.new_password.length < 6) {
    passwordErrors.value.new_password = '密码长度至少6位'
  }

  if (!passwordForm.confirm_password) {
    passwordErrors.value.confirm_password = '请确认新密码'
  } else if (passwordForm.new_password !== passwordForm.confirm_password) {
    passwordErrors.value.confirm_password = '两次输入的密码不一致'
  }

  return Object.keys(passwordErrors.value).length === 0
}

const updateProfile = async () => {
  if (!validateProfileForm()) return

  profileLoading.value = true

  try {
    await authStore.updateProfile(profileForm)

    toast.add({
      severity: 'success',
      summary: '更新成功',
      detail: '个人信息已更新',
      life: 3000
    })
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '更新失败',
      detail: error.message || '更新个人信息失败',
      life: 5000
    })
  } finally {
    profileLoading.value = false
  }
}

const changePassword = async () => {
  if (!validatePasswordForm()) return

  passwordLoading.value = true

  try {
    const response = await AuthApi.changePassword(passwordForm)

    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '密码修改成功',
        detail: response.data.message,
        life: 3000
      })

      // 重置表单
      Object.assign(passwordForm, {
        current_password: '',
        new_password: '',
        confirm_password: ''
      })
      passwordErrors.value = {}
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '密码修改失败',
      detail: error.message || '修改密码失败',
      life: 5000
    })
  } finally {
    passwordLoading.value = false
  }
}

const bindOAuth = (provider: string) => {
  // 构造OAuth授权URL
  const baseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
  const authUrl = `${baseUrl}/auth/oauth/${provider}`

  // 在新窗口中打开授权页面
  window.open(authUrl, '_blank', 'width=600,height=600')

  // 监听授权完成事件
  const checkAuth = setInterval(() => {
    try {
      // 检查用户是否完成授权（可以通过轮询用户信息或者其他方式）
      authStore.fetchUser().then(() => {
        clearInterval(checkAuth)
        toast.add({
          severity: 'success',
          summary: '账号关联成功',
          detail: `${provider === 'github' ? 'GitHub' : '微信'}账号已成功关联`,
          life: 3000
        })
      })
    } catch (error) {
      // 继续检查
    }
  }, 2000)

  // 30秒后停止检查
  setTimeout(() => {
    clearInterval(checkAuth)
  }, 30000)
}

const unbindOAuth = async (provider: string) => {
  try {
    const response = await AuthApi.unbindOAuth(provider)

    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '解除绑定成功',
        detail: response.data.message,
        life: 3000
      })

      // 刷新用户信息
      await authStore.fetchUser()
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '解除绑定失败',
      detail: error.message || '解除账号绑定失败',
      life: 5000
    })
  }
}

// Lifecycle
onMounted(() => {
  if (user.value) {
    profileForm.name = user.value.name
  }
})
</script>

<style scoped>
.profile-page {
  padding: 2rem;
  max-width: 100%;
}
</style>
