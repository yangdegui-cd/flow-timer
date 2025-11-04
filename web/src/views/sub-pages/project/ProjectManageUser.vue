<script setup lang="ts">
import { ref, watch } from 'vue'
import Card from 'primevue/card'
import Button from 'primevue/button'
import AssignedUsersTable from '@/views/_tables/AssignedUsersTable.vue'
import AssignProjectUserDialog from '@/views/_dialogs/AssignProjectUserDialog.vue'
import userProjectApi, { type ProjectRole, type UserProject } from '@/api/user-project-api'
import userApi from '@/api/user-api'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'

const toast = useToast()
const confirm = useConfirm()

const props = defineProps<{
  project: any
}>()

// 分配的用户
const assignedUsers = ref<UserProject[]>([])
const availableUsers = ref<any[]>([])
const showUserDialog = ref(false)

// 角色选项
const roleOptions = [
  { label: '所有者', value: 'owner', description: '拥有项目的完全控制权' },
  { label: '成员', value: 'member', description: '可以编辑项目和管理数据' },
  { label: '查看者', value: 'viewer', description: '只能查看项目数据' }
]

// 加载项目分配的用户
const loadProjectUsers = async () => {
  if (!props.project?.id) return

  userProjectApi
      .getProjectUsers(props.project.id)
      .then(data => {
        assignedUsers.value = data ?? []
      })
      .catch(err => {
        console.error('加载项目用户失败:', err)
        toast.add({ severity: 'error', summary: '错误', detail: err?.msg ?? '加载项目用户失败', life: 3000 })
      })
}

// 加载可用用户
const loadAvailableUsers = async () => {
  userApi.list()
      .then(res => {
        availableUsers.value = res.users
      })
      .catch(res => {
        toast.add({ severity: 'error', summary: '加载可用用户失败', detail: res.data.msg, life: 3000 })
      })
}

// 打开分配用户对话框
const openAssignUserDialog = () => {
  showUserDialog.value = true
}

// 分配用户
const assignUsers = async (users: any[], role: ProjectRole) => {
  try {
    for (const user of users) {
      await userProjectApi.assignUser({
        sys_user_id: user.id,
        project_id: props.project.id,
        role: role
      })
    }
    toast.add({ severity: 'success', summary: '成功', detail: '用户分配成功', life: 3000 })
    showUserDialog.value = false
    await loadProjectUsers()
  } catch (err: any) {
    console.error('分配用户失败:', err)
    const message = err?.msg ?? '分配失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 更新用户角色
const updateUserRole = async (userProject: UserProject, newRole: ProjectRole) => {
  try {
    await userProjectApi.updateUserRole(userProject.id, newRole)
    toast.add({ severity: 'success', summary: '成功', detail: '角色更新成功', life: 3000 })
    await loadProjectUsers()
  } catch (err: any) {
    console.error('更新角色失败:', err)
    const message = err?.msg ?? '更新失败'
    toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
  }
}

// 移除用户
const removeUser = async (userProject: UserProject) => {
  confirm.require({
    message: `确定要将用户 "${userProject.sys_user.name}" 从项目中移除吗？`,
    header: '确认移除',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '确定',
    rejectLabel: '取消',
    accept: async () => {
      try {
        await userProjectApi.removeUser(userProject.id)
        toast.add({ severity: 'success', summary: '成功', detail: '用户移除成功', life: 3000 })
        await loadProjectUsers()
      } catch (err: any) {
        console.error('移除用户失败:', err)
        const message = err?.msg ?? '移除失败'
        toast.add({ severity: 'error', summary: '错误', detail: message, life: 3000 })
      }
    }
  })
}

// 监听 project 变化，重新加载数据
watch(() => props.project?.id, (newId) => {
  if (newId) {
    loadProjectUsers()
    loadAvailableUsers()
  }
}, { immediate: true })
</script>

<template>
  <Card>
    <template #title>
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <i class="pi pi-users text-purple-600 mr-2"></i>
          分配用户
        </div>
        <Button
            @click="openAssignUserDialog"
            size="small"
            class="flex items-center"
        >
          <i class="pi pi-user-plus mr-2"></i>
          分配用户
        </Button>
      </div>
    </template>
    <template #content>
      <AssignedUsersTable
          :users="assignedUsers"
          :role-options="roleOptions"
          @update-role="updateUserRole"
          @remove="removeUser"
      />
    </template>
  </Card>

  <!-- 分配用户对话框 -->
  <AssignProjectUserDialog
      v-model:visible="showUserDialog"
      :available-users="availableUsers"
      :assigned-users="assignedUsers"
      :role-options="roleOptions"
      @assign="assignUsers"
  />
</template>

<style scoped>
</style>
