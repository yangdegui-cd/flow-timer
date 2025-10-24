<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Tag from 'primevue/tag'
import ConfirmDialog from 'primevue/confirmdialog'
import Dialog from 'primevue/dialog'
import Password from 'primevue/password'
import { useConfirm } from 'primevue/useconfirm'

import userApi from '@/api/user-api'
import type { User, CreateUserRequest, UpdateUserRequest } from '@/api/user-api'
import AssignRolesDialog from '@/views/_dialogs/AssignRolesDialog.vue'

const toast = useToast()
const confirm = useConfirm()

const emit = defineEmits<{
  refresh: []
}>()

// 数据
const users = ref<User[]>([])
const loading = ref(false)
const globalFilter = ref('')
const selectedUsers = ref<User[]>([])
const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const showAssignRolesDialog = ref(false)
const editingUser = ref<User | null>(null)

// 分页
const totalRecords = ref(0)
const first = ref(0)
const rows = ref(10)

// 筛选选项
const statusOptions = [
  { label: '全部', value: '' },
  { label: '激活', value: 'active' },
  { label: '未激活', value: 'inactive' },
  { label: '已暂停', value: 'suspended' }
]
const selectedStatus = ref('')

// 表单数据
const createForm = ref<CreateUserRequest>({
  email: '',
  name: '',
  password: '',
  status: 'active'
})

const updateForm = ref<UpdateUserRequest>({
  email: '',
  name: '',
  status: 'active'
})

// 方法
const loadUsers = async () => {
  loading.value = true

  try {
    const data = await userApi.list({
      page: Math.floor(first.value / rows.value) + 1,
      per_page: rows.value,
      status: selectedStatus.value || undefined,
      email: globalFilter.value || undefined
    })
    users.value = data.users
    totalRecords.value = data.pagination.total_count
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '加载用户列表失败',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

const onPageChange = (event: any) => {
  first.value = event.first
  rows.value = event.rows
  loadUsers()
}

const openCreateDialog = () => {
  createForm.value = {
    email: '',
    name: '',
    password: '',
    status: 'active'
  }
  showCreateDialog.value = true
}

const openEditDialog = (user: User) => {
  editingUser.value = user
  updateForm.value = {
    email: user.email,
    name: user.name,
    status: user.status
  }
  showEditDialog.value = true
}

const openAssignRolesDialog = (user: User) => {
  editingUser.value = user
  showAssignRolesDialog.value = true
}

const onRolesAssigned = () => {
  loadUsers()
  emit('refresh')
}

const createUser = async () => {
  try {
    await userApi.create(createForm.value)
    toast.add({
      severity: 'success',
      summary: '创建成功',
      detail: '用户创建成功',
      life: 3000
    })
    showCreateDialog.value = false
    loadUsers()
    emit('refresh')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '创建失败',
      detail: error.message || '用户创建失败',
      life: 3000
    })
  }
}

const updateUser = async () => {
  if (!editingUser.value) return

  try {
    await userApi.update(editingUser.value.id, updateForm.value)
    toast.add({
      severity: 'success',
      summary: '更新成功',
      detail: '用户信息更新成功',
      life: 3000
    })
    showEditDialog.value = false
    loadUsers()
    emit('refresh')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '更新失败',
      detail: error.message || '用户信息更新失败',
      life: 3000
    })
  }
}

const changeUserStatus = async (user: User, newStatus: string) => {
  try {
    await userApi.changeStatus(user.id, newStatus as any)
    toast.add({
      severity: 'success',
      summary: '状态更新成功',
      detail: `用户状态已更新为${getStatusLabel(newStatus)}`,
      life: 3000
    })
    loadUsers()
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '状态更新失败',
      detail: error.message || '用户状态更新失败',
      life: 3000
    })
  }
}

const deleteUser = (user: User) => {
  confirm.require({
    message: `确定要删除用户 "${user.name}" 吗？此操作无法撤销。`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    rejectClass: 'p-button-secondary p-button-outlined p-button-sm',
    acceptClass: 'p-button-danger p-button-sm',
    accept: async () => {
      try {
        await userApi.delete(user.id)
        toast.add({
          severity: 'success',
          summary: '删除成功',
          detail: '用户已删除',
          life: 3000
        })
        loadUsers()
        emit('refresh')
      } catch (error: any) {
        toast.add({
          severity: 'error',
          summary: '删除失败',
          detail: error.message || '用户删除失败',
          life: 3000
        })
      }
    }
  })
}

const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'active': return 'success'
    case 'inactive': return 'warning'
    case 'suspended': return 'danger'
    default: return 'info'
  }
}

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'active': return '激活'
    case 'inactive': return '未激活'
    case 'suspended': return '已暂停'
    default: return status
  }
}

// 生命周期
onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div class="user-management-tab">
    <!-- 工具栏 -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-4">
        <InputText
          v-model="globalFilter"
          placeholder="搜索用户邮箱..."
          class="w-80"
          size="small"
          @keyup.enter="loadUsers"
        />
        <Dropdown
          v-model="selectedStatus"
          :options="statusOptions"
          optionLabel="label"
          optionValue="value"
          placeholder="筛选状态"
          size="small"
          @change="loadUsers"
        />
        <Button icon="pi pi-search" label="搜索" size="small" @click="loadUsers" />
      </div>
      <Button icon="pi pi-plus" label="添加用户" size="small" @click="openCreateDialog" />
    </div>

    <!-- 用户表格 -->
    <DataTable
      v-model:selection="selectedUsers"
      :value="users"
      :loading="loading"
      :paginator="true"
      :rows="rows"
      :totalRecords="totalRecords"
      :lazy="true"
      paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
      currentPageReportTemplate="{first} 到 {last} 共 {totalRecords} 条"
      :rowsPerPageOptions="[10, 20, 50]"
      dataKey="id"
      responsiveLayout="scroll"
      @page="onPageChange"
    >
      <Column selectionMode="multiple" style="width: 3rem" />
      <Column field="id" header="ID" style="width: 80px" />
      <Column field="name" header="姓名" />
      <Column field="email" header="邮箱" />
      <Column field="status" header="状态" style="width: 100px">
        <template #body="{ data }">
          <Tag :value="getStatusLabel(data.status)" :severity="getStatusSeverity(data.status)" />
        </template>
      </Column>
      <Column field="roles" header="角色" style="width: 200px">
        <template #body="{ data }">
          <div class="flex flex-wrap gap-1">
            <Tag v-for="role in data.roles" :key="role.name" :value="role.display_name" severity="info" />
          </div>
        </template>
      </Column>
      <Column field="last_login_at" header="最后登录" style="width: 150px">
        <template #body="{ data }">
          {{ data.last_login_at ? new Date(data.last_login_at).toLocaleDateString() : '从未登录' }}
        </template>
      </Column>
      <Column header="操作" style="width: 200px">
        <template #body="{ data }">
          <div class="flex gap-2">
            <Button 
              icon="pi pi-users" 
              size="small" 
              outlined 
              v-tooltip="'分配角色'"
              @click="openAssignRolesDialog(data)" 
            />
            <Button 
              icon="pi pi-pencil" 
              size="small" 
              outlined 
              v-tooltip="'编辑用户'"
              @click="openEditDialog(data)" 
            />
            <Button
              v-if="data.status === 'active'"
              icon="pi pi-ban"
              size="small"
              severity="warning"
              outlined
              v-tooltip="'暂停用户'"
              @click="changeUserStatus(data, 'suspended')"
            />
            <Button
              v-else-if="data.status === 'suspended'"
              icon="pi pi-check"
              size="small"
              severity="success"
              outlined
              v-tooltip="'激活用户'"
              @click="changeUserStatus(data, 'active')"
            />
            <Button 
              icon="pi pi-trash" 
              size="small" 
              severity="danger" 
              outlined 
              v-tooltip="'删除用户'"
              @click="deleteUser(data)" 
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- 创建用户对话框 -->
    <Dialog v-model:visible="showCreateDialog" header="创建用户" modal style="width: 500px">
      <div class="grid grid-cols-1 gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">邮箱</label>
          <InputText v-model="createForm.email" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">姓名</label>
          <InputText v-model="createForm.name" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">密码</label>
          <Password v-model="createForm.password" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">状态</label>
          <Dropdown
            v-model="createForm.status"
            :options="statusOptions.slice(1)"
            optionLabel="label"
            optionValue="value"
            class="w-full"
            size="small"
          />
        </div>
      </div>
      <template #footer>
        <Button label="取消" icon="pi pi-times" text size="small" @click="showCreateDialog = false" />
        <Button label="创建" icon="pi pi-check" size="small" @click="createUser" />
      </template>
    </Dialog>

    <!-- 编辑用户对话框 -->
    <Dialog v-model:visible="showEditDialog" header="编辑用户" modal style="width: 500px">
      <div class="grid grid-cols-1 gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">邮箱</label>
          <InputText v-model="updateForm.email" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">姓名</label>
          <InputText v-model="updateForm.name" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">状态</label>
          <Dropdown
            v-model="updateForm.status"
            :options="statusOptions.slice(1)"
            optionLabel="label"
            optionValue="value"
            class="w-full"
            size="small"
          />
        </div>
      </div>
      <template #footer>
        <Button label="取消" icon="pi pi-times" text size="small" @click="showEditDialog = false" />
        <Button label="保存" icon="pi pi-check" size="small" @click="updateUser" />
      </template>
    </Dialog>

    <!-- 角色分配对话框 -->
    <AssignRolesDialog
      v-model:visible="showAssignRolesDialog"
      :user="editingUser"
      @success="onRolesAssigned"
    />

    <ConfirmDialog />
  </div>
</template>

<style scoped>
.user-management-tab {
  height: 100%;
}
</style>
