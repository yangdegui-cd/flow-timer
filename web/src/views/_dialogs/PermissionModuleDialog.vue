<template>
  <Dialog
    v-model:visible="visible"
    :modal="true"
    :closable="true"
    :draggable="false"
    class="w-full max-w-4xl max-h-[90vh]"
    :header="`${moduleDisplayName} - 权限详情`"
  >
    <div class="space-y-4">
      <!-- 统计信息 -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-surface-50 rounded-lg">
        <div class="text-center">
          <div class="text-2xl font-bold text-primary-600">{{ permissions.length }}</div>
          <div class="text-sm text-surface-600">总权限</div>
        </div>
        <div class="text-center">
          <div class="text-2xl font-bold text-primary-600">{{ readPermissions }}</div>
          <div class="text-sm text-surface-600">读取权限</div>
        </div>
        <div class="text-center">
          <div class="text-2xl font-bold text-green-600">{{ writePermissions }}</div>
          <div class="text-sm text-surface-600">写入权限</div>
        </div>
        <div class="text-center">
          <div class="text-2xl font-bold text-red-600">{{ executePermissions }}</div>
          <div class="text-sm text-surface-600">执行权限</div>
        </div>
      </div>

      <!-- 搜索和筛选 -->
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="flex-1">
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText
              v-model="searchQuery"
              placeholder="搜索权限..."
              class="w-full"
            />
          </IconField>
        </div>
        <div>
          <Select
            v-model="filterAction"
            :options="actionFilterOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="筛选动作"
            class="w-40"
            showClear
          />
        </div>
      </div>

      <!-- 权限列表 -->
      <div class="border rounded-lg overflow-hidden">
        <DataTable
          :value="filteredPermissions"
          :paginator="true"
          :rows="10"
          :rowsPerPageOptions="[10, 20, 50]"
          :loading="false"
          stripedRows
          class="permission-table"
          :globalFilterFields="['code', 'name', 'description']"
          :scrollable="true"
          scrollHeight="400px"
        >
          <template #empty>
            <div class="text-center py-8">
              <i class="pi pi-search text-4xl text-surface-400 mb-4 block"></i>
              <p class="text-surface-500">没有找到匹配的权限</p>
            </div>
          </template>

          <Column field="code" header="权限代码" :sortable="true" class="min-w-48">
            <template #body="{ data }">
              <code class="text-sm bg-surface-100 px-2 py-1 rounded">{{ data.code }}</code>
            </template>
          </Column>

          <Column field="name" header="权限名称" :sortable="true" class="min-w-32">
            <template #body="{ data }">
              <span class="font-medium">{{ data.name }}</span>
            </template>
          </Column>

          <Column field="action" header="动作类型" :sortable="true" class="min-w-24">
            <template #body="{ data }">
              <Tag
                :value="getActionLabel(data.action)"
                :severity="getActionSeverity(data.action)"
                size="small"
              />
            </template>
          </Column>

          <Column field="description" header="描述" class="min-w-48">
            <template #body="{ data }">
              <span class="text-sm text-surface-600">{{ data.description || '暂无描述' }}</span>
            </template>
          </Column>

          <Column field="is_system" header="类型" :sortable="true" class="min-w-20">
            <template #body="{ data }">
              <Tag
                :value="data.is_system ? '系统' : '自定义'"
                :severity="data.is_system ? 'info' : 'secondary'"
                size="small"
              />
            </template>
          </Column>

          <Column field="is_active" header="状态" :sortable="true" class="min-w-20">
            <template #body="{ data }">
              <Tag
                :value="data.is_active ? '启用' : '禁用'"
                :severity="data.is_active ? 'success' : 'danger'"
                size="small"
              />
            </template>
          </Column>

          <Column header="操作" class="min-w-32">
            <template #body="{ data }">
              <div class="flex space-x-2">
                <Button
                  @click="$emit('edit', data)"
                  icon="pi pi-pencil"
                  size="small"
                  text
                  rounded
                  tooltip="编辑"
                  v-if="!data.is_system"
                />

                <Button
                  @click="$emit('delete', data)"
                  icon="pi pi-trash"
                  size="small"
                  text
                  rounded
                  severity="danger"
                  tooltip="删除"
                  v-if="!data.is_system"
                />

                <Button
                  @click="copyPermissionCode(data.code)"
                  icon="pi pi-copy"
                  size="small"
                  text
                  rounded
                  tooltip="复制代码"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between">
        <div class="flex space-x-2">
          <Button
            @click="exportPermissions"
            icon="pi pi-download"
            label="导出权限"
            severity="secondary"
            size="small"
          />
        </div>
        <Button
          label="关闭"
          severity="secondary"
          @click="visible = false"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import type { SysPermission } from '@/data/types/permission-types'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Select from 'primevue/select'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'

// Props & Emits
const props = defineProps<{
  visible: boolean
  moduleName: string
  permissions: SysPermission[]
}>()

const emit = defineEmits<{
  'update:visible': [visible: boolean]
  edit: [permission: SysPermission]
  delete: [permission: SysPermission]
}>()

// Services
const toast = useToast()

// Data
const visible = ref(props.visible)
const searchQuery = ref('')
const filterAction = ref('')

// Computed
const moduleDisplayName = computed(() => {
  const moduleNames: Record<string, string> = {
    user: '用户管理',
    role: '角色管理',
    task: '任务管理',
    flow: '流程管理',
    execution: '执行管理',
    taskexecution: '任务执行',
    flowexecution: '流程执行',
    catalog: '目录管理',
    space: '空间管理',
    datasource: '数据源',
    monitor: '监控管理',
    permission: '权限管理',
    system: '系统管理'
  }
  return moduleNames[props.moduleName] || props.moduleName
})

const filteredPermissions = computed(() => {
  let result = [...props.permissions]

  // 搜索筛选
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(p =>
      p.code.toLowerCase().includes(query) ||
      p.name.toLowerCase().includes(query) ||
      (p.description && p.description.toLowerCase().includes(query))
    )
  }

  // 动作筛选
  if (filterAction.value) {
    result = result.filter(p => p.action === filterAction.value)
  }

  // 按代码排序
  result.sort((a, b) => a.code.localeCompare(b.code))

  return result
})

const readPermissions = computed(() =>
  props.permissions.filter(p => ['read', 'view'].includes(p.action)).length
)

const writePermissions = computed(() =>
  props.permissions.filter(p => ['create', 'update', 'write'].includes(p.action)).length
)

const executePermissions = computed(() =>
  props.permissions.filter(p => ['delete', 'execute'].includes(p.action)).length
)

const actionFilterOptions = computed(() => {
  const actions = [...new Set(props.permissions.map(p => p.action))].sort()
  return actions.map(action => ({
    label: getActionLabel(action),
    value: action
  }))
})

// Watchers
watch(() => props.visible, (newVal) => {
  visible.value = newVal
  if (newVal) {
    searchQuery.value = ''
    filterAction.value = ''
  }
})

watch(visible, (newVal) => {
  emit('update:visible', newVal)
})

// Methods
const getActionLabel = (action: string): string => {
  const actionLabels: Record<string, string> = {
    read: '读取',
    write: '写入',
    view: '查看',
    create: '创建',
    update: '更新',
    delete: '删除',
    execute: '执行',
    manage: '管理',
    assign: '分配',
    backup: '备份',
    config: '配置',
    logs: '日志',
    monitor: '监控',
    publish: '发布',
    retry: '重试',
    stop: '停止'
  }
  return actionLabels[action] || action
}

const getActionSeverity = (action: string): string => {
  const severityMap: Record<string, string> = {
    read: 'info',
    write: 'warning',
    view: 'info',
    create: 'success',
    update: 'warning',
    delete: 'danger',
    execute: 'danger',
    manage: 'warning',
    assign: 'warning',
    backup: 'secondary',
    config: 'warning',
    logs: 'info',
    monitor: 'info',
    publish: 'success',
    retry: 'warning',
    stop: 'danger'
  }
  return severityMap[action] || 'secondary'
}

const copyPermissionCode = async (code: string) => {
  try {
    await navigator.clipboard.writeText(code)
    toast.add({
      severity: 'success',
      summary: '复制成功',
      detail: `已复制权限代码: ${code}`,
      life: 2000
    })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '复制失败',
      detail: '无法访问剪贴板',
      life: 3000
    })
  }
}

const exportPermissions = () => {
  const data = filteredPermissions.value.map(p => ({
    权限代码: p.code,
    权限名称: p.name,
    描述: p.description || '',
    动作类型: p.action,
    系统权限: p.is_system ? '是' : '否',
    状态: p.is_active ? '启用' : '禁用',
    排序: p.sort_order
  }))

  const csv = [
    Object.keys(data[0]).join(','),
    ...data.map(row => Object.values(row).map(v => `"${v}"`).join(','))
  ].join('\n')

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${moduleDisplayName.value}_permissions.csv`
  link.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
:deep(.permission-table .p-datatable-thead > tr > th) {
  background: var(--surface-100);
  font-weight: 600;
  font-size: 0.875rem;
}

:deep(.permission-table .p-datatable-tbody > tr:hover) {
  background: var(--surface-50);
}

:deep(.p-dialog-header) {
  padding: 1.5rem 1.5rem 0;
}

:deep(.p-dialog-content) {
  padding: 1.5rem;
}

:deep(.p-dialog-footer) {
  padding: 0 1.5rem 1.5rem;
}
</style>
