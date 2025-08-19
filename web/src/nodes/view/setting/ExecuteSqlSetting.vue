<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import { preCheckExecuteSqlNode, validateExecuteSqlNode, } from '@/nodes/setting/execute-sql'
import type { Database } from '@/data/types/database-types'

import SqlEditor from '@/components/SqlEditor.vue'
import SettingLayout from "@/nodes/view/setting/SettingLayout.vue";
import SettingColumn from "@/nodes/view/setting/SettingColumn.vue";
import DatabaseSelector from "@/views/_selector/DatasourceSelector.vue";
import { SQL_EXECUTE_NODE_DEFAULT } from "@/data/defaults/nodes";

// Props & Emits
const props = defineProps<{
  visible?: boolean
  config?: any
}>()

const emit = defineEmits<{
  'update:visible': [visible: boolean]
  'save': [value: any]
}>()

const localVisible = ref(props.visible)
watch(() => props.visible, (val) => localVisible.value = val)
watch(localVisible, (val) => emit('update:visible', val))

// Services
const toast = useToast()

// Data
const validating = ref(false)
const previewing = ref(false)
const validationResult = ref<{ errors: string[] } | null>(null)
const precheckResult = ref<{ success: boolean; message: string; warnings?: string[] } | null>(null)
const loading = ref(false)

// 从配置文件获取初始配置
const initConfig = () => JSON.parse(JSON.stringify(SQL_EXECUTE_NODE_DEFAULT))

const config = ref(initConfig())


watch(() => props.config, (val) => {
  if (val) {
    config.value = { ...initConfig(), ...val }
  }
}, { immediate: true, deep: true })


// Computed
const sqlError = computed(() => {
  if (!config.value.sql?.trim()) {
    return 'SQL语句不能为空'
  }
  return ''
})

const isConfigValid = computed(() => {
  return validationResult.value?.errors.length === 0
})

const currentDatabase = computed((): Database | null => {
  // DatabaseSelector会处理数据库连接，这里返回基本信息即可
  if (config.value.connection_type === 'metadata' && config.value.metadata_id) {
    return { id: config.value.metadata_id } as Database
  }
  return null
})

// 更新配置
const updateConfig = (newConfig: any) => {
  // DatabaseSelector直接更新整个config
  config.value = newConfig
}

const validateConfig = async () => {
  validating.value = true

  try {
    const errors = validateExecuteSqlNode(config.value)
    validationResult.value = { errors }

    if (errors.length === 0) {
      toast.add({ severity: 'success', summary: '节点配置验证通过', life: 3000 })
    } else {
      toast.add({ severity: 'error', summary: `发现 ${errors.length} 个配置错误`, life: 5000 })
    }
  } finally {
    validating.value = false
  }
}

const previewExecution = async () => {
  if (!isConfigValid.value) return

  previewing.value = true

  try {
    const result = await preCheckExecuteSqlNode(config.value)
    precheckResult.value = result

    if (result.success) {
      toast.add({
        severity: 'success',
        summary: '预检通过',
        detail: result.message,
        life: 3000
      })
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '预检失败',
      detail: error.message,
      life: 5000
    })
  } finally {
    previewing.value = false
  }
}

const testExecuteSql = (sql: string) => {
  // SQL测试执行的回调
  console.log('Test execute SQL:', sql)
}

// Helpers
const getConnectionSummary = () => {
  if (config.value.connection_type === 'metadata') {
    return config.value.metadata_id ? `元数据连接 #${config.value.metadata_id}` : '未选择'
  } else {
    const conn = config.value.custom_connection
    return conn ? `${conn.host}:${conn.port}` : '未配置'
  }
}

const getSqlSummary = () => {
  const sql = config.value.sql?.trim()
  if (!sql) return '未配置'

  const firstLine = sql.split('\n')[0]
  return firstLine.length > 50 ? firstLine.substring(0, 50) + '...' : firstLine
}

// 保存配置
const handleSave = () => {
  emit('save', { ...config.value })
}

// Lifecycle
onMounted(validateConfig)

// Watch
watch(config, () => {
  // 配置改变时清除验证结果
  validationResult.value = null
  precheckResult.value = null
}, { deep: true })

</script>

<template>
  <SettingLayout v-model:visible="localVisible">
    <template #header>
      <div class="flex items-center gap-3 pb-4 border-b border-surface-200">
        <div class="w-10 h-10 rounded-lg bg-purple-100 flex items-center justify-center">
          <i class="pi pi-play text-purple-600 text-lg"></i>
        </div>
        <div>
          <h2 class="text-xl font-semibold text-surface-900">执行SQL节点</h2>
          <p class="text-surface-600 text-sm">执行SQL语句并返回结果数据</p>
        </div>
      </div>
    </template>
    <SettingColumn title="执行SQL节点">
      <div class="execute-sql-setting p-6 space-y-6">

        <!-- 数据库连接配置 -->
        <Card>
          <template #header>
            <div class="p-6 pb-0">
              <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
                <i class="pi pi-database text-surface-600"></i>
                数据库连接
              </h3>
              <p class="text-surface-500 text-sm mt-1">配置数据库连接方式和目标数据库</p>
            </div>
          </template>

          <template #content>
            <DatabaseSelector
                v-model="config"
                @update:model-value="updateConfig"
            />
          </template>
        </Card>

        <!-- SQL配置 -->
        <Card>
          <template #header>
            <div class="p-6 pb-0">
              <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
                <i class="pi pi-code text-surface-600"></i>
                SQL配置
              </h3>
              <p class="text-surface-500 text-sm mt-1">编写和配置要执行的SQL语句</p>
            </div>
          </template>

          <template #content>
            <div class="space-y-4">
              <!-- SQL编辑器 -->
              <div>
                <label class="text-sm font-medium text-surface-700 mb-2 block">SQL语句 *</label>
                <SqlEditor
                    v-model="config.sql"
                    :height="200"
                    :database-connection="currentDatabase"
                    @execute="testExecuteSql"
                />
                <small v-if="sqlError" class="text-red-500 mt-1 block">{{ sqlError }}</small>
              </div>

              <!-- 执行参数 -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <FloatLabel variant="on">
                    <InputNumber
                        id="timeout"
                        v-model="config.timeout"
                        class="w-full"
                        :min="1"
                        :max="3600"
                        suffix=" 秒"
                    />
                    <label for="timeout">超时时间 *</label>
                  </FloatLabel>
                  <small class="text-surface-500">SQL执行超时时间，建议不超过10分钟</small>
                </div>

                <div>
                  <FloatLabel variant="on">
                    <InputNumber
                        id="max-rows"
                        v-model="config.max_rows"
                        class="w-full"
                        :min="1"
                        :max="100000"
                        suffix=" 行"
                    />
                    <label for="max-rows">最大返回行数 *</label>
                  </FloatLabel>
                  <small class="text-surface-500">限制返回的最大行数，避免内存溢出</small>
                </div>
              </div>
            </div>
          </template>
        </Card>

        <!-- 结果处理配置 -->
        <Card>
          <template #header>
            <div class="p-6 pb-0">
              <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
                <i class="pi pi-cog text-surface-600"></i>
                结果处理
              </h3>
              <p class="text-surface-500 text-sm mt-1">配置SQL执行结果的处理方式</p>
            </div>
          </template>

          <template #content>
            <div class="space-y-4">
              <!-- 输出格式 -->
              <div>
                <label class="text-sm font-medium text-surface-700 mb-2 block">输出格式</label>
                <div class="flex gap-4">
                  <div class="flex items-center">
                    <RadioButton
                        id="format-json"
                        v-model="config.output_format"
                        name="output_format"
                        value="json"
                    />
                    <label for="format-json" class="ml-2 text-sm">JSON</label>
                  </div>
                  <div class="flex items-center">
                    <RadioButton
                        id="format-csv"
                        v-model="config.output_format"
                        name="output_format"
                        value="csv"
                    />
                    <label for="format-csv" class="ml-2 text-sm">CSV</label>
                  </div>
                  <div class="flex items-center">
                    <RadioButton
                        id="format-table"
                        v-model="config.output_format"
                        name="output_format"
                        value="none"
                    />
                    <label for="format-table" class="ml-2 text-sm">不输出</label>
                  </div>
                </div>
              </div>

              <!-- 结果保存 -->
              <div class="space-y-3">
                <div class="flex items-center">
                  <Checkbox
                      id="save-result"
                      v-model="config.save_result"
                      binary
                  />
                  <label for="save-result" class="ml-2 text-sm font-medium">保存执行结果到数据表</label>
                </div>

                <div v-if="config.save_result" class="ml-6">
                  <FloatLabel variant="on">
                    <InputText
                        id="result-table"
                        v-model="config.result_table"
                        class="w-full"
                        placeholder="例如: temp_sql_result_001"
                    />
                    <label for="result-table">结果表名 *</label>
                  </FloatLabel>
                  <small class="text-surface-500">指定保存结果的临时表名，用于后续节点使用</small>
                </div>
              </div>
            </div>
          </template>
        </Card>

        <!-- 配置验证和预览 -->
        <Card>
          <template #header>
            <div class="p-6 pb-0">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
                    <i class="pi pi-check-circle text-surface-600"></i>
                    配置验证
                  </h3>
                  <p class="text-surface-500 text-sm mt-1">验证节点配置并预览执行计划</p>
                </div>
                <div class="flex gap-2">
                  <Button
                      @click="validateConfig"
                      icon="pi pi-check"
                      label="验证配置"
                      size="small"
                      severity="secondary"
                      :loading="validating"
                  />

                  <Button
                      @click="previewExecution"
                      icon="pi pi-eye"
                      label="预览执行"
                      size="small"
                      :disabled="!isConfigValid"
                      :loading="previewing"
                  />
                </div>
              </div>
            </div>
          </template>

          <template #content>
            <div class="space-y-4">
              <!-- 验证结果 -->
              <div v-if="validationResult">
                <div
                    v-if="validationResult.errors.length === 0"
                    class="flex items-start gap-2 p-3 bg-green-50 border border-green-200 rounded-lg"
                >
                  <i class="pi pi-check-circle text-green-600 mt-0.5"></i>
                  <div>
                    <div class="font-medium text-green-900">配置验证通过</div>
                    <div class="text-sm text-green-700">节点配置正确，可以正常执行</div>
                  </div>
                </div>

                <div
                    v-else
                    class="space-y-2"
                >
                  <div
                      v-for="(error, index) in validationResult.errors"
                      :key="index"
                      class="flex items-start gap-2 p-3 bg-red-50 border border-red-200 rounded-lg"
                  >
                    <i class="pi pi-times-circle text-red-600 mt-0.5"></i>
                    <div class="text-sm text-red-700">{{ error }}</div>
                  </div>
                </div>
              </div>

              <!-- 预检结果 -->
              <div v-if="precheckResult">
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <div class="flex items-start gap-2 text-blue-800">
                    <i class="pi pi-info-circle mt-0.5"></i>
                    <div class="flex-1">
                      <div class="font-medium mb-1">{{ precheckResult.message }}</div>

                      <!-- 警告信息 -->
                      <div v-if="precheckResult.warnings?.length" class="space-y-1 mt-2">
                        <div
                            v-for="(warning, index) in precheckResult.warnings"
                            :key="index"
                            class="text-sm bg-yellow-100 text-yellow-800 p-2 rounded flex items-start gap-2"
                        >
                          <i class="pi pi-exclamation-triangle text-xs mt-0.5"></i>
                          <span>{{ warning }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- 配置摘要 -->
              <div class="bg-surface-50 border border-surface-200 rounded-lg p-4">
                <h4 class="font-medium text-surface-900 mb-2">配置摘要</h4>
                <div class="text-sm text-surface-700 space-y-1">
                  <div><span class="font-medium">连接方式:</span> {{ getConnectionSummary() }}</div>
                  <div><span class="font-medium">SQL语句:</span> {{ getSqlSummary() }}</div>
                  <div><span class="font-medium">执行限制:</span> 超时{{ config.timeout }}秒，最多{{ config.max_rows }}行
                  </div>
                  <div><span class="font-medium">输出格式:</span> {{ config.output_format?.toUpperCase() }}</div>
                  <div v-if="config.save_result">
                    <span class="font-medium">结果保存:</span> {{ config.result_table }}
                  </div>
                </div>
              </div>
            </div>
          </template>
        </Card>
      </div>
    </SettingColumn>

    <template #footer>
      <Button @click="handleSave" type="primary" size="small">保存设置</Button>
      <Button @click="localVisible = false" size="small">关闭</Button>
    </template>
  </SettingLayout>
</template>

<style scoped>
.form-item {
  margin-bottom: 1rem;
}

.custom-connection-config {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}

.execute-sql-setting {
  max-height: 80vh;
  overflow-y: auto;
}
</style>
