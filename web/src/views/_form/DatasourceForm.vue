<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import DatabaseApi from '@/api/database-api'
import { ApiList } from '@/api/base-api'
import type { DatabaseForm, DatabaseTestResult, Database } from '@/data/types/database-types'
import { DATABASE_TYPES, DATABASE_TYPE_OPTIONS } from '@/data/constants/database-constants'

import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Dropdown from 'primevue/dropdown'
import Password from 'primevue/password'
import Textarea from 'primevue/textarea'
import FloatLabel from 'primevue/floatlabel'

// Props & Emits
const props = defineProps<{
  modelValue: DatabaseForm
  mode?: 'create' | 'edit'
  datasource?: Database | null
  showTestButton?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: DatabaseForm]
  'test-connection': []
  'submit': []
}>()

// Services
const toast = useToast()

// Data
const testing = ref(false)
const testResult = ref<DatabaseTestResult | null>(null)
const errors = ref<Record<string, string>>({})
const catalogs = ref<any[]>([])
const loadingCatalogs = ref(false)

// Options
const databaseTypeOptions = DATABASE_TYPE_OPTIONS

// Computed
const form = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const currentDatabaseConfig = computed(() => {
  return DATABASE_TYPES[form.value.db_type]
})

const canTest = computed(() => {
  return form.value.host && form.value.port && form.value.username && form.value.password
})

const isFormValid = computed(() => {
  return form.value.name && form.value.db_type && form.value.host &&
         form.value.port && form.value.username && form.value.password &&
         Object.keys(errors.value).length === 0
})

// Methods
const validateForm = () => {
  errors.value = {}

  if (!form.value.name.trim()) {
    errors.value.name = '请输入连接名称'
  }

  if (!form.value.db_type) {
    errors.value.db_type = '请选择数据库类型'
  }

  if (!form.value.host.trim()) {
    errors.value.host = '请输入主机地址'
  }

  if (!form.value.port || form.value.port <= 0 || form.value.port > 65535) {
    errors.value.port = '请输入有效的端口号'
  }

  if (!form.value.username.trim()) {
    errors.value.username = '请输入用户名'
  }

  if (!form.value.password) {
    errors.value.password = '请输入密码'
  }

  return Object.keys(errors.value).length === 0
}

const onDatabaseTypeChange = () => {
  // 更新默认端口
  form.value.port = currentDatabaseConfig.value.default_port

  // 重置额外配置
  form.value.extra_config = {}

  // 清除测试结果
  testResult.value = null
}

const testConnection = async () => {
  if (!canTest.value) return

  testing.value = true
  testResult.value = null

  try {
    const result = await DatabaseApi.testConnection(form.value)
    testResult.value = result
    emit('test-connection')
  } catch (error: any) {
    testResult.value = {
      success: false,
      message: '连接测试失败',
      error: error.message,
      test_time: new Date().toISOString()
    }
  } finally {
    testing.value = false
  }
}

const handleSubmit = async () => {
  if (!validateForm()) return
  emit('submit')
}

const loadCatalogs = async () => {
  loadingCatalogs.value = true
  try {
    const response = await ApiList("catalog")
    catalogs.value = response || []
  } catch (error) {
    console.error('加载catalog列表失败:', error)
  } finally {
    loadingCatalogs.value = false
  }
}

// Helpers
const getExtraFieldLabel = (field: string) => {
  const labels: Record<string, string> = {
    charset: '字符集',
    collation: '排序规则',
    service_name: '服务名',
    sid: 'SID',
    auth_mechanism: '认证机制',
    kerberos_service: 'Kerberos服务',
    sslmode: 'SSL模式',
    connect_timeout: '连接超时',
    catalog: '默认Catalog',
    schema: '默认Schema',
    source: '查询源',
    database: '默认数据库',
    compression: '压缩算法',
    instance: '实例名',
    integrated_security: '集成认证'
  }
  return labels[field] || field
}

const getExtraFieldDescription = (field: string) => {
  const descriptions: Record<string, string> = {
    charset: '数据库字符编码，如utf8mb4',
    collation: '字符排序规则',
    service_name: 'Oracle服务名称',
    sid: 'Oracle系统标识符',
    auth_mechanism: 'SASL认证机制',
    kerberos_service: 'Kerberos服务主体名称',
    sslmode: 'SSL连接模式：disable/require/verify-full',
    connect_timeout: '连接超时时间（秒）',
    catalog: 'Trino默认catalog',
    schema: 'Trino默认schema',
    source: '查询来源标识',
    database: '默认连接的数据库',
    compression: '数据压缩算法',
    instance: 'SQL Server实例名',
    integrated_security: '使用Windows认证'
  }
  return descriptions[field] || ''
}

// Lifecycle
onMounted(() => {
  loadCatalogs()
})

// Expose validation method
defineExpose({
  validateForm,
  isFormValid
})
</script>

<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <!-- 基本信息 -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- 连接名称 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="name"
            v-model="form.name"
            class="w-full"
            :invalid="!!errors.name"
            size="small"
          />
          <label for="name">连接名称 *</label>
        </FloatLabel>
        <small v-if="errors.name" class="text-red-500">{{ errors.name }}</small>
      </div>

      <!-- 数据库类型 -->
      <div>
        <FloatLabel variant="on">
          <Dropdown
            id="type"
            v-model="form.db_type"
            :options="databaseTypeOptions"
            optionLabel="label"
            optionValue="value"
            class="w-full"
            :invalid="!!errors.db_type"
            size="small"
            @change="onDatabaseTypeChange"
          >
            <template #option="slotProps">
              <div class="flex items-center gap-2">
                <i :class="slotProps.option.icon" :style="{ color: slotProps.option.color }"></i>
                <div>
                  <div>{{ slotProps.option.label }}</div>
                  <small class="text-surface-500">{{ slotProps.option.description }}</small>
                </div>
              </div>
            </template>
          </Dropdown>
          <label for="db_type">数据库类型 *</label>
        </FloatLabel>
        <small v-if="errors.db_type" class="text-red-500">{{ errors.db_type }}</small>
      </div>
    </div>

    <!-- 目录选择 -->
    <div>
      <FloatLabel variant="on">
        <Dropdown
          id="catalog"
          v-model="form.catalog_id"
          :options="catalogs"
          optionLabel="name"
          optionValue="id"
          class="w-full"
          size="small"
          :loading="loadingCatalogs"
          showClear
          placeholder="选择目录"
        />
        <label for="catalog">所属目录</label>
      </FloatLabel>
      <small class="text-surface-500">选择数据源所属的目录分类</small>
    </div>

    <!-- 连接配置 -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- 主机地址 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="host"
            v-model="form.host"
            class="w-full"
            :invalid="!!errors.host"
            size="small"
          />
          <label for="host">主机地址 *</label>
        </FloatLabel>
        <small v-if="errors.host" class="text-red-500">{{ errors.host }}</small>
      </div>

      <!-- 端口号 -->
      <div>
        <FloatLabel variant="on">
          <InputNumber
            id="port"
            v-model="form.port"
            class="w-full"
            :invalid="!!errors.port"
            :min="1"
            :max="65535"
            size="small"
          />
          <label for="port">端口号 *</label>
        </FloatLabel>
        <small v-if="errors.port" class="text-red-500">{{ errors.port }}</small>
      </div>
    </div>

    <!-- 认证信息 -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- 用户名 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="username"
            v-model="form.username"
            class="w-full"
            :invalid="!!errors.username"
            size="small"
          />
          <label for="username">用户名 *</label>
        </FloatLabel>
        <small v-if="errors.username" class="text-red-500">{{ errors.username }}</small>
      </div>

      <!-- 密码 -->
      <div>
        <FloatLabel variant="on">
          <Password
            id="password"
            v-model="form.password"
            class="w-full"
            inputClass="w-full"
            :invalid="!!errors.password"
            :feedback="false"
            toggleMask
          />
          <label for="password">密码 *</label>
        </FloatLabel>
        <small v-if="errors.password" class="text-red-500">{{ errors.password }}</small>
      </div>
    </div>

    <!-- 描述 -->
    <div>
      <FloatLabel variant="on">
        <Textarea
          id="description"
          v-model="form.description"
          class="w-full"
          rows="3"
          :invalid="!!errors.description"
        />
        <label for="description">描述信息</label>
      </FloatLabel>
      <small v-if="errors.description" class="text-red-500">{{ errors.description }}</small>
    </div>

    <!-- 额外配置 -->
    <div v-if="currentDatabaseConfig?.extra_fields?.length" class="space-y-4">
      <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
        <i class="pi pi-cog text-surface-600"></i>
        高级配置
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="field in currentDatabaseConfig.extra_fields"
          :key="field"
        >
          <FloatLabel variant="on">
            <InputText
              :id="field"
              v-model="form.extra_config[field]"
              class="w-full"
              size="small"
            />
            <label :for="field">{{ getExtraFieldLabel(field) }}</label>
          </FloatLabel>
          <small class="text-surface-500">{{ getExtraFieldDescription(field) }}</small>
        </div>
      </div>
    </div>

    <!-- 连接测试 -->
    <div v-if="showTestButton" class="bg-surface-50 p-4 rounded-lg">
      <div class="flex items-center justify-between">
        <div>
          <h4 class="font-medium text-surface-900">连接测试</h4>
          <p class="text-sm text-surface-600 mt-1">验证数据库连接配置是否正确</p>
        </div>
        <Button
          @click="testConnection"
          icon="pi pi-check-circle"
          label="测试连接"
          severity="secondary"
          size="small"
          :loading="testing"
          :disabled="!canTest"
        />
      </div>

      <!-- 测试结果 -->
      <div v-if="testResult" class="mt-4">
        <div
          v-if="testResult.success"
          class="flex items-start gap-2 p-3 bg-green-50 border border-green-200 rounded-lg"
        >
          <i class="pi pi-check-circle text-green-600 mt-0.5"></i>
          <div>
            <div class="font-medium text-green-900">连接测试成功</div>
            <div class="text-sm text-green-700">{{ testResult.message }}</div>
            <div v-if="testResult.databases?.length" class="text-sm text-green-600 mt-1">
              发现 {{ testResult.databases.length }} 个数据库
            </div>
          </div>
        </div>

        <div
          v-else
          class="flex items-start gap-2 p-3 bg-red-50 border border-red-200 rounded-lg"
        >
          <i class="pi pi-times-circle text-red-600 mt-0.5"></i>
          <div>
            <div class="font-medium text-red-900">连接测试失败</div>
            <div class="text-sm text-red-700">{{ testResult.message }}</div>
            <div v-if="testResult.error" class="text-sm text-red-600 mt-1">
              {{ testResult.error }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </form>
</template>

<style scoped>
.form-item {
  margin-bottom: 1rem;
}
</style>