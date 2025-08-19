<script setup lang="ts">
import { ref, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import DatabaseApi from '@/api/database-api'
import type { Database, DatabaseTestResult } from '@/data/types/database-types'
import { DATABASE_TYPES, DATABASE_STATUS_CONFIG } from '@/data/constants/database-constants'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Tag from 'primevue/tag'

// Props & Emits
const props = defineProps<{
  visible: boolean
  database?: Database | null
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
}>()

// Services
const toast = useToast()

// Data
const testing = ref(false)
const testResult = ref<DatabaseTestResult | null>(null)

// Computed
const dialogVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

// Methods
const testConnection = async () => {
  if (!props.database) return

  testing.value = true
  testResult.value = null

  try {
    const result = await DatabaseApi.testConnection(props.database)
    testResult.value = result

    if (result.success) {
      toast.add({
        severity: 'success',
        summary: '连接测试成功',
        detail: result.message,
        life: 3000
      })
    } else {
      toast.add({
        severity: 'error',
        summary: '连接测试失败',
        detail: result.message,
        life: 5000
      })
    }
  } catch (error: any) {
    testResult.value = {
      success: false,
      message: '连接测试失败',
      error: error.message,
      test_time: new Date().toISOString()
    }

    toast.add({
      severity: 'error',
      summary: '测试失败',
      detail: error.message,
      life: 5000
    })
  } finally {
    testing.value = false
  }
}

// Helpers
const getDatabaseTypeConfig = (type: string) => {
  return DATABASE_TYPES[type as keyof typeof DATABASE_TYPES] || DATABASE_TYPES.mysql
}

const getStatusConfig = (status: string) => {
  return DATABASE_STATUS_CONFIG[status as keyof typeof DATABASE_STATUS_CONFIG] || DATABASE_STATUS_CONFIG.inactive
}

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

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}
</script>

<template>
  <Dialog
    v-model:visible="dialogVisible"
    modal
    :header="'数据库连接详情'"
    class="w-full max-w-3xl"
    :closable="true"
    :draggable="false"
  >
    <div v-if="database" class="space-y-6">
      <!-- 基本信息 -->
      <Card>
        <template #header>
          <div class="p-6 pb-0">
            <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
              <i
                :class="getDatabaseTypeConfig(database.db_type).icon"
                :style="{ color: getDatabaseTypeConfig(database.db_type).color }"
              ></i>
              {{ database.name }}
            </h3>
          </div>
        </template>

        <template #content>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- 左侧信息 -->
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-surface-600">数据库类型</label>
                <div class="flex items-center gap-2 mt-1">
                  <Tag
                    :value="getDatabaseTypeConfig(database.db_type).label"
                    :style="{ backgroundColor: `${getDatabaseTypeConfig(database.db_type).color}20`, color: getDatabaseTypeConfig(database.db_type).color }"
                  />
                </div>
              </div>

              <div>
                <label class="text-sm font-medium text-surface-600">连接地址</label>
                <div class="mt-1 text-surface-900 font-mono text-sm">
                  {{ database.host }}:{{ database.port }}
                </div>
              </div>

              <div>
                <label class="text-sm font-medium text-surface-600">用户名</label>
                <div class="mt-1 text-surface-900">{{ database.username }}</div>
              </div>

              <div v-if="database.description">
                <label class="text-sm font-medium text-surface-600">描述信息</label>
                <div class="mt-1 text-surface-900">{{ database.description }}</div>
              </div>
            </div>

            <!-- 右侧状态 -->
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-surface-600">连接状态</label>
                <div class="mt-1">
                  <Tag
                    :value="getStatusConfig(database.status || 'inactive').label"
                    :severity="getStatusConfig(database.status || 'inactive').severity"
                  />
                </div>
              </div>

              <div>
                <label class="text-sm font-medium text-surface-600">创建时间</label>
                <div class="mt-1 text-surface-900">{{ formatDateTime(database.created_at!) }}</div>
              </div>

              <div>
                <label class="text-sm font-medium text-surface-600">更新时间</label>
                <div class="mt-1 text-surface-900">{{ formatDateTime(database.updated_at!) }}</div>
              </div>

              <div v-if="database.last_test_at">
                <label class="text-sm font-medium text-surface-600">最后测试时间</label>
                <div class="mt-1 text-surface-900">{{ formatDateTime(database.last_test_at) }}</div>
              </div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 高级配置 -->
      <Card v-if="database.extra_config && Object.keys(database.extra_config).length > 0">
        <template #header>
          <div class="p-6 pb-0">
            <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
              <i class="pi pi-cog text-surface-600"></i>
              高级配置
            </h3>
          </div>
        </template>

        <template #content>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div
              v-for="(value, key) in database.extra_config"
              :key="key"
              class="space-y-1"
            >
              <label class="text-sm font-medium text-surface-600">{{ getExtraFieldLabel(key) }}</label>
              <div class="text-surface-900 font-mono text-sm">{{ value || '未设置' }}</div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 连接测试 -->
      <Card>
        <template #header>
          <div class="p-6 pb-0">
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
                <i class="pi pi-check-circle text-surface-600"></i>
                连接测试
              </h3>
              <Button
                @click="testConnection"
                icon="pi pi-refresh"
                label="重新测试"
                severity="secondary"
                size="small"
                :loading="testing"
              />
            </div>
          </div>
        </template>

        <template #content>
          <!-- 测试结果 -->
          <div v-if="testResult" class="space-y-4">
            <div
              v-if="testResult.success"
              class="flex items-start gap-3 p-4 bg-green-50 border border-green-200 rounded-lg"
            >
              <i class="pi pi-check-circle text-green-600 text-xl mt-0.5"></i>
              <div class="flex-1">
                <div class="font-medium text-green-900 mb-1">连接测试成功</div>
                <div class="text-sm text-green-700 mb-2">{{ testResult.message }}</div>

                <!-- 数据库列表 -->
                <div v-if="testResult.databases?.length" class="space-y-2">
                  <div class="font-medium text-green-800">可用数据库 ({{ testResult.databases.length }}个):</div>
                  <div class="flex flex-wrap gap-1">
                    <Tag
                      v-for="db in testResult.databases.slice(0, 10)"
                      :key="db"
                      :value="db"
                      severity="success"
                      size="small"
                    />
                    <Tag
                      v-if="testResult.databases.length > 10"
                      :value="`+${testResult.databases.length - 10}`"
                      severity="success"
                      size="small"
                    />
                  </div>
                </div>

                <!-- Catalog列表 (Trino) -->
                <div v-if="testResult.catalogs?.length" class="space-y-2 mt-3">
                  <div class="font-medium text-green-800">可用Catalog ({{ testResult.catalogs.length }}个):</div>
                  <div class="flex flex-wrap gap-1">
                    <Tag
                      v-for="catalog in testResult.catalogs"
                      :key="catalog"
                      :value="catalog"
                      severity="info"
                      size="small"
                    />
                  </div>
                </div>

                <div class="text-xs text-green-600 mt-2">
                  测试时间: {{ formatDateTime(testResult.test_time) }}
                </div>
              </div>
            </div>

            <div
              v-else
              class="flex items-start gap-3 p-4 bg-red-50 border border-red-200 rounded-lg"
            >
              <i class="pi pi-times-circle text-red-600 text-xl mt-0.5"></i>
              <div class="flex-1">
                <div class="font-medium text-red-900 mb-1">连接测试失败</div>
                <div class="text-sm text-red-700 mb-2">{{ testResult.message }}</div>
                <div v-if="testResult.error" class="text-sm text-red-600 bg-red-100 p-2 rounded">
                  {{ testResult.error }}
                </div>
                <div class="text-xs text-red-600 mt-2">
                  测试时间: {{ formatDateTime(testResult.test_time) }}
                </div>
              </div>
            </div>
          </div>

          <!-- 历史测试结果 -->
          <div v-else-if="database.test_result" class="p-4 bg-surface-50 rounded-lg">
            <div class="text-sm text-surface-600 mb-2">上次测试结果:</div>
            <div class="text-sm text-surface-900">{{ database.test_result }}</div>
            <div v-if="database.last_test_at" class="text-xs text-surface-500 mt-2">
              测试时间: {{ formatDateTime(database.last_test_at) }}
            </div>
          </div>

          <!-- 未测试状态 -->
          <div v-else class="p-4 bg-surface-50 rounded-lg text-center">
            <i class="pi pi-info-circle text-surface-400 text-2xl mb-2 block"></i>
            <p class="text-surface-600">暂无测试记录，点击上方按钮进行连接测试</p>
          </div>
        </template>
      </Card>

      <!-- 使用统计 -->
      <Card>
        <template #header>
          <div class="p-6 pb-0">
            <h3 class="text-lg font-semibold text-surface-900 flex items-center gap-2">
              <i class="pi pi-chart-bar text-surface-600"></i>
              使用统计
            </h3>
          </div>
        </template>

        <template #content>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="text-center p-4 bg-blue-50 rounded-lg">
              <div class="text-2xl font-bold text-blue-600">0</div>
              <div class="text-sm text-blue-700">关联流程</div>
            </div>
            <div class="text-center p-4 bg-green-50 rounded-lg">
              <div class="text-2xl font-bold text-green-600">0</div>
              <div class="text-sm text-green-700">执行次数</div>
            </div>
            <div class="text-center p-4 bg-purple-50 rounded-lg">
              <div class="text-2xl font-bold text-purple-600">0</div>
              <div class="text-sm text-purple-700">错误次数</div>
            </div>
          </div>

          <div class="mt-4 text-center text-sm text-surface-500">
            <i class="pi pi-info-circle mr-1"></i>
            统计功能正在开发中，敬请期待
          </div>
        </template>
      </Card>
    </div>

    <template #footer>
      <div class="flex justify-end">
        <Button
          @click="dialogVisible = false"
          label="关闭"
          severity="secondary"
          size="small"
        />
      </div>
    </template>
  </Dialog>
</template>


