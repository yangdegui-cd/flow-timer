<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import PageHeader from '@/views/layer/PageHeader.vue'
import GitHubLogin from '@/components/GitHubLogin.vue'
import { getOAuthProviders, unbindOAuthProvider, type OAuthProvider } from '@/api/oauth-api'

const toast = useToast()
const confirm = useConfirm()

const loading = ref(false)
const providers = ref<OAuthProvider[]>([])

// 支持的OAuth提供商配置
const supportedProviders = [
  {
    key: 'github',
    name: 'GitHub',
    icon: 'pi pi-github',
    description: '绑定GitHub账号，支持代码仓库管理',
    color: '#24292e'
  },
  {
    key: 'wechat',
    name: '微信',
    icon: 'pi pi-weixin',
    description: '绑定微信账号，支持微信登录',
    color: '#07c160'
  }
]

// 检查提供商是否已绑定
const isProviderBound = (providerKey: string): boolean => {
  return providers.value.some(p => p.provider === providerKey)
}

// 获取绑定的提供商信息
const getBoundProvider = (providerKey: string): OAuthProvider | undefined => {
  return providers.value.find(p => p.provider === providerKey)
}

// 加载OAuth绑定信息
const loadOAuthProviders = async () => {
  loading.value = true
  try {
    providers.value = await getOAuthProviders()
  } catch (error: any) {
    console.error('Failed to load OAuth providers:', error)
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: '无法加载账号绑定信息',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

// 绑定账号
const bindAccount = (providerKey: string) => {
  if (providerKey === 'github') {
    // 设置绑定模式
    localStorage.setItem('oauth_mode', 'bind')

    // 跳转到GitHub授权
    const backendUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
    window.location.href = `${backendUrl}/auth/github`
  } else if (providerKey === 'wechat') {
    toast.add({
      severity: 'info',
      summary: '功能提示',
      detail: '微信绑定功能开发中，敬请期待',
      life: 3000
    })
  }
}

// 解绑账号
const unbindAccount = (providerKey: string) => {
  const provider = getBoundProvider(providerKey)
  if (!provider) return

  confirm.require({
    message: `确定要解绑 ${provider.provider_name} 账号吗？`,
    header: '解绑确认',
    icon: 'pi pi-exclamation-triangle',
    rejectLabel: '取消',
    acceptLabel: '解绑',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await unbindOAuthProvider(providerKey)

        toast.add({
          severity: 'success',
          summary: '解绑成功',
          detail: `${provider.provider_name} 账号已解绑`,
          life: 3000
        })

        // 重新加载绑定信息
        await loadOAuthProviders()
      } catch (error: any) {
        toast.add({
          severity: 'error',
          summary: '解绑失败',
          detail: error.message || '解绑操作失败',
          life: 3000
        })
      }
    }
  })
}

// 格式化连接时间
const formatConnectedTime = (dateString: string): string => {
  return new Date(dateString).toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  loadOAuthProviders()
})
</script>

<template>
  <div class="h-full flex flex-col bg-gray-50 w-full">
    <!-- 页面头部 -->
    <PageHeader
      title="账号绑定"
      description="管理第三方账号绑定，支持多种登录方式"
      icon="pi pi-link"
      icon-color="text-blue-600"
    >
      <template #actions>
        <Button
          icon="pi pi-refresh"
          severity="secondary"
          variant="outlined"
          size="small"
          :loading="loading"
          @click="loadOAuthProviders"
          v-tooltip.top="'刷新绑定信息'" />
      </template>
    </PageHeader>

    <!-- 主要内容 -->
    <div class="flex-1 p-6">
      <div class="max-w-4xl mx-auto">
        <!-- 账号绑定说明 -->
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div class="flex items-start gap-3">
            <i class="pi pi-info-circle text-blue-600 text-lg mt-0.5"></i>
            <div>
              <h3 class="font-semibold text-blue-900 mb-1">账号绑定说明</h3>
              <p class="text-sm text-blue-800">
                绑定第三方账号后，您可以使用多种方式登录系统。绑定的账号信息仅用于身份验证，不会获取您的私人数据。
              </p>
            </div>
          </div>
        </div>

        <!-- 支持的提供商列表 -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card
            v-for="provider in supportedProviders"
            :key="provider.key"
            class="provider-card"
          >
            <template #content>
              <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-12 h-12 rounded-lg flex items-center justify-center"
                      :style="{ backgroundColor: `${provider.color}15` }"
                    >
                      <!-- GitHub图标 -->
                      <svg
                        v-if="provider.key === 'github'"
                        width="24"
                        height="24"
                        viewBox="0 0 24 24"
                        :fill="provider.color"
                      >
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                      </svg>
                      <!-- 微信图标 -->
                      <i
                        v-else
                        :class="provider.icon"
                        class="text-xl"
                        :style="{ color: provider.color }"
                      ></i>
                    </div>

                    <div>
                      <h3 class="text-lg font-semibold text-gray-900">{{ provider.name }}</h3>
                      <p class="text-sm text-gray-600">{{ provider.description }}</p>
                    </div>
                  </div>

                  <!-- 绑定状态标识 -->
                  <div v-if="isProviderBound(provider.key)">
                    <Tag value="已绑定" severity="success" />
                  </div>
                </div>

                <!-- 绑定信息 -->
                <div v-if="isProviderBound(provider.key)" class="bg-gray-50 rounded-lg p-4 mb-4">
                  <div class="space-y-2">
                    <div class="flex items-center justify-between">
                      <span class="text-sm text-gray-600">绑定账号：</span>
                      <span class="text-sm font-medium text-gray-900">
                        {{ getBoundProvider(provider.key)?.display_info?.username ||
                           getBoundProvider(provider.key)?.display_info?.nickname ||
                           'N/A' }}
                      </span>
                    </div>
                    <div class="flex items-center justify-between">
                      <span class="text-sm text-gray-600">绑定时间：</span>
                      <span class="text-sm text-gray-900">
                        {{ formatConnectedTime(getBoundProvider(provider.key)!.connected_at) }}
                      </span>
                    </div>
                  </div>
                </div>

                <!-- 操作按钮 -->
                <div class="flex gap-3">
                  <Button
                    v-if="!isProviderBound(provider.key)"
                    :label="`绑定${provider.name}`"
                    :icon="provider.icon"
                    size="small"
                    class="flex-1"
                    @click="bindAccount(provider.key)"
                  />

                  <template v-else>
                    <Button
                      label="解绑账号"
                      icon="pi pi-times"
                      severity="danger"
                      variant="outlined"
                      size="small"
                      class="flex-1"
                      @click="unbindAccount(provider.key)"
                    />

                    <Button
                      v-if="getBoundProvider(provider.key)?.display_info?.profile_url"
                      icon="pi pi-external-link"
                      severity="secondary"
                      variant="outlined"
                      size="small"
                      v-tooltip.top="'查看账号'"
                      @click="window.open(getBoundProvider(provider.key)?.display_info?.profile_url, '_blank')"
                    />
                  </template>
                </div>
              </div>
            </template>
          </Card>
        </div>

        <!-- 安全提示 -->
        <div class="mt-8 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-yellow-600 text-lg mt-0.5"></i>
            <div>
              <h3 class="font-semibold text-yellow-900 mb-1">安全提示</h3>
              <ul class="text-sm text-yellow-800 space-y-1">
                <li>• 请确保在受信任的设备上进行账号绑定操作</li>
                <li>• 绑定的第三方账号应为您本人拥有和控制</li>
                <li>• 如发现异常登录，请及时解绑相关账号并修改密码</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.provider-card {
  transition: all 0.2s ease;
}

.provider-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
</style>
