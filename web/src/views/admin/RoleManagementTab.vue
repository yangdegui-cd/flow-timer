<template>
  <div class="role-management-tab">
    <!-- 操作栏 -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
      <div>
        <h2 class="text-xl font-semibold text-surface-900">角色列表</h2>
        <p class="text-surface-600 text-sm mt-1">管理系统角色和权限配置</p>
      </div>
      
      <div class="flex items-center space-x-3">
        <Button 
          @click="showCreateDialog = true"
          icon="pi pi-plus" 
          label="新增角色"
          v-if="authStore.hasPermission('manage_roles')"
        />
      </div>
    </div>

    <!-- 角色卡片网格 -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <Card 
        v-for="role in roles" 
        :key="role.id"
        class="role-card hover:shadow-lg transition-shadow"
      >
        <template #header>
          <div class="p-6 pb-0">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center space-x-3">
                <div 
                  class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg"
                  :class="getRoleColorClass(role.name)"
                >
                  {{ role.display_name.charAt(0) }}
                </div>
                <div>
                  <h3 class="font-semibold text-lg text-surface-900">{{ role.display_name }}</h3>
                  <p class="text-sm text-surface-500">{{ role.name }}</p>
                </div>
              </div>
              
              <Tag 
                v-if="role.system_role"
                value="系统角色"
                severity="info"
                size="small"
              />
            </div>
          </div>
        </template>

        <template #content>
          <div class="space-y-4">
            <!-- 描述 -->
            <p v-if="role.description" class="text-surface-600 text-sm">
              {{ role.description }}
            </p>

            <!-- 统计信息 -->
            <div class="grid grid-cols-2 gap-4 text-center">
              <div class="bg-surface-50 p-3 rounded-lg">
                <div class="text-lg font-bold text-primary-600">{{ role.user_count }}</div>
                <div class="text-sm text-surface-500">用户数量</div>
              </div>
              <div class="bg-surface-50 p-3 rounded-lg">
                <div class="text-lg font-bold text-secondary-600">{{ role.permissions.length }}</div>
                <div class="text-sm text-surface-500">权限数量</div>
              </div>
            </div>

            <!-- 权限预览 -->
            <div>
              <div class="text-sm font-medium text-surface-700 mb-2">权限预览</div>
              <div class="flex flex-wrap gap-1">
                <Tag 
                  v-for="permission in role.permissions.slice(0, 4)" 
                  :key="permission"
                  :value="getPermissionLabel(permission)"
                  size="small"
                  severity="secondary"
                />
                <Tag 
                  v-if="role.permissions.length > 4"
                  :value="`+${role.permissions.length - 4}`"
                  size="small"
                  severity="secondary"
                />
              </div>
            </div>
          </div>
        </template>

        <template #footer>
          <div class="flex justify-end space-x-2">
            <Button 
              @click="viewRole(role)"
              icon="pi pi-eye"
              size="small"
              text
              rounded
              tooltip="查看详情"
            />
            
            <Button 
              @click="editPermissions(role)"
              icon="pi pi-cog"
              size="small"
              text
              rounded
              tooltip="编辑权限"
              v-if="authStore.hasPermission('manage_roles')"
            />
            
            <Button 
              @click="editRole(role)"
              icon="pi pi-pencil"
              size="small"
              text
              rounded
              tooltip="编辑角色"
              v-if="authStore.hasPermission('manage_roles')"
            />
            
            <Button 
              @click="deleteRole(role)"
              icon="pi pi-trash"
              size="small"
              text
              rounded
              severity="danger"
              tooltip="删除角色"
              v-if="authStore.hasPermission('manage_roles') && !role.system_role && role.user_count === 0"
            />
          </div>
        </template>
      </Card>

      <!-- 空状态 -->
      <div v-if="roles.length === 0 && !loading" class="col-span-full">
        <Card class="text-center py-12">
          <template #content>
            <i class="pi pi-shield text-4xl text-surface-400 mb-4 block"></i>
            <p class="text-surface-500 text-lg">暂无角色数据</p>
          </template>
        </Card>
      </div>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <ProgressSpinner size="50" strokeWidth="4" />
    </div>

    <!-- 对话框组件 -->
    <CreateRoleDialog 
      v-model:visible="showCreateDialog"
      @success="refreshRoles"
    />

    <EditRoleDialog 
      v-model:visible="showEditDialog"
      :role="selectedRole"
      @success="refreshRoles"
    />

    <EditPermissionsDialog 
      v-model:visible="showPermissionsDialog"
      :role="selectedRole"
      @success="refreshRoles"
    />

    <RoleDetailDialog 
      v-model:visible="showDetailDialog"
      :role="selectedRole"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '@/stores/auth'
import RoleApi, { type Role } from '@/api/role-api'

import Card from 'primevue/card'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'

import CreateRoleDialog from '@/views/_dialogs/CreateRoleDialog.vue'
import EditRoleDialog from '@/views/_dialogs/EditRoleDialog.vue'
import EditPermissionsDialog from '@/views/_dialogs/EditPermissionsDialog.vue'
import RoleDetailDialog from '@/views/_dialogs/RoleDetailDialog.vue'

// Emits
const emit = defineEmits<{
  refresh: []
}>()

// Stores & Services
const authStore = useAuthStore()
const confirm = useConfirm()
const toast = useToast()

// Data
const roles = ref<Role[]>([])
const loading = ref(false)
const selectedRole = ref<Role | null>(null)

// Dialogs
const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const showPermissionsDialog = ref(false)
const showDetailDialog = ref(false)

// Methods
const loadRoles = async () => {
  loading.value = true
  
  try {
    const response = await RoleApi.list()
    
    if (response.code === 200) {
      roles.value = response.data.roles
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取角色列表失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

const refreshRoles = () => {
  loadRoles()
  emit('refresh')
}

// Role actions
const viewRole = (role: Role) => {
  selectedRole.value = role
  showDetailDialog.value = true
}

const editRole = (role: Role) => {
  selectedRole.value = role
  showEditDialog.value = true
}

const editPermissions = (role: Role) => {
  selectedRole.value = role
  showPermissionsDialog.value = true
}

const deleteRole = (role: Role) => {
  confirm.require({
    message: `确定要删除角色 "${role.display_name}" 吗？此操作不可恢复。`,
    header: '删除角色',
    icon: 'pi pi-trash',
    rejectLabel: '取消',
    acceptLabel: '删除',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        const response = await RoleApi.delete(role.id)
        if (response.code === 200) {
          toast.add({
            severity: 'success',
            summary: '删除成功',
            detail: response.data.message,
            life: 3000
          })
          refreshRoles()
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
const getRoleColorClass = (roleName: string) => {
  switch (roleName) {
    case 'admin': return 'bg-red-500'
    case 'developer': return 'bg-blue-500'
    case 'operator': return 'bg-orange-500'
    case 'viewer': return 'bg-gray-500'
    default: return 'bg-primary-500'
  }
}

const getPermissionLabel = (permission: string) => {
  const labels: Record<string, string> = {
    'manage_users': '管理用户',
    'manage_roles': '管理角色',
    'manage_tasks': '管理任务',
    'manage_flows': '管理流程',
    'manage_executions': '管理执行',
    'view_resque_monitor': '队列监控',
    'manage_system': '系统管理',
    'view_tasks': '查看任务',
    'create_tasks': '创建任务',
    'edit_tasks': '编辑任务',
    'delete_tasks': '删除任务',
    'view_flows': '查看流程',
    'create_flows': '创建流程',
    'edit_flows': '编辑流程',
    'delete_flows': '删除流程',
    'view_executions': '查看执行'
  }
  return labels[permission] || permission
}

// Lifecycle
onMounted(() => {
  loadRoles()
})
</script>

<style scoped>
.role-management-tab {
  max-width: 100%;
}

.role-card {
  transition: all 0.2s ease;
}

.role-card:hover {
  transform: translateY(-2px);
}
</style>