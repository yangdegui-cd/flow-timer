<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import systemApi from '@/api/system-api'
import type { CreatePermissionRequest } from '@/data/types/system-types'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Select from 'primevue/select'
import ToggleSwitch from 'primevue/toggleswitch'

// Props & Emits
const props = defineProps<{
  visible: boolean
}>()

const emit = defineEmits<{
  'update:visible': [visible: boolean]
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const visible = ref(props.visible)

const formData = reactive<CreatePermissionRequest>({
  code: '',
  name: '',
  description: '',
  module: '',
  action: '',
  resource: '',
  is_active: true,
  sort_order: 0
})

const errors = reactive<Record<string, string>>({})

// Options
const moduleOptions = [
  { label: '用户管理', value: 'user' },
  { label: '角色管理', value: 'role' },
  { label: '权限管理', value: 'permission' },
  { label: '任务管理', value: 'task' },
  { label: '流程管理', value: 'flow' },
  { label: '执行管理', value: 'execution' },
  { label: '任务执行', value: 'taskexecution' },
  { label: '流程执行', value: 'flowexecution' },
  { label: '目录管理', value: 'catalog' },
  { label: '空间管理', value: 'space' },
  { label: '数据源', value: 'datasource' },
  { label: '监控管理', value: 'monitor' },
  { label: '系统管理', value: 'system' }
]

const actionOptions = [
  { label: '读取', value: 'read' },
  { label: '写入', value: 'write' },
  { label: '查看', value: 'view' },
  { label: '创建', value: 'create' },
  { label: '更新', value: 'update' },
  { label: '删除', value: 'delete' },
  { label: '执行', value: 'execute' },
  { label: '管理', value: 'manage' },
  { label: '分配', value: 'assign' },
  { label: '配置', value: 'config' },
  { label: '监控', value: 'monitor' },
  { label: '备份', value: 'backup' },
  { label: '日志', value: 'logs' },
  { label: '发布', value: 'publish' },
  { label: '重试', value: 'retry' },
  { label: '停止', value: 'stop' }
]

// Watchers
watch(() => props.visible, (newVal) => {
  visible.value = newVal
  if (newVal) {
    resetForm()
  }
})

watch(visible, (newVal) => {
  emit('update:visible', newVal)
})

// Methods
const resetForm = () => {
  Object.keys(formData).forEach(key => {
    if (key === 'is_active') {
      formData[key] = true
    } else if (key === 'sort_order') {
      formData[key] = 0
    } else {
      formData[key] = ''
    }
  })
  Object.keys(errors).forEach(key => delete errors[key])
}

const validateField = (field: string): boolean => {
  delete errors[field]

  switch (field) {
    case 'code':
      if (!formData.code) {
        errors[field] = '请输入权限代码'
      } else if (!/^[a-zA-Z0-9_:]+$/.test(formData.code)) {
        errors[field] = '权限代码只能包含字母、数字、下划线和冒号'
      }
      break

    case 'name':
      if (!formData.name) {
        errors[field] = '请输入权限名称'
      }
      break

    case 'module':
      if (!formData.module) {
        errors[field] = '请选择所属模块'
      }
      break

    case 'action':
      if (!formData.action) {
        errors[field] = '请选择动作类型'
      }
      break
  }

  return !errors[field]
}

const validateForm = (): boolean => {
  const fields = ['code', 'name', 'module', 'action']
  const isValid = fields.every(field => validateField(field))
  return isValid
}

const handleSubmit = () => {
  if (!validateForm()) {
    return
  }

  loading.value = true

  systemApi.post('sys_permission', formData).then(data => {
    toast.add({
      severity: 'success',
      summary: '创建成功',
      detail: '权限创建成功',
      life: 3000
    })

    emit('success')
    visible.value = false
  }).catch(error => {
    toast.add({
      severity: 'error',
      summary: '创建失败',
      detail: error.message || '创建权限失败',
      life: 5000
    })
  }).finally(() => {
    loading.value = false
  })
}

const handleCancel = () => {
  visible.value = false
}
</script>
<template>
  <Dialog
    v-model:visible="visible"
    :modal="true"
    :closable="true"
    :draggable="false"
    class="w-full max-w-md"
    header="新增权限"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- 权限代码 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          权限代码 *
        </label>
        <InputText
          v-model="formData.code"
          placeholder="例如: user:create"
          :invalid="!!errors.code"
          class="w-full"
          @blur="validateField('code')"
        />
        <small v-if="errors.code" class="text-red-500">{{ errors.code }}</small>
        <small class="text-surface-500">格式: 模块名:动作名，如 user:create</small>
      </div>

      <!-- 权限名称 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          权限名称 *
        </label>
        <InputText
          v-model="formData.name"
          placeholder="例如: 创建用户"
          :invalid="!!errors.name"
          class="w-full"
          @blur="validateField('name')"
        />
        <small v-if="errors.name" class="text-red-500">{{ errors.name }}</small>
      </div>

      <!-- 模块 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          所属模块 *
        </label>
        <Select
          v-model="formData.module"
          :options="moduleOptions"
          optionLabel="label"
          optionValue="value"
          placeholder="选择模块"
          :invalid="!!errors.module"
          class="w-full"
          @change="validateField('module')"
          editable
        />
        <small v-if="errors.module" class="text-red-500">{{ errors.module }}</small>
      </div>

      <!-- 动作类型 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          动作类型 *
        </label>
        <Select
          v-model="formData.action"
          :options="actionOptions"
          optionLabel="label"
          optionValue="value"
          placeholder="选择动作类型"
          :invalid="!!errors.action"
          class="w-full"
          @change="validateField('action')"
        />
        <small v-if="errors.action" class="text-red-500">{{ errors.action }}</small>
      </div>

      <!-- 描述 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          描述
        </label>
        <Textarea
          v-model="formData.description"
          placeholder="权限的详细描述"
          rows="3"
          class="w-full"
        />
      </div>

      <!-- 资源标识 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          资源标识
        </label>
        <InputText
          v-model="formData.resource"
          placeholder="例如: users, tasks"
          class="w-full"
        />
        <small class="text-surface-500">可选，用于更精确的权限控制</small>
      </div>

      <!-- 排序 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">
          排序
        </label>
        <InputNumber
          v-model="formData.sort_order"
          :min="0"
          :max="999"
          placeholder="0"
          class="w-full"
        />
      </div>

      <!-- 状态开关 -->
      <div class="flex items-center justify-between">
        <label class="text-sm font-medium text-surface-700">
          启用权限
        </label>
        <ToggleSwitch v-model="formData.is_active" />
      </div>
    </form>

    <template #footer>
      <div class="flex justify-end space-x-3">
        <Button
          label="取消"
          severity="secondary"
          @click="handleCancel"
          :disabled="loading"
        />
        <Button
          label="创建"
          @click="handleSubmit"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>
<style scoped>
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
