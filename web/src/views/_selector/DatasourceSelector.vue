<template>
  <div class="database-selector space-y-4">
    <!-- 连接方式选择 -->
    <div>
      <label class="text-sm font-medium text-surface-700 mb-2 block">连接方式</label>
      <div class="flex gap-4">
        <div class="flex items-center">
          <RadioButton
              id="metadata"
              v-model="connectionType"
              name="connectionType"
              value="metadata"
          />
          <label for="metadata" class="ml-2 text-sm">使用元数据连接</label>
        </div>
        <div class="flex items-center">
          <RadioButton
              id="custom"
              v-model="connectionType"
              name="connectionType"
              value="custom"
          />
          <label for="custom" class="ml-2 text-sm">自定义连接</label>
        </div>
      </div>
    </div>

    <!-- 元数据连接选择 -->
    <div v-if="connectionType === 'metadata'" class="space-y-3">
      <div>
        <FloatLabel variant="on">
          <Dropdown
              id="metadata-connection"
              v-model="selectedMetaDatasourceId"
              :options="metaDatasources"
              optionLabel="name"
              optionValue="id"
              class="w-full"
              :loading="loadingDatasources"
              @change="onDatasourceChange"
              filter
          >
            <template #option="slotProps">
              <div class="flex items-center gap-2 p-2 justify-between h-full">
                <Tag
                    :value="getStatusLabel(slotProps.option.status)"
                    :severity="getStatusSeverity(slotProps.option.status)"
                    size="small"
                    class="ml-auto"
                />
                <div>
                  <i :class="getDatabaseTypeConfig(slotProps.option.db_type).icon"
                     :style="{ color: getDatabaseTypeConfig(slotProps.option.db_type).color }"/>
                  <span class="font-medium ml-3">{{ slotProps.option.name }}</span>
                  <div class="text-sm text-surface-500">
                    {{ getDatabaseTypeConfig(slotProps.option.db_type).label }} - {{
                      slotProps.option.host
                    }}:{{ slotProps.option.port }}
                  </div>
                </div>
              </div>
            </template>
          </Dropdown>
          <label for="metadata-connection">数据库连接 *</label>
        </FloatLabel>
      </div>

      <!-- 数据库选择 -->
      <div v-if="selectedDatasource" class="grid grid-cols-1 md:grid-cols-2 gap-3 space-y-3">
        <!-- Catalog选择 (Trino等) -->
        <div v-if="supportsCatalog">
          <FloatLabel variant="on">
            <Dropdown
                id="catalog"
                v-model="selectedCatalog"
                :options="availableCatalogs"
                class="w-full"
                :loading="loadingCatalogs"
                placeholder="选择Catalog"
                @change="onCatalogChange"
                showClear
            />
            <label for="catalog">Catalog</label>
          </FloatLabel>
        </div>

        <!-- 数据库选择 -->
        <div>
          <FloatLabel variant="on">
            <Dropdown
                id="database"
                v-model="selectedDatabase"
                :options="availableDatabases"
                class="w-full"
                :loading="loadingDatabases"
                @change="onDatabaseChange"
                showClear
            />
            <label for="database">数据库</label>
          </FloatLabel>
        </div>

        <!-- Schema选择 -->
        <div v-if="availableSchemas.length > 0" class="md:col-span-2">
          <FloatLabel variant="on">
            <Dropdown
                id="schema"
                v-model="selectedSchema"
                :options="availableSchemas"
                class="w-full"
                :loading="loadingSchemas"
                showClear
            />
            <label for="schema">Schema</label>
          </FloatLabel>
        </div>
      </div>

      <!-- 连接测试 -->
      <div v-if="selectedDatasource" class="flex items-center gap-2">
        <Button
            @click="testSelectedConnection"
            icon="pi pi-check-circle"
            label="测试连接"
            size="small"
            severity="secondary"
            :loading="testingConnection"
        />

        <div v-if="connectionTestResult" class="flex items-center gap-2">
          <i
              :class="connectionTestResult.success ? 'pi pi-check-circle text-green-600' : 'pi pi-times-circle text-red-600'"
          ></i>
          <span
              :class="connectionTestResult.success ? 'text-green-700' : 'text-red-700'"
              class="text-sm"
          >
            {{ connectionTestResult.message }}
          </span>
        </div>
      </div>
    </div>

    <!-- 自定义连接 -->
    <div v-else class="space-y-3">
      <DatasourceForm
          v-model="customConnectionForm"
          mode="create"
          :show-test-button="true"
          @test-connection="onCustomConnectionTest"
      />
    </div>

    <!-- 配置摘要 -->
    <div v-if="isConfigured" class="bg-blue-50 border border-blue-200 rounded-lg p-3">
      <h4 class="font-medium text-primary-900 mb-2 flex items-center gap-2">
        <i class="pi pi-info-circle"></i>
        当前配置
      </h4>
      <div class="text-sm text-primary-800 space-y-1">
        <div v-if="connectionType === 'metadata'">
          <span class="font-medium">元数据连接:</span> {{ selectedDatasource?.name }}
        </div>
        <div v-else>
          <span class="font-medium">自定义连接:</span> {{ customConnectionForm.host }}:{{ customConnectionForm.port }}
        </div>
        <div v-if="selectedCatalog">
          <span class="font-medium">Catalog:</span> {{ selectedCatalog }}
        </div>
        <div v-if="selectedDatabase">
          <span class="font-medium">数据库:</span> {{ selectedDatabase }}
        </div>
        <div v-if="selectedSchema">
          <span class="font-medium">Schema:</span> {{ selectedSchema }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import DatabaseApi from '@/api/database-api'
import type { Database, DatabaseTestResult, SqlExecuteNodeConfig } from '@/data/types/database-types'
import { DATABASE_STATUS_CONFIG, DATABASE_TYPE_OPTIONS, DATABASE_TYPES } from '@/data/constants/database-constants'

import RadioButton from 'primevue/radiobutton'
import Dropdown from 'primevue/dropdown'
import DatasourceForm from '@/views/_form/DatasourceForm.vue'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import FloatLabel from 'primevue/floatlabel'
import { ApiList, ApiRequest } from "@/api/base-api";

// Props & Emits
const props = defineProps<{
  modelValue: Partial<SqlExecuteNodeConfig>
}>()

const emit = defineEmits<{
  'update:modelValue': [value: Partial<SqlExecuteNodeConfig>]
}>()

// Services
const toast = useToast()

// Data
const loadingDatasources = ref(false)
const loadingCatalogs = ref(false)
const loadingDatabases = ref(false)
const loadingSchemas = ref(false)
const testingConnection = ref(false)

const metaDatasources = ref<Database[]>([])
const availableCatalogs = ref<string[]>([])
const availableDatabases = ref<string[]>([])
const availableSchemas = ref<string[]>([])
const connectionTestResult = ref<DatabaseTestResult | null>(null)

const connectionType = ref<'metadata' | 'custom'>('metadata')
const selectedMetaDatasourceId = ref<number | null>(null)
const selectedCatalog = ref('')
const selectedDatabase = ref('')
const selectedSchema = ref('')

// 自定义连接表单数据
const customConnectionForm = ref({
  name: '自定义连接',
  db_type: 'mysql' as const,
  host: '',
  port: 3306,
  username: '',
  password: '',
  description: '自定义数据库连接',
  extra_config: {}
})

// Options
const databaseTypeOptions = DATABASE_TYPE_OPTIONS

// Computed
const selectedDatasource = computed(() => {
  return metaDatasources.value.find(conn => conn.id === selectedMetaDatasourceId.value) || null
})

const supportsCatalog = computed(() => {
  const dbType = connectionType.value === 'metadata'
      ? selectedDatasource.value?.db_type
      : customConnectionForm.value.db_type
  return dbType === 'trino'
})

const supportsSchema = computed(() => {
  const dbType = connectionType.value === 'metadata'
      ? selectedDatasource.value?.db_type
      : customConnectionForm.value.db_type
  return dbType !== 'mysql' // MySQL不支持Schema概念
})

const isCustomConnectionValid = computed(() => {
  return customConnectionForm.value.host &&
      customConnectionForm.value.port &&
      customConnectionForm.value.username &&
      customConnectionForm.value.password
})

const isConfigured = computed(() => {
  if (connectionType.value === 'metadata') {
    return selectedMetaDatasourceId.value !== null
  } else {
    return isCustomConnectionValid.value
  }
})

// Methods
const loadMetadataConnections = async () => {
  loadingDatasources.value = true
  ApiList("meta_datasource")
      .then(res => metaDatasources.value = res)
      .catch(err => toast.add({ severity: 'error', summary: '获取元数据连接列表失败', life: 3000 }))
      .finally(loadingDatasources.value = false)
}

const onDatasourceChange = async () => {
  if (!selectedDatasource.value) return

  connectionTestResult.value = null
  selectedCatalog.value = ''
  selectedDatabase.value = ''
  selectedSchema.value = ''
  availableCatalogs.value = []
  availableDatabases.value = []
  availableSchemas.value = []

  if (supportsCatalog.value) {
    loadCatalogs()
  } else {
    loadDatabases()
  }
  updateConfig()
}

const onCatalogChange = () => {
  selectedDatabase.value = ''
  selectedSchema.value = ''
  availableDatabases.value = []
  availableSchemas.value = []

  loadDatabases()
  updateConfig()
}

const onDatabaseChange = () => {
  selectedSchema.value = ''
  availableSchemas.value = []
  if (!supportsSchema.value) return

  loadSchemas()
  updateConfig()
}

const loadCatalogs = () => {
  if (!selectedDatasource.value?.id) return

  if (!supportsCatalog) return

  loadingCatalogs.value = true

  ApiRequest("GET", "meta_datasource/get_catalogs", {}, {
    id: selectedMetaDatasourceId.value,
  }).then(res => {
    availableCatalogs.value = res
  }).catch(err => {
    toast.add({ severity: 'error', summary: err.msg, life: 3000 })
  }).finally(() => {
    loadingCatalogs.value = false
  })
}

const loadDatabases = () => {
  if (!selectedDatasource.value?.id) return
  loadingDatabases.value = true
  ApiRequest("GET", "meta_datasource/get_databases", {}, {
    id: selectedMetaDatasourceId.value,
    catalog: selectedCatalog.value
  }).then(res => {
    availableDatabases.value = res
  }).catch(err => {
    toast.add({ severity: 'error', summary: err.msg, life: 3000 })
  }).finally(() => {
    loadingDatabases.value = false
  })
}

const loadSchemas = () => {
  if (!selectedDatasource.value?.id || !selectedDatabase.value) return
  // MySQL不支持Schema概念，直接返回
  if (!supportsSchema.value) return

  loadingSchemas.value = true
  ApiRequest("GET", "meta_datasource/get_schemas", {}, {
    id: selectedMetaDatasourceId.value,
    catalog: selectedCatalog.value,
    database: selectedDatabase.value
  }).then(res => {
    availableSchemas.value = res
  }).catch(err => {
    toast.add({ severity: 'error', summary: err.msg, life: 3000 })
  }).finally(() => {
    loadingSchemas.value = false
  })
}

const testSelectedConnection = async () => {
  if (!selectedDatasource.value) return

  testingConnection.value = true
  ApiRequest("GET", "meta_datasource/test_connection", {}, {
    id: selectedMetaDatasourceId.value,
    catalog: selectedCatalog.value,
    database: selectedDatabase.value,
    schema: selectedSchema.value
  }).then(res => {
    connectionTestResult.value = res
  }).catch(err => {
    connectionTestResult.value = {
      success: false,
      message: '连接测试失败',
      error: err.msg,
      test_time: new Date().toISOString()
    }
  }).finally(() => {
    testingConnection.value = false
  })
}

// 自定义连接测试回调
const onCustomConnectionTest = () => {
  // DatasourceForm会处理测试，这里只需要更新配置
  updateConfig()
}

const testCustomConnection = async () => {
  if (!isCustomConnectionValid.value) return

  testingConnection.value = true
  try {
    const result = await DatabaseApi.testConnection(customConnectionForm.value)
    connectionTestResult.value = result
  } catch (error: any) {
    connectionTestResult.value = {
      success: false,
      message: '连接测试失败',
      error: error.message,
      test_time: new Date().toISOString()
    }
  } finally {
    testingConnection.value = false
  }
}

const updateConfig = () => {
  const config: Partial<SqlExecuteNodeConfig> = {
    ...props.modelValue,
    connection_type: connectionType.value
  }

  if (connectionType.value === 'metadata') {
    config.metadata_id = selectedMetaDatasourceId.value || undefined
    config.custom_connection = undefined
  } else {
    config.metadata_id = undefined
    config.custom_connection = {
      name: customConnectionForm.value.name,
      db_type: customConnectionForm.value.db_type,
      host: customConnectionForm.value.host,
      port: customConnectionForm.value.port,
      username: customConnectionForm.value.username,
      password: customConnectionForm.value.password,
      description: customConnectionForm.value.description
    }
  }

  config.catalog = selectedCatalog.value || undefined
  config.database = selectedDatabase.value || undefined
  config.schema = selectedSchema.value || undefined

  emit('update:modelValue', config)
}

// Helpers
const getDatabaseTypeConfig = (type: string) => {
  return DATABASE_TYPES[type as keyof typeof DATABASE_TYPES] || DATABASE_TYPES.mysql
}

const getStatusLabel = (status?: string) => {
  return DATABASE_STATUS_CONFIG[status as keyof typeof DATABASE_STATUS_CONFIG]?.label || '未知'
}

const getStatusSeverity = (status?: string) => {
  return DATABASE_STATUS_CONFIG[status as keyof typeof DATABASE_STATUS_CONFIG]?.severity || 'secondary'
}

// Lifecycle
onMounted(() => {
  loadMetadataConnections()

  // 加载初始配置
  if (props.modelValue.connection_type) {
    connectionType.value = props.modelValue.connection_type
  }

  if (props.modelValue.metadata_id) {
    selectedMetaDatasourceId.value = props.modelValue.metadata_id
  }

  if (props.modelValue.custom_connection) {
    customConnectionForm.value = {
      ...customConnectionForm.value,
      db_type: props.modelValue.custom_connection.db_type,
      host: props.modelValue.custom_connection.host,
      port: props.modelValue.custom_connection.port,
      username: props.modelValue.custom_connection.username,
      password: props.modelValue.custom_connection.password
    }
  }

  selectedCatalog.value = props.modelValue.catalog || ''
  selectedDatabase.value = props.modelValue.database || ''
  selectedSchema.value = props.modelValue.schema || ''
})

// Watch
watch(connectionType, () => {
  connectionTestResult.value = null
  updateConfig()
})

watch([selectedCatalog, selectedDatabase, selectedSchema], () => {
  updateConfig()
})

watch(customConnectionForm, () => {
  updateConfig()
}, { deep: true })
</script>
