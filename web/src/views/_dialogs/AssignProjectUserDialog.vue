<script setup lang="ts">
import { ref, watch } from 'vue'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import type { ProjectRole, UserProject } from '@/api/user-project-api'

interface User {
  id: number
  name: string
  email: string
  initials?: string
}

interface Props {
  visible: boolean
  availableUsers: User[]
  assignedUsers: UserProject[]
  roleOptions: Array<{
    label: string
    value: ProjectRole
    description: string
  }>
}

interface Emits {
  (e: 'update:visible', value: boolean): void
  (e: 'assign', users: User[], role: ProjectRole): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const selectedUsers = ref<User[]>([])
const currentRole = ref<ProjectRole>('member')

// 过滤出未分配的用户
const unassignedUsers = ref<User[]>([])

watch(() => [props.availableUsers, props.assignedUsers], () => {
  unassignedUsers.value = props.availableUsers.filter(
      u => !props.assignedUsers.find(au => au.sys_user_id === u.id)
  )
}, { deep: true, immediate: true })

watch(() => props.visible, (newVal) => {
  if (newVal) {
    // 重置状态
    selectedUsers.value = []
    currentRole.value = 'member'
  }
})

const getRoleSeverity = (role: ProjectRole) => {
  switch (role) {
    case 'owner':
      return 'danger'
    case 'member':
      return 'success'
    case 'viewer':
      return 'info'
    default:
      return 'secondary'
  }
}

const handleClose = () => {
  emit('update:visible', false)
}

const handleAssign = () => {
  if (selectedUsers.value.length === 0) return
  emit('assign', selectedUsers.value, currentRole.value)
}
</script>

<template>
  <Dialog
      :visible="visible"
      @update:visible="handleClose"
      header="分配用户到项目"
      :style="{ width: '800px' }"
      modal
  >
    <div class="flex flex-row gap-6">
      <div class="flex-1">
        <label class="block text-sm font-medium mb-2">选择用户</label>
        <DataTable
            :value="unassignedUsers"
            v-model:selection="selectedUsers"
            selectionMode="multiple"
            dataKey="id"
            size="small"
            scrollable
            scrollHeight="300px"
        >
          <Column selectionMode="multiple" headerStyle="width: 3rem"></Column>
          <Column header="用户">
            <template #body="{ data }">
              <div class="flex items-center gap-2">
                <Avatar
                    :label="data.initials || data.name?.[0]"
                    size="small"
                />
                <div>
                  <div class="font-medium">{{ data.name }}</div>
                  <div class="text-xs text-gray-500">{{ data.email }}</div>
                </div>
              </div>
            </template>
          </Column>
          <template #empty>
            <div class="text-center py-4 text-gray-500">
              所有用户已分配
            </div>
          </template>
        </DataTable>
      </div>

      <div class="flex-1">
        <label class="block text-sm font-medium mb-2">选择角色</label>
        <div class="grid grid-cols-1 gap-2">
          <div
              v-for="role in roleOptions"
              :key="role.value"
              class="flex items-center p-3 border border-surface rounded cursor-pointer hover:bg-gray-50"
              :class="{ 'border-blue-500 bg-blue-50': currentRole === role.value }"
              @click="currentRole = role.value"
          >
            <input
                type="radio"
                :value="role.value"
                v-model="currentRole"
                class="mr-3"
            />
            <div class="flex-1">
              <div class="font-medium">{{ role.label }}</div>
              <div class="text-sm text-gray-500">{{ role.description }}</div>
            </div>
            <Tag :value="role.label" :severity="getRoleSeverity(role.value)"/>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <Button
          label="取消"
          icon="pi pi-times"
          @click="handleClose"
          text
      />
      <Button
          label="确定分配"
          icon="pi pi-check"
          @click="handleAssign"
          :disabled="selectedUsers.length === 0"
      />
    </template>
  </Dialog>
</template>
