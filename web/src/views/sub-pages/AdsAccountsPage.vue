<template>
  <div class="ads-accounts-page">
    <PageHeader
      title="广告账户管理"
      subtitle="管理项目的广告平台账户和授权"
      :breadcrumb="breadcrumb"
    />

    <div class="surface-card border-round shadow-1 p-4">
      <!-- 工具栏 -->
      <Toolbar class="mb-4">
        <template #start>
          <Button
            label="添加账户"
            icon="pi pi-plus"
            class="p-button-primary mr-2"
            @click="showAddDialog"
          />
          <Button
            label="刷新"
            icon="pi pi-refresh"
            class="p-button-outlined"
            @click="loadAccounts"
            :loading="loading"
          />
        </template>

        <template #end>
          <Dropdown
            v-model="selectedPlatform"
            :options="platformOptions"
            option-label="name"
            option-value="slug"
            placeholder="筛选平台"
            class="mr-2"
            @change="filterByPlatform"
          />
          <Button
            icon="pi pi-filter-slash"
            class="p-button-text"
            @click="clearFilter"
            v-tooltip="'清除筛选'"
          />
        </template>
      </Toolbar>

      <!-- 快速授权卡片 -->
      <div class="grid mb-4">
        <div class="col-12 md:col-3" v-for="platform in availablePlatforms" :key="platform.id">
          <Card class="text-center">
            <template #content>
              <div class="flex flex-column align-items-center gap-3">
                <div class="flex align-items-center gap-2">
                  <i :class="getPlatformIcon(platform.slug)" class="text-2xl"></i>
                  <span class="font-bold">{{ platform.name }}</span>
                </div>
                <small class="text-500">{{ getAccountCount(platform.slug) }} 个账户</small>
                <Button
                  :label="`授权${platform.name}`"
                  size="small"
                  class="p-button-outlined"
                  @click="authorizeWithPlatform(platform)"
                  :loading="authorizing && authorizingPlatform === platform.slug"
                />
              </div>
            </template>
          </Card>
        </div>
      </div>

      <!-- 账户列表 -->
      <DataTable
        :value="filteredAccounts"
        :loading="loading"
        paginator
        :rows="10"
        :rowsPerPageOptions="[10, 25, 50]"
        dataKey="id"
        :globalFilterFields="['name', 'account_id', 'ads_platform.name']"
        currentPageReportTemplate="显示第 {first} 到 {last} 条，共 {totalRecords} 条记录"
        paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
        responsiveLayout="scroll"
        stripedRows
      >
        <template #empty>
          <div class="text-center p-4">
            <i class="pi pi-info-circle text-4xl text-400 mb-3"></i>
            <p class="text-500">暂无广告账户数据</p>
            <Button
              label="添加第一个账户"
              icon="pi pi-plus"
              class="p-button-text"
              @click="showAddDialog"
            />
          </div>
        </template>

        <Column field="name" header="账户名称" sortable>
          <template #body="{ data }">
            <div class="flex align-items-center gap-2">
              <i :class="getPlatformIcon(data.ads_platform.slug)"></i>
              <div>
                <div class="font-medium">{{ data.name }}</div>
                <small class="text-500">ID: {{ data.account_id }}</small>
              </div>
            </div>
          </template>
        </Column>

        <Column field="ads_platform.name" header="平台" sortable>
          <template #body="{ data }">
            <Tag
              :value="data.ads_platform.name"
              :class="getPlatformClass(data.ads_platform.slug)"
            />
          </template>
        </Column>

        <Column field="account_status" header="账户状态" sortable>
          <template #body="{ data }">
            <Tag
              :value="getStatusLabel(data.account_status)"
              :severity="getStatusSeverity(data.account_status)"
            />
          </template>
        </Column>

        <Column field="sync_status" header="同步状态" sortable>
          <template #body="{ data }">
            <div class="flex align-items-center gap-2">
              <Tag
                :value="getSyncStatusLabel(data.sync_status)"
                :severity="getSyncStatusSeverity(data.sync_status)"
              />
              <Button
                v-if="data.sync_status !== 'pending'"
                icon="pi pi-sync"
                class="p-button-text p-button-sm"
                @click="syncAccount(data)"
                v-tooltip="'立即同步'"
              />
            </div>
          </template>
        </Column>

        <Column field="token_expires_at" header="令牌状态" sortable>
          <template #body="{ data }">
            <div v-if="data.token_expires_at">
              <Tag
                :value="data.token_expired ? '已过期' : '有效'"
                :severity="data.token_expired ? 'danger' : 'success'"
              />
              <div class="text-xs text-500 mt-1">
                {{ formatDate(data.token_expires_at) }}
              </div>
            </div>
            <Tag v-else value="无令牌" severity="warning" />
          </template>
        </Column>

        <Column field="last_sync_at" header="最后同步" sortable>
          <template #body="{ data }">
            <div v-if="data.last_sync_at" class="text-sm">
              {{ formatDate(data.last_sync_at) }}
            </div>
            <span v-else class="text-500">从未同步</span>
          </template>
        </Column>

        <Column header="操作" :exportable="false" style="width: 120px">
          <template #body="{ data }">
            <div class="flex gap-2">
              <Button
                icon="pi pi-pencil"
                class="p-button-text p-button-sm"
                @click="editAccount(data)"
                v-tooltip="'编辑'"
              />
              <Button
                icon="pi pi-refresh"
                class="p-button-text p-button-sm"
                @click="refreshToken(data)"
                v-tooltip="'刷新令牌'"
              />
              <Button
                :icon="data.active ? 'pi pi-eye-slash' : 'pi pi-eye'"
                class="p-button-text p-button-sm"
                @click="toggleAccount(data)"
                :v-tooltip="data.active ? '禁用' : '启用'"
              />
              <Button
                icon="pi pi-trash"
                class="p-button-text p-button-sm p-button-danger"
                @click="confirmDelete(data)"
                v-tooltip="'删除'"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 添加/编辑对话框 -->
    <AdsAccountDialog
      v-model:visible="dialogVisible"
      :ads-account="selectedAccount"
      :project-id="projectId"
      :platforms="availablePlatforms"
      @success="onDialogSuccess"
    />

    <!-- 删除确认对话框 -->
    <ConfirmDialog />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useConfirm } from 'primevue/useconfirm'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import Card from 'primevue/card'
import Tag from 'primevue/tag'
import Dropdown from 'primevue/dropdown'
import ConfirmDialog from 'primevue/confirmdialog'
import PageHeader from '../../components/PageHeader.vue'
import AdsAccountDialog from '../_dialogs/AdsAccountDialog.vue'
import { adsAccountApi } from '../../api/ads-account-api'
import type { AdsAccount, AdsPlatform } from '../../data/types/ads-account-types'

const route = useRoute()
const confirm = useConfirm()

const projectId = computed(() => Number(route.params.id))
const loading = ref(false)
const authorizing = ref(false)
const authorizingPlatform = ref('')
const dialogVisible = ref(false)
const selectedAccount = ref<AdsAccount | undefined>()
const selectedPlatform = ref('')

const accounts = ref<AdsAccount[]>([])
const availablePlatforms = ref<AdsPlatform[]>([])

const breadcrumb = computed(() => [
  { label: '首页', to: '/' },
  { label: '项目管理', to: '/projects' },
  { label: '广告账户', to: `/projects/${projectId.value}/ads-accounts` }
])

const platformOptions = computed(() => [
  { name: '全部平台', slug: '' },
  ...availablePlatforms.value.map(p => ({ name: p.name, slug: p.slug }))
])

const filteredAccounts = computed(() => {
  if (!selectedPlatform.value) return accounts.value
  return accounts.value.filter(account => account.ads_platform.slug === selectedPlatform.value)
})

onMounted(() => {
  loadAccounts()
  loadPlatforms()
})

const loadAccounts = async () => {
  try {
    loading.value = true
    const result = await adsAccountApi.getAdsAccounts(projectId.value)
    accounts.value = result.data || []
  } catch (error) {
    console.error('加载广告账户失败:', error)
  } finally {
    loading.value = false
  }
}

const loadPlatforms = async () => {
  // TODO: 实现获取可用平台列表的API
  availablePlatforms.value = [
    { id: 1, name: 'Facebook', slug: 'facebook', api_version: 'v18.0', base_url: '', oauth_url: '', scopes: [], auth_method: 'oauth2', description: '', active: true, created_at: '', updated_at: '' },
    { id: 2, name: 'Google Ads', slug: 'google', api_version: 'v14', base_url: '', oauth_url: '', scopes: [], auth_method: 'oauth2', description: '', active: true, created_at: '', updated_at: '' },
    { id: 3, name: 'Twitter Ads', slug: 'twitter', api_version: '12', base_url: '', oauth_url: '', scopes: [], auth_method: 'oauth2', description: '', active: true, created_at: '', updated_at: '' },
    { id: 4, name: 'TikTok for Business', slug: 'tiktok', api_version: 'v1.3', base_url: '', oauth_url: '', scopes: [], auth_method: 'oauth2', description: '', active: true, created_at: '', updated_at: '' }
  ]
}

const showAddDialog = () => {
  selectedAccount.value = undefined
  dialogVisible.value = true
}

const editAccount = (account: AdsAccount) => {
  selectedAccount.value = account
  dialogVisible.value = true
}

const authorizeWithPlatform = async (platform: AdsPlatform) => {
  if (platform.slug === 'facebook') {
    try {
      authorizing.value = true
      authorizingPlatform.value = platform.slug

      const result = await adsAccountApi.authorizeWithFacebook(projectId.value)
      const authUrl = result.data.auth_url

      // 在新窗口中打开授权页面
      const authWindow = window.open(authUrl, 'platform_auth', 'width=600,height=600')

      // 监听授权完成
      const checkClosed = setInterval(() => {
        if (authWindow?.closed) {
          clearInterval(checkClosed)
          loadAccounts() // 重新加载账户列表
        }
      }, 1000)

    } catch (error) {
      console.error(`${platform.name}授权失败:`, error)
    } finally {
      authorizing.value = false
      authorizingPlatform.value = ''
    }
  }
}

const syncAccount = async (account: AdsAccount) => {
  try {
    await adsAccountApi.syncAccount(account.id)
    loadAccounts()
  } catch (error) {
    console.error('同步账户失败:', error)
  }
}

const refreshToken = async (account: AdsAccount) => {
  try {
    await adsAccountApi.refreshToken(account.id)
    loadAccounts()
  } catch (error) {
    console.error('刷新令牌失败:', error)
  }
}

const toggleAccount = async (account: AdsAccount) => {
  try {
    await adsAccountApi.toggleAdsAccount(account.id, !account.active)
    loadAccounts()
  } catch (error) {
    console.error('切换账户状态失败:', error)
  }
}

const confirmDelete = (account: AdsAccount) => {
  confirm.require({
    message: `确定要删除广告账户 "${account.name}" 吗？此操作不可撤销。`,
    header: '删除确认',
    icon: 'pi pi-exclamation-triangle',
    accept: () => {
      deleteAccount(account)
    }
  })
}

const deleteAccount = async (account: AdsAccount) => {
  try {
    await adsAccountApi.deleteAdsAccount(account.id)
    loadAccounts()
  } catch (error) {
    console.error('删除广告账户失败:', error)
  }
}

const onDialogSuccess = () => {
  loadAccounts()
}

const filterByPlatform = () => {
  // 筛选逻辑已在计算属性中处理
}

const clearFilter = () => {
  selectedPlatform.value = ''
}

// 工具函数
const getPlatformIcon = (slug: string) => {
  const icons: Record<string, string> = {
    facebook: 'pi pi-facebook',
    google: 'pi pi-google',
    twitter: 'pi pi-twitter',
    tiktok: 'pi pi-video'
  }
  return icons[slug] || 'pi pi-globe'
}

const getPlatformClass = (slug: string) => {
  const classes: Record<string, string> = {
    facebook: 'p-tag-info',
    google: 'p-tag-success',
    twitter: 'p-tag-warning',
    tiktok: 'p-tag-danger'
  }
  return classes[slug] || ''
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    active: '活跃',
    suspended: '暂停',
    closed: '关闭'
  }
  return labels[status] || status
}

const getStatusSeverity = (status: string) => {
  const severities: Record<string, string> = {
    active: 'success',
    suspended: 'warning',
    closed: 'danger'
  }
  return severities[status] || 'info'
}

const getSyncStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    success: '成功',
    error: '失败',
    pending: '同步中'
  }
  return labels[status] || status
}

const getSyncStatusSeverity = (status: string) => {
  const severities: Record<string, string> = {
    success: 'success',
    error: 'danger',
    pending: 'warning'
  }
  return severities[status] || 'info'
}

const getAccountCount = (slug: string) => {
  return accounts.value.filter(account => account.ads_platform.slug === slug).length
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}
</script>