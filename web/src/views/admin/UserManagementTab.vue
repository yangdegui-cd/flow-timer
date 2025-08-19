<template>
  <div class="user-management-tab">
    <!-- 操作栏 -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
      <div>
        <h2 class="text-xl font-semibold text-surface-900">用户列表</h2>
        <p class="text-surface-600 text-sm mt-1">管理系统用户账号和权限</p>
      </div>
      
      <div class="flex items-center space-x-3">
        <!-- 搜索框 -->
        <div class="flex items-center space-x-2">
          <IconField>
            <InputIcon>
              <i class="pi pi-search" />
            </InputIcon>
            <InputText 
              v-model="filters.search"
              placeholder="搜索用户..."
              @input="handleSearch"
              class="w-64"
            />
          </IconField>
          
          <Dropdown
            v-model="filters.status"
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="状态筛选"
            @change="loadUsers"
            class="w-32"
            showClear
          />
        </div>
        
        <!-- 新增用户按钮 -->
        <Button 
          @click="showCreateDialog = true"
          icon="pi pi-plus" 
          label="新增用户"
          v-if="authStore.hasPermission('manage_users')"
        />
      </div>
    </div>

    <!-- 用户表格 -->
    <DataTable 
      :value="users" 
      :loading="loading"
      paginator 
      :rows="pagination.per_page"
      :totalRecords="pagination.total_count"
      :lazy="true"
      @page="onPageChange"
      dataKey="id"
      stripedRows
      showGridlines
      class="user-table"
    >
      <Column field="id" header="ID" sortable class="w-16">
        <template #body="{ data }">
          <span class="font-mono text-sm">#{{ data.id }}</span>
        </template>
      </Column>
      
      <Column field="name" header="用户信息" sortable>
        <template #body="{ data }">
          <div class="flex items-center space-x-3">
            <Avatar 
              :label="data.avatar_url ? undefined : data.name.charAt(0)"
              :image="data.avatar_url"
              shape="circle"
              class="bg-primary-100 text-primary-600"
            />
            <div>
              <div class="font-medium">{{ data.name }}</div>
              <div class="text-sm text-surface-500">{{ data.email }}</div>
            </div>
          </div>
        </template>
      </Column>
      
      <Column field="roles" header="角色">
        <template #body="{ data }">
          <div class="flex flex-wrap gap-1">
            <Tag 
              v-for="role in data.roles" 
              :key="role.name"
              :value="role.display_name"
              :severity="getRoleSeverity(role.name)"
              size="small"
            />
          </div>
        </template>
      </Column>
      
      <Column field="status" header="状态" sortable>
        <template #body="{ data }">
          <Tag 
            :value="getStatusLabel(data.status)"
            :severity="getStatusSeverity(data.status)"
          />
        </template>
      </Column>
      
      <Column field="last_login_at" header="最后登录">
        <template #body="{ data }">
          <span v-if="data.last_login_at" class="text-sm">
            {{ formatDateTime(data.last_login_at) }}
          </span>
          <span v-else class="text-sm text-surface-400">从未登录</span>
        </template>
      </Column>
      
      <Column header="操作" class="w-48">
        <template #body="{ data }">
          <div class="flex items-center space-x-1">
            <Button 
              @click="viewUser(data)"
              icon="pi pi-eye"
              size="small"
              text
              rounded
              tooltip="查看详情"
            />
            
            <Button 
              @click="editUser(data)"
              icon="pi pi-pencil"
              size="small"
              text
              rounded
              tooltip="编辑用户"
              v-if="authStore.hasPermission('manage_users')"
            />
            
            <Button 
              @click="assignRoles(data)"
              icon="pi pi-users"
              size="small"
              text
              rounded
              tooltip="分配角色"
              v-if="authStore.hasPermission('manage_users')"
            />
            
            <Button 
              @click="toggleUserStatus(data)"
              :icon="data.status === 'active' ? 'pi pi-lock' : 'pi pi-unlock'"
              size="small"
              text
              rounded
              :severity="data.status === 'active' ? 'warning' : 'success'"
              :tooltip="data.status === 'active' ? '禁用用户' : '启用用户'"
              v-if="authStore.hasPermission('manage_users')"
            />
            
            <Button 
              @click="deleteUser(data)"
              icon="pi pi-trash"
              size="small"
              text
              rounded
              severity="danger"
              tooltip="删除用户"
              v-if="authStore.hasPermission('manage_users') && data.id !== authStore.user?.id"
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- 对话框组件 -->
    <CreateUserDialog 
      v-model:visible="showCreateDialog"
      @success="refreshUsers"
    />
    
    <EditUserDialog 
      v-model:visible="showEditDialog"
      :user="selectedUser"
      @success="refreshUsers"
    />
    
    <AssignRolesDialog 
      v-model:visible="showAssignRolesDialog"
      :user="selectedUser"
      @success="refreshUsers"
    />
    
    <UserDetailDialog 
      v-model:visible="showDetailDialog"
      :user="selectedUser"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import UserApi, { type UserListParams } from '@/api/user-api'
import type { User } from '@/api/auth-api'

import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'

import CreateUserDialog from '@/views/_dialogs/CreateUserDialog.vue'
import EditUserDialog from '@/views/_dialogs/EditUserDialog.vue'
import AssignRolesDialog from '@/views/_dialogs/AssignRolesDialog.vue'
import UserDetailDialog from '@/views/_dialogs/UserDetailDialog.vue'

// Emits
const emit = defineEmits<{
  refresh: []
}>()

// Stores & Services
const authStore = useAuthStore()
const confirm = useConfirm()
const toast = useToast()

// Data
const users = ref<User[]>([])
const loading = ref(false)
const selectedUser = ref<User | null>(null)

const pagination = reactive({
  current_page: 1,
  per_page: 10,
  total_count: 0,
  total_pages: 0
})

const filters = reactive({
  search: '',
  status: ''
})

// Dialogs
const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const showAssignRolesDialog = ref(false)
const showDetailDialog = ref(false)

// Options
const statusOptions = [
  { label: '活跃', value: 'active' },
  { label: '非活跃', value: 'inactive' },
  { label: '已禁用', value: 'suspended' }
]

// Methods
const loadUsers = async (page = 1) => {
  loading.value = true
  
  try {
    const params: UserListParams = {
      page,
      per_page: pagination.per_page
    }
    
    if (filters.search) {
      params.name = filters.search
      params.email = filters.search
    }
    
    if (filters.status) {
      params.status = filters.status
    }
    
    const response = await UserApi.list(params)
    
    if (response.code === 200) {
      users.value = response.data.users
      Object.assign(pagination, response.data.pagination)
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取用户列表失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

const refreshUsers = () => {
  loadUsers(pagination.current_page)
  emit('refresh')
}

const handleSearch = () => {
  // 延迟搜索
  setTimeout(() => {
    loadUsers(1)
  }, 300)
}

const onPageChange = (event: any) => {
  loadUsers(event.page + 1)
}

// User actions
const viewUser = (user: User) => {
  selectedUser.value = user
  showDetailDialog.value = true
}

const editUser = (user: User) => {
  selectedUser.value = user
  showEditDialog.value = true
}

const assignRoles = (user: User) => {
  selectedUser.value = user
  showAssignRolesDialog.value = true
}

const toggleUserStatus = async (user: User) => {
  const newStatus = user.status === 'active' ? 'suspended' : 'active'
  const action = newStatus === 'active' ? '启用' : '禁用'
  
  confirm.require({
    message: `确定要${action}用户 "${user.name}" 吗？`,
    header: `${action}用户`,
    icon: 'pi pi-exclamation-triangle',
    rejectLabel: '取消',
    acceptLabel: '确定',
    accept: async () => {
      try {
        const response = await UserApi.update(user.id, { status: newStatus })
        if (response.code === 200) {
          toast.add({
            severity: 'success',
            summary: `${action}成功`,
            detail: response.data.message,
            life: 3000
          })
          refreshUsers()
        }
      } catch (error: any) {
        toast.add({
          severity: 'error',
          summary: `${action}失败`,
          detail: error.message,
          life: 5000
        })
      }
    }
  })
}

const deleteUser = (user: User) => {
  confirm.require({
    message: `确定要删除用户 "${user.name}" 吗？此操作不可恢复。`,
    header: '删除用户',
    icon: 'pi pi-trash',
    rejectLabel: '取消',
    acceptLabel: '删除',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        const response = await UserApi.delete(user.id)
        if (response.code === 200) {
          toast.add({
            severity: 'success',
            summary: '删除成功',
            detail: response.data.message,
            life: 3000
          })
          refreshUsers()
        }
      } catch (error: any) {
        toast.add({
          severity: 'error',
          summary: '删除失败',
          detail: error.message,
          life: 5000
        })
      }
    }
  })
}

// Helpers
const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'active': return 'success'
    case 'inactive': return 'warning'
    case 'suspended': return 'danger'
    default: return 'secondary'
  }
}

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'active': return '活跃'
    case 'inactive': return '非活跃'
    case 'suspended': return '已禁用'
    default: return status
  }
}

const getRoleSeverity = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'danger'
    case 'developer': return 'info'
    case 'operator': return 'warning'
    default: return 'secondary'
  }
}

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

// Lifecycle
onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.user-management-tab {
  max-width: 100%;
}

:deep(.user-table) {
  .p-datatable-thead > tr > th {
    background: var(--p-surface-50);
    color: var(--p-text-color);
    border-color: var(--p-surface-200);
  }
}
</style>