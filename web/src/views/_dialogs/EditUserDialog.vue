<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="编辑用户"
    class="w-full max-w-md"
  >
    <div v-if="user" class="space-y-4">
      <p class="text-surface-600">编辑用户: {{ user.name }}</p>

      <!-- 简化的编辑表单 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="editName"
            v-model="editForm.name"
            class="w-full"
          />
          <label for="editName">姓名</label>
        </FloatLabel>
      </div>

      <div>
        <FloatLabel variant="on">
          <Dropdown
            id="editStatus"
            v-model="editForm.status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            class="w-full"
          />
          <label for="editStatus">状态</label>
        </FloatLabel>
      </div>
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
import  from '@/api/user-api'
import type { User } from '@/api/auth-api'

import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  user: User | null
}>()

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const editForm = reactive({
  name: '',
  status: 'active' as 'active' | 'inactive' | 'suspended'
})

const statusOptions = [
  { label: '活跃', value: 'active' },
  { label: '非活跃', value: 'inactive' },
  { label: '已禁用', value: 'suspended' }
]

// Methods
const handleUpdate = async () => {
  if (!props.user) return

  loading.value = true

  try {
    const response = await .update(props.user.id, editForm)

    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '更新成功',
        detail: response.data.message,
        life: 3000
      })

      visible.value = false
      emit('success')
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '更新失败',
      detail: error.message || '更新用户失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Watch
watch(() => props.user, (newUser) => {
  if (newUser) {
    editForm.name = newUser.name
    editForm.status = newUser.status as any
  }
}, { immediate: true })
</script>
