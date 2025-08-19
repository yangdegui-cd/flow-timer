<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="创建用户"
    class="w-full max-w-md"
    @hide="resetForm"
  >
    <form @submit.prevent="handleSubmit" class="space-y-4">
      <!-- 姓名 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="name"
            v-model="form.name"
            class="w-full"
            :invalid="!!errors.name"
            @blur="validateName"
          />
          <label for="name">姓名 *</label>
        </FloatLabel>
        <small v-if="errors.name" class="text-red-500">{{ errors.name }}</small>
      </div>

      <!-- 邮箱 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="email"
            v-model="form.email"
            type="email"
            class="w-full"
            :invalid="!!errors.email"
            @blur="validateEmail"
          />
          <label for="email">邮箱地址 *</label>
        </FloatLabel>
        <small v-if="errors.email" class="text-red-500">{{ errors.email }}</small>
      </div>

      <!-- 密码 -->
      <div>
        <FloatLabel variant="on">
          <Password
            id="password"
            v-model="form.password"
            class="w-full"
            :invalid="!!errors.password"
            :feedback="false"
            toggleMask
            @blur="validatePassword"
          />
          <label for="password">密码 *</label>
        </FloatLabel>
        <small v-if="errors.password" class="text-red-500">{{ errors.password }}</small>
        <small v-else class="text-surface-500">至少6位字符</small>
      </div>

      <!-- 状态 -->
      <div>
        <FloatLabel variant="on">
          <Dropdown
            id="status"
            v-model="form.status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            class="w-full"
          />
          <label for="status">状态</label>
        </FloatLabel>
      </div>

      <!-- 角色 -->
      <div>
        <label class="block text-sm font-medium text-surface-700 mb-2">角色</label>
        <div class="space-y-2 max-h-32 overflow-y-auto">
          <div
            v-for="role in availableRoles"
            :key="role.id"
            class="flex items-center space-x-2"
          >
            <Checkbox
              :id="`role-${role.id}`"
              v-model="form.roles"
              :value="role.name"
              binary
            />
            <label :for="`role-${role.id}`" class="cursor-pointer">
              <span class="font-medium">{{ role.display_name }}</span>
              <span v-if="role.description" class="text-sm text-surface-500 ml-2">
                - {{ role.description }}
              </span>
            </label>
          </div>
        </div>
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
          @click="handleSubmit"
          :loading="loading"
          :disabled="!isFormValid"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import UserApi, { type CreateUserRequest } from '@/api/user-api'
import type { Role } from '@/api/user-api'

import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import Dropdown from 'primevue/dropdown'
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
const availableRoles = ref<Role[]>([])

const form = reactive({
  name: '',
  email: '',
  password: '',
  status: 'active' as 'active' | 'inactive' | 'suspended',
  roles: [] as string[]
})

const errors = reactive({
  name: '',
  email: '',
  password: ''
})

const statusOptions = [
  { label: '活跃', value: 'active' },
  { label: '非活跃', value: 'inactive' },
  { label: '已禁用', value: 'suspended' }
]

// Computed
const isFormValid = computed(() => {
  return form.name.trim() &&
         form.email &&
         form.password &&
         !errors.name &&
         !errors.email &&
         !errors.password
})

// Validation
const validateName = () => {
  if (!form.name.trim()) {
    errors.name = '请输入姓名'
  } else if (form.name.trim().length < 2) {
    errors.name = '姓名至少2个字符'
  } else {
    errors.name = ''
  }
}

const validateEmail = () => {
  if (!form.email) {
    errors.email = '请输入邮箱地址'
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = '请输入有效的邮箱地址'
  } else {
    errors.email = ''
  }
}

const validatePassword = () => {
  if (!form.password) {
    errors.password = '请输入密码'
  } else if (form.password.length < 6) {
    errors.password = '密码至少6位'
  } else {
    errors.password = ''
  }
}

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

const handleSubmit = async () => {
  validateName()
  validateEmail()
  validatePassword()

  if (!isFormValid.value) return

  loading.value = true

  try {
    const data: CreateUserRequest = {
      name: form.name.trim(),
      email: form.email,
      password: form.password,
      status: form.status,
      roles: form.roles.length > 0 ? form.roles : ['viewer'] // 默认分配viewer角色
    }

    const response = await UserApi.create(data)

    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: '创建成功',
        detail: response.data.message,
        life: 3000
      })

      visible.value = false
      emit('success')
    } else {
      toast.add({
        severity: 'error',
        summary: '创建失败',
        detail: response.msg || '创建用户失败',
        life: 5000
      })
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '创建失败',
      detail: error.message || '网络错误，请稍后重试',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  form.name = ''
  form.email = ''
  form.password = ''
  form.status = 'active'
  form.roles = []

  errors.name = ''
  errors.email = ''
  errors.password = ''
}

// Lifecycle
onMounted(() => {
  loadRoles()
})

// Watch
watch(visible, (newValue) => {
  if (newValue) {
    loadRoles()
  }
})
</script>
