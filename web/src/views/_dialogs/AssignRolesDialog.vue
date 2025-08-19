<template>
  <Dialog 
    v-model:visible="visible" 
    modal 
    header="分配角色" 
    class="w-full max-w-md"
  >
    <div v-if="user" class="space-y-4">
      <p class="text-surface-600">为用户 "{{ user.name }}" 分配角色</p>
      
      <div class="space-y-2 max-h-64 overflow-y-auto">
        <div 
          v-for="role in availableRoles" 
          :key="role.id"
          class="flex items-center space-x-3 p-3 border border-surface-200 rounded-lg"
        >
          <Checkbox 
            :id="`role-${role.id}`"
            v-model="selectedRoles" 
            :value="role.name"
            binary
          />
          <div class="flex-1">
            <label :for="`role-${role.id}`" class="cursor-pointer font-medium">
              {{ role.display_name }}
            </label>
            <p v-if="role.description" class="text-sm text-surface-500">
              {{ role.description }}
            </p>
            <div class="flex flex-wrap gap-1 mt-1">
              <Tag 
                v-for="permission in role.permissions.slice(0, 3)" 
                :key="permission"
                :value="permission"
                size="small"
                severity="secondary"
              />
              <Tag 
                v-if="role.permissions.length > 3"
                :value="`+${role.permissions.length - 3}`"
                size="small"
                severity="secondary"
              />
            </div>
          </div>
        </div>
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
          @click="handleAssignRoles"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import UserApi from '@/api/user-api'
import type { User } from '@/api/auth-api'
import type { Role } from '@/api/user-api'

import Dialog from 'primevue/dialog'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'
import Tag from 'primevue/tag'

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
const availableRoles = ref<Role[]>([])
const selectedRoles = ref<string[]>([])

// Methods
const loadRoles = async () => {
  try {
    const response = await UserApi.getRoles()
    if (response.code === 200) {
      availableRoles.value = response.data.roles
    }
  } catch (error) {
    console.error('Failed to load roles:', error)
  }
}

const handleAssignRoles = async () => {
  if (!props.user) return
  
  loading.value = true
  
  try {
    const response = await UserApi.assignRoles(props.user.id, {
      roles: selectedRoles.value
    })
    
    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '分配成功',
        detail: response.data.message,
        life: 3000
      })
      
      visible.value = false
      emit('success')
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '分配失败',
      detail: error.message || '角色分配失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Watch
watch(() => props.user, (newUser) => {
  if (newUser) {
    selectedRoles.value = newUser.roles.map(role => role.name)
  }
}, { immediate: true })

watch(visible, (newValue) => {
  if (newValue) {
    loadRoles()
  }
})

// Lifecycle
onMounted(() => {
  loadRoles()
})
</script>