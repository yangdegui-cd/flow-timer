<template>
  <Dialog
    v-model:visible="visible"
    :modal="true"
    :closable="true"
    :draggable="false"
    class="w-full max-w-md"
    header="编辑权限"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4" v-if="permission">
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
          :disabled="permission.is_system"
        />
        <small v-if="errors.code" class="text-red-500">{{ errors.code }}</small>
        <small v-if="permission.is_system" class="text-surface-500">系统权限代码不可修改</small>
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
          :disabled="permission.is_system"
          editable
        />
        <small v-if="errors.module" class="text-red-500">{{ errors.module }}</small>
        <small v-if="permission.is_system" class="text-surface-500">系统权限模块不可修改</small>
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
          :disabled="permission.is_system"
        />
        <small v-if="errors.action" class="text-red-500">{{ errors.action }}</small>
        <small v-if="permission.is_system" class="text-surface-500">系统权限动作不可修改</small>
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

      <!-- 系统权限提示 -->
      <div v-if="permission.is_system" class="bg-blue-50 p-3 rounded-lg">
        <div class="flex items-start space-x-2">
          <i class="pi pi-info-circle text-primary-600 mt-0.5"></i>
          <div class="text-sm text-primary-700">
            <p class="font-medium">系统权限提示</p>
            <p class="mt-1">此为系统自动生成的权限，部分字段不可修改。您可以修改名称、描述、资源标识、排序和状态。</p>
          </div>
        </div>
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
          label="保存"
          @click="handleSubmit"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import systemApi from '@/api/system-api'
import type { SysPermission, UpdatePermissionRequest } from '@/data/types/system-types'

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
  permission: SysPermission | null
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

const formData = reactive<UpdatePermissionRequest>({
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
  if (newVal && props.permission) {
    populateForm()
  }
})

watch(visible, (newVal) => {
  emit('update:visible', newVal)
})

watch(() => props.permission, (newVal) => {
  if (newVal && visible.value) {
    populateForm()
  }
})

// Methods
const populateForm = () => {
  if (!props.permission) return

  formData.code = props.permission.code
  formData.name = props.permission.name
  formData.description = props.permission.description || ''
  formData.module = props.permission.module
  formData.action = props.permission.action
  formData.resource = props.permission.resource || ''
  formData.is_active = props.permission.is_active
  formData.sort_order = props.permission.sort_order

  // 清除错误
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
  return fields.every(field => validateField(field))
}

const handleSubmit = () => {
  if (!props.permission || !validateForm()) {
    return
  }

  loading.value = true

  // 只发送有变化的字段
  const updateData: UpdatePermissionRequest = {}

  if (formData.name !== props.permission.name) {
    updateData.name = formData.name
  }
  if (formData.description !== (props.permission.description || '')) {
    updateData.description = formData.description
  }
  if (formData.resource !== (props.permission.resource || '')) {
    updateData.resource = formData.resource
  }
  if (formData.is_active !== props.permission.is_active) {
    updateData.is_active = formData.is_active
  }
  if (formData.sort_order !== props.permission.sort_order) {
    updateData.sort_order = formData.sort_order
  }

  // 非系统权限可以修改的字段
  if (!props.permission.is_system) {
    if (formData.code !== props.permission.code) {
      updateData.code = formData.code
    }
    if (formData.module !== props.permission.module) {
      updateData.module = formData.module
    }
    if (formData.action !== props.permission.action) {
      updateData.action = formData.action
    }
  }

  systemApi.update(`sys_permission/${props.permission.id}`, updateData).then(data => {
    toast.add({
      severity: 'success',
      summary: '保存成功',
      detail: '权限更新成功',
      life: 3000
    })

    emit('success')
    visible.value = false
  }).catch(error => {
    toast.add({
      severity: 'error',
      summary: '保存失败',
      detail: error.message || '保存权限失败',
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
