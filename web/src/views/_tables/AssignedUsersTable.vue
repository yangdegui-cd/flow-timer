<script setup lang="ts">
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import Button from 'primevue/button'
import Avatar from 'primevue/avatar'
import Dropdown from 'primevue/dropdown'
import type { UserProject, ProjectRole } from '@/api/user-project-api'

interface Props {
  users: UserProject[]
  roleOptions: Array<{
    label: string
    value: ProjectRole
    description: string
  }>
}

interface Emits {
  (e: 'updateRole', userProject: UserProject, newRole: ProjectRole): void
  (e: 'remove', userProject: UserProject): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

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

const handleRoleChange = (userProject: UserProject, newRole: ProjectRole) => {
  emit('updateRole', userProject, newRole)
}

const handleRemove = (userProject: UserProject) => {
  emit('remove', userProject)
}
</script>

<template>
  <DataTable
      :value="users"
      size="small"
  >
    <Column header="用户">
      <template #body="{ data }">
        <div class="flex items-center gap-3">
          <Avatar
              :label="data.sys_user.initials || data.sys_user.name?.[0]"
              size="normal"
          />
          <div>
            <div class="font-medium">{{ data.sys_user.name }}</div>
            <div class="text-sm text-gray-500">{{ data.sys_user.email }}</div>
          </div>
        </div>
      </template>
    </Column>
    <Column field="role" header="角色">
      <template #body="{ data }">
        <Dropdown
            :modelValue="data.role"
            :options="roleOptions"
            optionLabel="label"
            optionValue="value"
            @change="(e) => handleRoleChange(data, e.value)"
            class="w-32"
        >
          <template #value="{ value }">
            <Tag
                :value="roleOptions.find(r => r.value === value)?.label"
                :severity="getRoleSeverity(value)"
            />
          </template>
          <template #option="{ option }">
            <div>
              <div class="font-medium">{{ option.label }}</div>
              <div class="text-xs text-gray-500">{{ option.description }}</div>
            </div>
          </template>
        </Dropdown>
      </template>
    </Column>
    <Column field="assigned_at" header="分配时间">
      <template #body="{ data }">
        {{ new Date(data.assigned_at).toLocaleDateString() }}
      </template>
    </Column>
    <Column header="操作" style="width: 100px">
      <template #body="{ data }">
        <Button
            icon="pi pi-trash"
            size="small"
            severity="danger"
            text
            @click="handleRemove(data)"
            title="移除用户"
        />
      </template>
    </Column>
    <template #empty>
      <div class="text-center py-4 text-gray-500">
        暂未分配用户
      </div>
    </template>
  </DataTable>
</template>
