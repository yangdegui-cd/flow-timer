<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue'
import userApi from '@/api/user-api'
import projectApi, { projectRoleOptions } from '@/api/project-api'
import type { Project, SysUser } from '@/data/types/project-types'
import { useToast } from 'primevue/usetoast'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import MultiSelect from 'primevue/multiselect'
import RadioButton from 'primevue/radiobutton'
import Tag from 'primevue/tag'
import Badge from 'primevue/badge'
import Avatar from 'primevue/avatar'

interface Props {
  visible: boolean
  project?: Project | null
}

interface Emits {
  (e: 'update:visible', value: boolean): void
  (e: 'assigned'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const toast = useToast()

const users = ref<SysUser[]>([])
const selectedUserIds = ref<number[]>([])
const selectedRole = ref('member')
const loading = ref(false)
const loadingUsers = ref(false)

const dialogTitle = computed(() => {
  return props.project ? `分配用户到项目: ${props.project.name}` : '分配用户到项目'
})

const selectedUsersCount = computed(() => {
  return selectedUserIds.value.length
})

const loadUsers = () => {
  loadingUsers.value = true
  userApi.list().then(data => {
    // data来自于后端的ok({ users: [...] })，所以需要取data.users
    users.value = data?.users || []
  }).catch(err => {
    console.error('加载用户列表失败:', err)
    toast.add({
      severity: 'error',
      summary: '错误',
      detail: '加载用户列表失败',
      life: 3000
    })
  }).finally(() => {
    loadingUsers.value = false
  })
}

const resetForm = () => {
  selectedUserIds.value = []
  selectedRole.value = 'member'
}

watch(() => props.visible, (visible) => {
  if (visible) {
    if (props.project) {
      // 预先选中已分配的用户
      selectedUserIds.value = props.project.sys_users?.map(u => u.id) || []
    } else {
      resetForm()
    }
  }
})

const handleClose = () => {
  emit('update:visible', false)
  resetForm()
}

const handleAssign = () => {
  if (!props.project) return

  if (selectedUserIds.value.length === 0) {
    toast.add({
      severity: 'warn',
      summary: '请选择用户',
      detail: '至少选择一个用户进行分配',
      life: 3000
    })
    return
  }

  loading.value = true

  projectApi.assignUsers(props.project.id, {
    user_ids: selectedUserIds.value,
    role: selectedRole.value as any
  }).then(() => {
    toast.add({
      severity: 'success',
      summary: '分配成功',
      detail: `成功分配 ${selectedUserIds.value.length} 个用户到项目`,
      life: 3000
    })
    emit('assigned')
    handleClose()
  }).catch(err => {
    console.error('分配用户失败:', err)
    toast.add({
      severity: 'error',
      summary: '分配失败',
      detail: err.message || '分配用户时发生错误',
      life: 3000
    })
  }).finally(() => {
    loading.value = false
  })
}

const getUserDisplayText = (user: SysUser) => {
  return `${user.name} (${user.email})`
}

const getRoleDisplayText = (role: string) => {
  const roleOption = projectRoleOptions.find(r => r.value === role)
  return roleOption?.label || role
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="emit('update:visible', $event)"
    :header="dialogTitle"
    modal
    class="p-fluid"
    style="width: 700px"
    @hide="handleClose"
  >
    <template #header>
      <div class="flex items-center gap-2">
        <i class="pi pi-users text-green-600"></i>
        <span class="font-semibold">{{ dialogTitle }}</span>
      </div>
    </template>

    <div class="flex flex-col gap-6 p-4">
      <!-- 项目信息显示 -->
      <div v-if="props.project" class="bg-gray-50 p-4 rounded-lg">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded bg-blue-100 flex items-center justify-center">
            <i class="pi pi-briefcase text-blue-600"></i>
          </div>
          <div>
            <div class="font-medium text-gray-900">{{ props.project.name }}</div>
            <div class="text-sm text-gray-600" v-if="props.project.description">
              {{ props.project.description }}
            </div>
            <div class="flex items-center gap-4 mt-2">
              <span class="text-xs text-gray-500">
                <i class="pi pi-calendar mr-1"></i>
                开始时间: {{ props.project.start_date }}
              </span>
              <Tag
                :value="props.project.active_ads_automate ? '广告自动化已启用' : '广告自动化未启用'"
                :severity="props.project.active_ads_automate ? 'success' : 'warning'"
                size="small"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- 角色选择 -->
      <div class="field">
        <label class="block mb-3 font-medium text-gray-700">
          <i class="pi pi-user-edit mr-2"></i>
          分配角色
        </label>
        <div class="grid grid-cols-3 gap-3">
          <div
            v-for="role in projectRoleOptions"
            :key="role.value"
            class="flex items-center p-3 border rounded-lg cursor-pointer transition-all"
            :class="{
              'border-blue-500 bg-blue-50': selectedRole === role.value,
              'border-gray-200 hover:border-gray-300': selectedRole !== role.value
            }"
            @click="selectedRole = role.value"
          >
            <RadioButton
              v-model="selectedRole"
              :value="role.value"
              :inputId="`role_${role.value}`"
              class="mr-3"
            />
            <div>
              <label :for="`role_${role.value}`" class="font-medium cursor-pointer">
                {{ role.label }}
              </label>
              <div class="text-xs text-gray-500 mt-1">
                {{ role.value === 'owner' ? '拥有完全权限' :
                   role.value === 'member' ? '拥有读写权限' : '只有查看权限' }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 用户选择 -->
      <div class="field">
        <label class="block mb-3 font-medium text-gray-700">
          <i class="pi pi-users mr-2"></i>
          选择用户
          <Badge v-if="selectedUsersCount > 0" :value="selectedUsersCount" class="ml-2" />
        </label>
        <MultiSelect
          v-model="selectedUserIds"
          :options="users"
          optionLabel="name"
          optionValue="id"
          placeholder="请选择要分配的用户"
          filter
          :loading="loadingUsers"
          class="w-full"
          :maxSelectedLabels="3"
          :selectionLimit="20"
          style="min-height: 3rem"
        >
          <template #option="slotProps">
            <div class="flex items-center gap-3 p-2">
              <Avatar
                :label="slotProps.option.initials"
                size="small"
                shape="circle"
                class="flex-shrink-0"
              />
              <div class="flex-1 min-w-0">
                <div class="font-medium text-gray-900">{{ slotProps.option.name }}</div>
                <div class="text-sm text-gray-500 truncate">{{ slotProps.option.email }}</div>
              </div>
              <Tag
                v-if="slotProps.option.status"
                :value="slotProps.option.status"
                :severity="slotProps.option.status === 'active' ? 'success' : 'warning'"
                size="small"
              />
            </div>
          </template>
          <template #selectedItems="slotProps">
            <div class="flex flex-wrap gap-1">
              <Tag
                v-for="user in slotProps.value.slice(0, 3)"
                :key="user.id"
                :value="user.name"
                class="mr-1"
              />
              <Tag
                v-if="slotProps.value.length > 3"
                :value="`+${slotProps.value.length - 3} 更多`"
                severity="info"
              />
            </div>
          </template>
        </MultiSelect>
        <small class="text-gray-600 mt-2 block">
          已选择 {{ selectedUsersCount }} 个用户，最多可选择 20 个用户
        </small>
      </div>

      <!-- 分配预览 -->
      <div v-if="selectedUsersCount > 0" class="bg-blue-50 p-4 rounded-lg">
        <div class="flex items-center gap-2 mb-3">
          <i class="pi pi-eye text-blue-600"></i>
          <span class="font-medium text-blue-800">分配预览</span>
        </div>
        <div class="text-sm text-blue-700">
          将以 <strong>{{ getRoleDisplayText(selectedRole) }}</strong> 角色分配
          <strong>{{ selectedUsersCount }}</strong> 个用户到项目
          <strong>{{ props.project?.name }}</strong>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <div class="text-sm text-gray-600">
          <i class="pi pi-info-circle mr-1"></i>
          分配后用户将根据角色获得相应权限
        </div>
        <div class="flex gap-2">
          <Button
            @click="handleClose"
            text
            size="small"
            severity="secondary"
            :disabled="loading"
          >
            <i class="pi pi-times mr-2"></i>
            取消
          </Button>
          <Button
            @click="handleAssign"
            :loading="loading"
            size="small"
            severity="success"
            :disabled="selectedUsersCount === 0"
          >
            <i class="pi pi-check mr-2" v-if="!loading"></i>
            分配用户 ({{ selectedUsersCount }})
          </Button>
        </div>
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
.field {
  margin-bottom: 1.5rem;
}

:deep(.p-dialog-content) {
  padding: 0;
}

:deep(.p-multiselect) {
  min-height: 3rem;
}

:deep(.p-multiselect-token) {
  background: #e0f2fe;
  color: #0369a1;
}

:deep(.p-radiobutton .p-radiobutton-box) {
  width: 1.25rem;
  height: 1.25rem;
}

.grid {
  display: grid;
}

.grid-cols-3 {
  grid-template-columns: repeat(3, 1fr);
}

.gap-3 {
  gap: 0.75rem;
}
</style>
