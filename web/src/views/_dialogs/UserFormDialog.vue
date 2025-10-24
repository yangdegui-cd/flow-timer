<template>
  <Dialog
    v-model:visible="visible"
    modal
    :header="mode === 'create' ? '创建用户' : '编辑用户'"
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

      <!-- 密码 - 仅创建模式显示 -->
      <div v-if="mode === 'create'">
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
            :options="USER_STATUS_OPTIONS"
            optionLabel="label"
            optionValue="value"
            class="w-full"
          />
          <label for="status">状态</label>
        </FloatLabel>
      </div>

      <!-- 部门 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="department"
            v-model="form.department"
            class="w-full"
          />
          <label for="department">部门</label>
        </FloatLabel>
      </div>

      <!-- 职位 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="position"
            v-model="form.position"
            class="w-full"
          />
          <label for="position">职位</label>
        </FloatLabel>
      </div>

      <!-- 手机号 -->
      <div>
        <FloatLabel variant="on">
          <InputText
            id="phone"
            v-model="form.phone"
            class="w-full"
          />
          <label for="phone">手机号</label>
        </FloatLabel>
      </div>

      <!-- 角色 -->
      <div v-if="mode === 'create'">
        <label class="block text-sm font-medium text-surface-700 mb-2">角色</label>
        <div class="space-y-2 max-h-32 overflow-y-auto">
          <div
            v-for="role in availableRoles"
            :key="role.id"
            class="flex items-center space-x-2"
          >
            <Checkbox
              :id="`role-${role.id}`"
              v-model="form.role_ids"
              :value="role.id"
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
          size="small"
        />
        <Button
          :label="mode === 'create' ? '创建' : '保存'"
          @click="handleSubmit"
          :loading="loading"
          :disabled="!isFormValid"
          size="small"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { createUserDefaults } from '@/data/defaults'
import { USER_STATUS_OPTIONS } from '@/data/constants'
import { createUser, updateUser, getRoles } from '@/api/user-api'
import type { User, UserFormData, Role } from '@/data/types'

import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import Dropdown from 'primevue/dropdown'
import Checkbox from 'primevue/checkbox'
import FloatLabel from 'primevue/floatlabel'
import Button from 'primevue/button'

// Props & Emits
export interface Props {
  visible?: boolean
  mode?: 'create' | 'edit'
  userData?: Partial<User>
}

const props = withDefaults(defineProps<Props>(), {
  visible: false,
  mode: 'create',
  userData: undefined
})

const visible = defineModel<boolean>('visible', { default: false })

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const availableRoles = ref<Role[]>([])
const form = reactive<UserFormData>(createUserDefaults())

const errors = reactive({
  name: '',
  email: '',
  password: ''
})

// Computed
const isFormValid = computed(() => {
  if (props.mode === 'create') {
    return form.name.trim() &&
           form.email &&
           form.password &&
           !errors.name &&
           !errors.email &&
           !errors.password
  } else {
    return form.name.trim() &&
           form.email &&
           !errors.name &&
           !errors.email
  }
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
  if (props.mode === 'create') {
    if (!form.password) {
      errors.password = '请输入密码'
    } else if (form.password!.length < 6) {
      errors.password = '密码至少6位'
    } else {
      errors.password = ''
    }
  }
}

// Methods
const loadRoles = async () => {
  if (props.mode === 'create') {
    try {
      const roles = await getRoles()
      availableRoles.value = roles
    } catch (error) {
      console.error('Failed to load roles:', error)
    }
  }
}

const handleSubmit = async () => {
  validateName()
  validateEmail()
  if (props.mode === 'create') {
    validatePassword()
  }

  if (!isFormValid.value) return

  loading.value = true

  try {
    if (props.mode === 'create') {
      await createUser(form)
      toast.add({
        severity: 'success',
        summary: '创建成功',
        detail: '用户创建成功',
        life: 3000
      })
    } else {
      const userData = props.userData!
      const updateData = {
        name: form.name,
        email: form.email,
        status: form.status,
        department: form.department,
        position: form.position,
        phone: form.phone
      }
      await updateUser(userData.id!, updateData)
      toast.add({
        severity: 'success',
        summary: '更新成功',
        detail: '用户信息更新成功',
        life: 3000
      })
    }

    visible.value = false
    emit('success')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: props.mode === 'create' ? '创建失败' : '更新失败',
      detail: error.message || '操作失败，请稍后重试',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  Object.assign(form, createUserDefaults())
  errors.name = ''
  errors.email = ''
  errors.password = ''
}

// Watch
watch(() => props.userData, (newUser) => {
  if (newUser && props.mode === 'edit') {
    form.name = newUser.name || ''
    form.email = newUser.email || ''
    form.status = newUser.status || 'active'
    form.department = newUser.department || ''
    form.position = newUser.position || ''
    form.phone = newUser.phone || ''
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