<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="编辑角色"
    class="w-full max-w-lg"
  >
    <div v-if="role" class="space-y-4">
      <p class="text-surface-600">编辑角色: {{ role.name }}</p>

      <form @submit.prevent="handleUpdate" class="space-y-4">
        <!-- 角色名称（不可编辑系统角色） -->
        <div>
          <FloatLabel variant="on">
            <InputText
              id="editRoleName"
              v-model="editForm.name"
              class="w-full"
              :class="{ 'p-invalid': errors.name }"
              :disabled="role.system_role"
              required
            />
            <label for="editRoleName">角色名称*</label>
          </FloatLabel>
          <small v-if="errors.name" class="p-error">{{ errors.name }}</small>
          <small v-if="role.system_role" class="text-surface-500 text-xs mt-1">系统角色名称不可修改</small>
          <small v-else class="text-surface-500 text-xs mt-1">角色的唯一标识，只能包含字母、数字和下划线</small>
        </div>


        <!-- 描述 -->
        <div>
          <FloatLabel variant="on">
            <Textarea
              id="editDescription"
              v-model="editForm.description"
              class="w-full"
              rows="3"
              :class="{ 'p-invalid': errors.description }"
            />
            <label for="editDescription">描述</label>
          </FloatLabel>
          <small v-if="errors.description" class="p-error">{{ errors.description }}</small>
        </div>

        <!-- 系统角色提示 -->
        <div v-if="role.system_role" class="p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <div class="flex items-center space-x-2">
            <i class="pi pi-info-circle text-primary-600"></i>
            <span class="text-primary-700 text-sm">
              系统角色的权限配置请使用"编辑权限"功能
            </span>
          </div>
        </div>
      </form>
    </div>

    <template #footer>
      <div class="flex justify-end space-x-2">
        <Button
          label="取消"
          @click="visible = false"
          text
        />
        <Button
          label="保存"
          @click="handleUpdate"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import roleApi from '@/api/role-api'
import type { Role } from '@/data/types/user-types'
import type { UpdateRoleRequest } from '@/data/types/role-types'

import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  role: Role | null
}>()

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const editForm = reactive<UpdateRoleRequest>({
  name: '',
  description: ''
})

const errors = ref<Record<string, string>>({})

// Methods
const validateForm = () => {
  errors.value = {}

  if (!editForm.name.trim()) {
    errors.value.name = '角色名称不能为空'
  } else if (!/^[a-zA-Z0-9_]+$/.test(editForm.name)) {
    errors.value.name = '角色名称只能包含字母、数字和下划线'
  }

  // display_name validation removed as it's not in the new API structure

  return Object.keys(errors.value).length === 0
}

const handleUpdate = async () => {
  if (!props.role || !validateForm()) return

  loading.value = true

  try {
    const response = await roleApi.update(props.role.id, editForm)

    toast.add({
      severity: 'success',
      summary: '更新成功',
      detail: response.message || '角色更新成功',
      life: 3000
    })

    visible.value = false
    emit('success')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '更新失败',
      detail: error.message || '更新角色失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Watch
watch(() => props.role, (newRole) => {
  if (newRole) {
    editForm.name = newRole.name
    editForm.description = newRole.description || ''
    errors.value = {}
  }
}, { immediate: true })
</script>
