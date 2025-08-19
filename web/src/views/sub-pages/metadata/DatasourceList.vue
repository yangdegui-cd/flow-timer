<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import type { Database } from '@/data/types/database-types'
import { DATABASE_STATUS_CONFIG, DATABASE_TYPE_OPTIONS, DATABASE_TYPES } from '@/data/constants/database-constants'

import Card from 'primevue/card'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Tag from 'primevue/tag'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import ProgressSpinner from 'primevue/progressspinner'

import DatabaseFormDialog from '@/views/_dialogs/DatasourceFormDialog.vue'
import DatabaseDetailDialog from '@/views/_dialogs/DatasourceDetailDialog.vue'
import PageHeader from '@/views/layer/PageHeader.vue'
import { ApiDelete, ApiList, ApiRequest } from "@/api/base-api";

// Services
const confirm = useConfirm()
const toast = useToast()

// Data
const datasource = ref<Database[]>([])
const loading = ref(false)
const testingIds = ref<number[]>([])
const selectedDatabase = ref<Database | null>(null)

const pagination = reactive({
  current_page: 1,
  per_page: 12,
  total_count: 0,
  total_pages: 0
})

const filters = reactive({
  search: '',
  db_type: '',
  status: ''
})

// Dialogs
const showFormDialog = ref(false)
const showDetailDialog = ref(false)
const formMode = ref<'create' | 'edit'>('create')

// Options
const databaseTypeOptions = DATABASE_TYPE_OPTIONS
const statusOptions = Object.entries(DATABASE_STATUS_CONFIG).map(([key, config]) => ({
  label: config.label,
  value: key
}))

// Methods
const loadDatabases = () => {
  loading.value = true

  const params = {}
  if (filters.db_type) params['db_type'] = filters.db_type
  if (filters.status) params['status'] = filters.status

  ApiList("meta_datasource", params)
      .then((response) => {
        datasource.value = response
      })
      .catch((error) => {
        toast.add({
          severity: 'error',
          summary: '加载失败',
          detail: error.message || '获取数据库连接列表失败',
          life: 5000
        })
      })
      .finally(() => {
        loading.value = false
      })
}

const refreshDatabases = () => {
  loadDatabases()
}

const handleSearch = () => {
  // 延迟搜索
  setTimeout(() => {
    loadDatabases()
  }, 300)
}

// Database actions
const viewDatabase = (database: Database) => {
  selectedDatabase.value = database
  showDetailDialog.value = true
}

const createDatabase = () => {
  selectedDatabase.value = null
  formMode.value = 'create'
  showFormDialog.value = true
}

const editDatabase = (database: Database) => {
  selectedDatabase.value = database
  formMode.value = 'edit'
  showFormDialog.value = true
}

const testConnection = async (database: Database) => {
  if (!database.id) return

  ApiRequest("GET", 'meta_datasource/test_connection/', {}, { id: database.id })
      .then((result) => {
        toast.add({ severity: 'success', summary: '连接测试成功', life: 3000 })
      }).catch(err => {
    toast.add({ severity: 'error', summary: err.msg, life: 3000 })
  }).finally(loadDatabases)
}

const deleteDatabase = (database: Database) => {
  confirm.require({
    message: `确定要删除数据库连接 "${database.name}" 吗？此操作不可恢复。`,
    header: '删除数据库连接',
    icon: 'pi pi-trash',
    rejectLabel: '取消',
    acceptLabel: '删除',
    acceptClass: 'p-button-danger',
    accept: async () => {
      const response = ApiDelete("meta_datasource", database.id!)
          .then(_ => {
            toast.add({ severity: 'success', summary: '删除成功', life: 3000 })
          }).catch(err => {
            toast.add({ severity: 'error', summary: err.msg, life: 5000 })
          }).finally(loadDatabases)
    }
  })
}

// Helpers
const getDatabaseTypeConfig = (type: string) => {
  return DATABASE_TYPES[type as keyof typeof DATABASE_TYPES] || DATABASE_TYPES.mysql
}

const getStatusConfig = (status: string) => {
  return DATABASE_STATUS_CONFIG[status as keyof typeof DATABASE_STATUS_CONFIG] || DATABASE_STATUS_CONFIG.inactive
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

// Lifecycle
onMounted(() => {
  loadDatabases()
})
</script>
<template>
  <div class="h-full flex flex-col bg-gray-50 w-full">
    <!-- 页面头部 -->
    <PageHeader
      title="SQL数据库源"
      description="管理SQL数据库连接配置，支持MySQL、Oracle、Hive等多种数据库类型"
      icon="pi pi-database"
      icon-color="text-purple-600"
    >
      <template #actions>
        <!-- 搜索框 -->
        <IconField>
          <InputIcon>
            <i class="pi pi-search"/>
          </InputIcon>
          <InputText
              v-model="filters.search"
              placeholder="搜索数据库连接..."
              @input="handleSearch"
              class="w-64"
          />
        </IconField>

        <!-- 类型筛选 -->
        <Dropdown
            v-model="filters.db_type"
            :options="databaseTypeOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="类型筛选"
            @change="loadDatabases"
            class="w-40"
            showClear
        >
          <template #option="slotProps">
            <div class="flex items-center gap-2">
              <i :class="slotProps.option.icon" :style="{ color: slotProps.option.color }"></i>
              <span>{{ slotProps.option.label }}</span>
            </div>
          </template>
        </Dropdown>

        <!-- 状态筛选 -->
        <Dropdown
            v-model="filters.status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="状态筛选"
            @change="loadDatabases"
            class="w-32"
            showClear
        />

        <!-- 新增按钮 -->
        <Button
            @click="createDatabase"
            icon="pi pi-plus"
            label="新增连接"
            size="small"
        />

        <!-- 刷新按钮 -->
        <Button
            icon="pi pi-refresh"
            severity="secondary"
            variant="outlined"
            size="small"
            :loading="loading"
            @click="loadDatabases"
            v-tooltip.top="'刷新列表'"/>
      </template>
    </PageHeader>

    <!-- 数据库连接卡片网格 -->
    <div class="flex-1 p-6">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <Card
            v-for="database in datasource"
            :key="database.id"
            class="database-card hover:shadow-lg transition-all cursor-pointer group"
        >
          <template #header>
            <div class="p-6 pb-0">
              <div class="flex items-center justify-between mb-4">
                <div class="flex items-center space-x-3">
                  <div
                      class="w-12 h-12 rounded-lg flex items-center justify-center group-hover:scale-105 transition-transform"
                      :style="{ backgroundColor: `${getDatabaseTypeConfig(database.db_type).color}20` }"
                  >
                    <i
                        :class="getDatabaseTypeConfig(database.db_type).icon"
                        class="text-xl"
                        :style="{ color: getDatabaseTypeConfig(database.db_type).color }"
                    ></i>
                  </div>
                  <div>
                    <h3 class="font-semibold text-lg text-surface-900">{{ database.name }}</h3>
                    <p class="text-sm text-surface-500">{{ getDatabaseTypeConfig(database.db_type).label }}</p>
                  </div>
                </div>

                <Tag
                    :value="getStatusConfig(database.status || 'inactive').label"
                    :severity="getStatusConfig(database.status || 'inactive').severity"
                    size="small"
                />
              </div>
            </div>
          </template>

          <template #content>
            <div class="space-y-4">
              <!-- 连接信息 -->
              <div class="text-sm text-surface-600">
                <div class="flex items-center gap-2 mb-2">
                  <i class="pi pi-server text-surface-400"></i>
                  <span>{{ database.host }}:{{ database.port }}</span>
                </div>
                <div class="flex items-center gap-2 mb-2">
                  <i class="pi pi-user text-surface-400"></i>
                  <span>{{ database.username }}</span>
                </div>
                <div v-if="database.description" class="text-surface-500 mt-2">
                  {{ database.description }}
                </div>
              </div>

              <!-- 最后测试时间 -->
              <div v-if="database.last_test_at" class="text-xs text-surface-400">
                最后测试: {{ formatDateTime(database.last_test_at) }}
              </div>
            </div>
          </template>

          <template #footer>
            <div class="flex justify-between items-center">
              <div class="flex items-center space-x-1">
                <Button
                    @click="viewDatabase(database)"
                    icon="pi pi-eye"
                    size="small"
                    text
                    rounded
                    v-tooltip.top="'查看详情'"
                />

                <Button
                    @click="testConnection(database)"
                    icon="pi pi-check-circle"
                    size="small"
                    text
                    rounded
                    :loading="testingIds.includes(database.id!)"
                    v-tooltip.top="'测试连接'"
                />

                <Button
                    @click="editDatabase(database)"
                    icon="pi pi-pencil"
                    size="small"
                    text
                    rounded
                    v-tooltip.top="'编辑连接'"
                />

                <Button
                    @click="deleteDatabase(database)"
                    icon="pi pi-trash"
                    size="small"
                    text
                    rounded
                    severity="danger"
                    v-tooltip.top="'删除连接'"
                />
              </div>

              <div class="text-xs text-surface-400">
                ID: {{ database.id }}
              </div>
            </div>
          </template>
        </Card>

        <!-- 空状态 -->
        <div v-if="datasource.length === 0 && !loading" class="col-span-full">
          <Card class="text-center py-12">
            <template #content>
              <i class="pi pi-database text-4xl text-surface-400 mb-4 block"></i>
              <p class="text-surface-500 text-lg mb-4">暂无数据库连接</p>
              <Button
                  @click="createDatabase"
                  icon="pi pi-plus"
                  label="创建第一个连接"
                  size="small"
              />
            </template>
          </Card>
        </div>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <ProgressSpinner size="50" strokeWidth="4"/>
    </div>

    <!-- 对话框组件 -->
    <DatabaseFormDialog
        v-model:visible="showFormDialog"
        :database="selectedDatabase"
        :mode="formMode"
        @success="refreshDatabases"
    />

    <DatabaseDetailDialog
        v-model:visible="showDetailDialog"
        :database="selectedDatabase"
    />
  </div>
</template>

<style scoped>
.database-card {
  transition: all 0.2s ease;
}

.database-card:hover {
  transform: translateY(-2px);
}
</style>
