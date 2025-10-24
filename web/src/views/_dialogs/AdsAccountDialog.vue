<template>
  <Dialog
    v-model:visible="visible"
    :header="isEditing ? '编辑广告账户' : '添加广告账户'"
    :modal="true"
    :style="{ width: '50vw' }"
    :closable="false"
  >
    <div class="flex flex-column gap-3">
      <!-- 基本信息 -->
      <div class="field">
        <label for="name" class="block text-900 font-medium mb-2">账户名称 *</label>
        <InputText
          id="name"
          v-model="form.name"
          class="w-full"
          placeholder="请输入账户名称"
          :class="{ 'p-invalid': errors.name }"
        />
        <small v-if="errors.name" class="p-error">{{ errors.name }}</small>
      </div>

      <div class="field">
        <label for="platform" class="block text-900 font-medium mb-2">广告平台 *</label>
        <Dropdown
          id="platform"
          v-model="form.ads_platform_id"
          :options="platforms"
          option-label="name"
          option-value="id"
          placeholder="请选择广告平台"
          class="w-full"
          :class="{ 'p-invalid': errors.ads_platform_id }"
        />
        <small v-if="errors.ads_platform_id" class="p-error">{{ errors.ads_platform_id }}</small>
      </div>

      <div class="field">
        <label for="account_id" class="block text-900 font-medium mb-2">平台账户ID *</label>
        <InputText
          id="account_id"
          v-model="form.account_id"
          class="w-full"
          placeholder="请输入平台账户ID"
          :class="{ 'p-invalid': errors.account_id }"
        />
        <small v-if="errors.account_id" class="p-error">{{ errors.account_id }}</small>
      </div>

      <!-- 认证信息 -->
      <div class="field">
        <label for="access_token" class="block text-900 font-medium mb-2">访问令牌</label>
        <InputText
          id="access_token"
          v-model="form.access_token"
          class="w-full"
          placeholder="请输入访问令牌"
          type="password"
        />
      </div>

      <div class="field">
        <label for="refresh_token" class="block text-900 font-medium mb-2">刷新令牌</label>
        <InputText
          id="refresh_token"
          v-model="form.refresh_token"
          class="w-full"
          placeholder="请输入刷新令牌"
          type="password"
        />
      </div>

      <!-- 配置信息 -->
      <div class="formgrid grid">
        <div class="field col">
          <label for="currency" class="block text-900 font-medium mb-2">货币</label>
          <InputText
            id="currency"
            v-model="form.currency"
            class="w-full"
            placeholder="如: USD, CNY"
          />
        </div>

        <div class="field col">
          <label for="timezone" class="block text-900 font-medium mb-2">时区</label>
          <InputText
            id="timezone"
            v-model="form.timezone"
            class="w-full"
            placeholder="如: Asia/Shanghai"
          />
        </div>
      </div>

      <div class="field">
        <label for="sync_frequency" class="block text-900 font-medium mb-2">同步频率(分钟)</label>
        <InputNumber
          id="sync_frequency"
          v-model="form.sync_frequency"
          class="w-full"
          :min="1"
          :max="1440"
          placeholder="默认60分钟"
        />
      </div>

      <!-- OAuth授权按钮 -->
      <div v-if="selectedPlatform?.slug === 'facebook'" class="field">
        <Button
          label="通过Facebook授权"
          icon="pi pi-facebook"
          class="p-button-outlined p-button-primary w-full"
          @click="authorizeWithFacebook"
          :loading="authorizing"
        />
        <small class="text-500">点击此按钮将跳转到Facebook进行OAuth授权</small>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-content-end gap-2">
        <Button
          label="取消"
          icon="pi pi-times"
          class="p-button-text"
          @click="onCancel"
        />
        <Button
          label="确定"
          icon="pi pi-check"
          @click="onSubmit"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Dropdown from 'primevue/dropdown'
import { adsAccountApi } from '../../api/ads-account-api'
import type {
  AdsAccount,
  AdsAccountCreateRequest,
  AdsAccountUpdateRequest,
  AdsPlatform
} from '../../data/types/ads-account-types'

interface Props {
  visible: boolean
  adsAccount?: AdsAccount
  projectId: number
  platforms: AdsPlatform[]
}

interface Emits {
  (e: 'update:visible', value: boolean): void
  (e: 'success'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const loading = ref(false)
const authorizing = ref(false)
const errors = ref<Record<string, string>>({})

const isEditing = computed(() => !!props.adsAccount)
const selectedPlatform = computed(() =>
  props.platforms.find(p => p.id === form.value.ads_platform_id)
)

const form = ref({
  name: '',
  account_id: '',
  ads_platform_id: null as number | null,
  access_token: '',
  refresh_token: '',
  currency: '',
  timezone: '',
  sync_frequency: 60
})

const visible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

// 监听对话框打开，重置表单
watch(() => props.visible, (newVal) => {
  if (newVal) {
    resetForm()
    if (props.adsAccount) {
      loadAdsAccount(props.adsAccount)
    }
  }
})

const resetForm = () => {
  form.value = {
    name: '',
    account_id: '',
    ads_platform_id: null,
    access_token: '',
    refresh_token: '',
    currency: '',
    timezone: '',
    sync_frequency: 60
  }
  errors.value = {}
}

const loadAdsAccount = (adsAccount: AdsAccount) => {
  form.value = {
    name: adsAccount.name,
    account_id: adsAccount.account_id,
    ads_platform_id: adsAccount.ads_platform_id,
    access_token: '',
    refresh_token: '',
    currency: adsAccount.currency || '',
    timezone: adsAccount.timezone || '',
    sync_frequency: adsAccount.sync_frequency
  }
}

const validateForm = () => {
  errors.value = {}

  if (!form.value.name) {
    errors.value.name = '请输入账户名称'
  }

  if (!form.value.account_id) {
    errors.value.account_id = '请输入平台账户ID'
  }

  if (!form.value.ads_platform_id) {
    errors.value.ads_platform_id = '请选择广告平台'
  }

  return Object.keys(errors.value).length === 0
}

const authorizeWithFacebook = async () => {
  try {
    authorizing.value = true

    const result = await adsAccountApi.authorizeWithFacebook(props.projectId)
    const authUrl = result.data.auth_url

    // 在新窗口中打开授权页面
    const authWindow = window.open(authUrl, 'facebook_auth', 'width=600,height=600')

    // 监听授权完成
    const checkClosed = setInterval(() => {
      if (authWindow?.closed) {
        clearInterval(checkClosed)
        emit('success')
        visible.value = false
      }
    }, 1000)

  } catch (error) {
    console.error('Facebook授权失败:', error)
  } finally {
    authorizing.value = false
  }
}

const onSubmit = async () => {
  if (!validateForm()) return

  try {
    loading.value = true

    const data = {
      ...form.value,
      project_id: props.projectId
    }

    if (isEditing.value) {
      const updateData: AdsAccountUpdateRequest = {
        name: data.name,
        sync_frequency: data.sync_frequency
      }
      await adsAccountApi.updateAdsAccount(props.adsAccount!.id, updateData)
    } else {
      const createData: AdsAccountCreateRequest = data
      await adsAccountApi.createAdsAccount(createData)
    }

    emit('success')
    visible.value = false
  } catch (error) {
    console.error('保存广告账户失败:', error)
  } finally {
    loading.value = false
  }
}

const onCancel = () => {
  visible.value = false
}
</script>