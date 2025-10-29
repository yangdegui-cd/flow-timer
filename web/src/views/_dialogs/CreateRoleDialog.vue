<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useToast } from 'primevue/usetoast'
import roleApi from '@/api/role-api'
import type { CreateRoleRequest } from '@/data/types/role-types'

import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Checkbox from 'primevue/checkbox'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const form = reactive<CreateRoleRequest>({
  name: '',
  description: '',
  permissions: []
})

const errors = ref<Record<string, string>>({})

// 权限分组
const permissionGroups = {
  '用户管理': [
    { key: 'manage_users', label: '管理用户' },
    { key: 'manage_roles', label: '管理角色' }
  ],
  '任务管理': [
    { key: 'view_tasks', label: '查看任务' },
    { key: 'create_tasks', label: '创建任务' },
    { key: 'edit_tasks', label: '编辑任务' },
    { key: 'delete_tasks', label: '删除任务' },
    { key: 'manage_tasks', label: '完全管理任务' }
  ],
  '流程管理': [
    { key: 'view_flows', label: '查看流程' },
    { key: 'create_flows', label: '创建流程' },
    { key: 'edit_flows', label: '编辑流程' },
    { key: 'delete_flows', label: '删除流程' },
    { key: 'manage_flows', label: '完全管理流程' }
  ],
  '执行管理': [
    { key: 'view_executions', label: '查看执行记录' },
    { key: 'manage_executions', label: '管理执行' }
  ],
  '系统管理': [
    { key: 'view_resque_monitor', label: '查看队列监控' },
    { key: 'manage_system', label: '系统管理' }
  ]
}

// Methods
const validateForm = () => {
  errors.value = {}

  if (!form.name.trim()) {
    errors.value.name = '角色名称不能为空'
  } else if (!/^[a-zA-Z0-9_]+$/.test(form.name)) {
    errors.value.name = '角色名称只能包含字母、数字和下划线'
  }

  // display_name validation removed as it's not in the new API structure

  if (form.permissions.length === 0) {
    errors.value.permissions = '请至少选择一个权限'
  }

  return Object.keys(errors.value).length === 0
}

const handleCreate = async () => {
  if (!validateForm()) return

  loading.value = true

  try {
    const response = await roleApi.create(form)

    toast.add({
      severity: 'success',
      summary: '创建成功',
      detail: response.message || '角色创建成功',
      life: 3000
    })

    // 重置表单
    Object.assign(form, {
      name: '',
      description: '',
      permissions: []
    })
    errors.value = {}

    visible.value = false
    emit('success')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '创建失败',
      detail: error.message || '创建角色失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}
</script>
<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="创建角色"
    class="w-full max-w-lg"
  >
    <form @submit.prevent="handleCreate" class="space-y-4">
      <!-- 角色名称 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="roleName"
            v-model="form.name"
            class="w-full"
            :class="{ 'p-invalid': errors.name }"
            required
          />
          <label for="roleName">角色名称*</label>
        </FloatLabel>
        <small v-if="errors.name" class="p-error">{{ errors.name }}</small>
        <small class="text-surface-500 text-xs mt-1">角色的唯一标识，只能包含字母、数字和下划线</small>
      </div>


      <!-- 描述 -->
      <div>
        <FloatLabel variant="on">
          <Textarea
            id="description"
            v-model="form.description"
            class="w-full"
            rows="3"
            :class="{ 'p-invalid': errors.description }"
          />
          <label for="description">描述</label>
        </FloatLabel>
        <small v-if="errors.description" class="p-error">{{ errors.description }}</small>
      </div>

      <!-- 权限选择 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">权限设置*</label>
        <div class="border border-surface-200 rounded-lg p-4 max-h-64 overflow-y-auto">
          <div class="space-y-3">
            <div v-for="(group, groupName) in permissionGroups" :key="groupName">
              <div class="font-medium text-surface-700 mb-2">{{ groupName }}</div>
              <div class="grid grid-cols-1 gap-2 ml-4">
                <div
                  v-for="permission in group"
                  :key="permission.key"
                  class="flex items-center space-x-2"
                >
                  <Checkbox
                    :id="`permission-${permission.key}`"
                    v-model="form.permissions"
                    :value="permission.key"
                    binary
                  />
                  <label :for="`permission-${permission.key}`" class="text-sm cursor-pointer">
                    {{ permission.label }}
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
        <small v-if="errors.permissions" class="p-error">{{ errors.permissions }}</small>
      </div>
    </form>

    <template #footer>
      <div class="flex justify-end space-x-2">
        <Button
          label="取消"
          @click="visible = false"
          text
        />
        <Button
          label="创建"
          @click="handleCreate"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

