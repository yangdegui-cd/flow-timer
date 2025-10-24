<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Tag from 'primevue/tag'
import Dialog from 'primevue/dialog'
import Textarea from 'primevue/textarea'
import MultiSelect from 'primevue/multiselect'
import Checkbox from 'primevue/checkbox'
import ConfirmDialog from 'primevue/confirmdialog'
import { useConfirm } from 'primevue/useconfirm'

import roleApi from '@/api/role-api'
import type { CreateRoleRequest, UpdateRoleRequest } from '@/data/types/role-types'
import type { Role } from '@/data/types/user-types'
import EditPermissionsDialog from '@/views/_dialogs/EditPermissionsDialog.vue'

const toast = useToast()
const confirm = useConfirm()

const emit = defineEmits<{
  refresh: []
}>()

// 数据
const roles = ref<Role[]>([])
const loading = ref(false)
const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const showPermissionsDialog = ref(false)
const editingRole = ref<Role | null>(null)

// 权限相关数据
const availablePermissions = ref([])
const modules = ref([])
const selectedModule = ref('')

// 表单数据
const createForm = ref<CreateRoleRequest>({
  name: '',
  description: '',
  permissions: []
})

const updateForm = ref<UpdateRoleRequest>({
  name: '',
  description: '',
  permissions: []
})

// 权限管理表单
const permissionForm = ref({
  permission_ids: [],           // 直接绑定的权限
})

// 方法
const loadRoles = async () => {
  loading.value = true
  try {
    const data = await roleApi.list()
    roles.value = data.roles || data
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '加载角色列表失败',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

const loadPermissions = async () => {
  try {
    const data = await roleApi.getAvailablePermissions()
    availablePermissions.value = data.permissions
    modules.value = Object.keys(data.grouped_permissions || {})
  } catch (error) {
    console.error('加载权限失败:', error)
  }
}
// 权限组功能已移除

const openCreateDialog = () => {
  createForm.value = {
    name: '',
    description: '',
    permissions: []
  }
  showCreateDialog.value = true
}

const openEditDialog = (role: Role) => {
  editingRole.value = role
  updateForm.value = {
    name: role.name,
    description: role.description || '',
    permissions: role.permissions?.map(p => p.name) || []
  }
  showEditDialog.value = true
}

const openPermissionsDialog = (role: Role) => {
  editingRole.value = role
  showPermissionsDialog.value = true
}

const createRole = async () => {
  try {
    await roleApi.create(createForm.value)
    toast.add({
      severity: 'success',
      summary: '创建成功',
      detail: '角色创建成功',
      life: 3000
    })
    showCreateDialog.value = false
    loadRoles()
    emit('refresh')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '创建失败',
      detail: error.message || '角色创建失败',
      life: 3000
    })
  }
}

const updateRole = async () => {
  if (!editingRole.value) return

  try {
    await roleApi.update(editingRole.value.id, updateForm.value)
    toast.add({
      severity: 'success',
      summary: '更新成功',
      detail: '角色信息更新成功',
      life: 3000
    })
    showEditDialog.value = false
    loadRoles()
    emit('refresh')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '更新失败',
      detail: error.message || '角色信息更新失败',
      life: 3000
    })
  }
}

const onPermissionsUpdated = () => {
  loadRoles()
  emit('refresh')
}

const deleteRole = (role: Role) => {
  if (role.system_role) {
    toast.add({
      severity: 'warn',
      summary: '无法删除',
      detail: '系统角色不能删除',
      life: 3000
    })
    return
  }

  confirm.require({
    message: `确定要删除角色 "${role.display_name}" 吗？此操作无法撤销。`,
    header: '确认删除',
    icon: 'pi pi-exclamation-triangle',
    rejectClass: 'p-button-secondary p-button-outlined p-button-sm',
    acceptClass: 'p-button-danger p-button-sm',
    accept: () => {
      roleApi.delete(role.id).then(() => {
        toast.add({
          severity: 'success',
          summary: '删除成功',
          detail: '角色已删除',
          life: 3000
        })
        loadRoles()
        emit('refresh')
      }).catch((error: any) => {
        toast.add({
          severity: 'error',
          summary: '删除失败',
          detail: error.message || '角色删除失败',
          life: 3000
        })
      })
    }
  })
}

const getPermissionOptions = () => {

}


// 生命周期
onMounted(() => {
  loadRoles()
  loadPermissions()
})
</script>

<template>
  <div class="role-management-tab">
    <!-- 工具栏 -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-4">
        <h2 class="text-lg font-semibold">角色管理</h2>
      </div>
      <Button icon="pi pi-plus" label="添加角色" size="small" @click="openCreateDialog" />
    </div>

    <!-- 角色表格 -->
    <DataTable
      :value="roles"
      :loading="loading"
      dataKey="id"
      responsiveLayout="scroll"
    >
      <Column field="id" header="ID" style="width: 80px" />
      <Column field="display_name" header="角色名称" />
      <Column field="name" header="标识" />
      <Column field="description" header="描述" />
      <Column field="user_count" header="用户数" style="width: 100px">
        <template #body="{ data }">
          <Tag :value="data.user_count" severity="info" />
        </template>
      </Column>
      <Column field="permission_count" header="权限数" style="width: 100px">
        <template #body="{ data }">
          <Tag :value="data.permissions.length" severity="secondary" />
        </template>
      </Column>
      <Column field="system_role" header="系统角色" style="width: 100px">
        <template #body="{ data }">
          <Tag v-if="data.system_role" value="是" severity="warning" />
          <Tag v-else value="否" severity="info" />
        </template>
      </Column>
      <Column header="操作" style="width: 250px">
        <template #body="{ data }">
          <div class="flex gap-2">
            <Button
              icon="pi pi-eye"
              size="small"
              outlined
              v-tooltip="'查看权限'"
              @click="openPermissionsDialog(data)"
            />
            <Button
              icon="pi pi-pencil"
              size="small"
              outlined
              v-tooltip="'编辑角色'"
              :disabled="data.system_role"
              @click="openEditDialog(data)"
            />
            <Button
              icon="pi pi-trash"
              size="small"
              severity="danger"
              outlined
              v-tooltip="'删除角色'"
              :disabled="data.system_role"
              @click="deleteRole(data)"
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- 创建角色对话框 -->
    <Dialog v-model:visible="showCreateDialog" header="创建角色" modal style="width: 600px">
      <div class="grid grid-cols-1 gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">角色标识</label>
          <InputText v-model="createForm.name" class="w-full" size="small" placeholder="例如: custom_role" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">描述</label>
          <Textarea v-model="createForm.description" class="w-full" size="small" rows="3" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">权限</label>
          <MultiSelect
            v-model="createForm.permissions"
            :options="getPermissionOptions()"
            optionLabel="label"
            optionValue="value"
            placeholder="选择权限"
            class="w-full"
            size="small"
            :filter="true"
            :maxSelectedLabels="3"
          />
        </div>
      </div>
      <template #footer>
        <Button label="取消" icon="pi pi-times" text size="small" @click="showCreateDialog = false" />
        <Button label="创建" icon="pi pi-check" size="small" @click="createRole" />
      </template>
    </Dialog>

    <!-- 编辑角色对话框 -->
    <Dialog v-model:visible="showEditDialog" header="编辑角色" modal style="width: 600px">
      <div class="grid grid-cols-1 gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">角色标识</label>
          <InputText v-model="updateForm.name" class="w-full" size="small" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">描述</label>
          <Textarea v-model="updateForm.description" class="w-full" size="small" rows="3" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">权限</label>
          <MultiSelect
            v-model="updateForm.permissions"
            :options="getPermissionOptions()"
            optionLabel="label"
            optionValue="value"
            placeholder="选择权限"
            class="w-full"
            size="small"
            :filter="true"
            :maxSelectedLabels="3"
          />
        </div>
      </div>
      <template #footer>
        <Button label="取消" icon="pi pi-times" text size="small" @click="showEditDialog = false" />
        <Button label="保存" icon="pi pi-check" size="small" @click="updateRole" />
      </template>
    </Dialog>

    <!-- 权限管理对话框 -->
    <EditPermissionsDialog
      v-model:visible="showPermissionsDialog"
      :role="editingRole"
      @success="onPermissionsUpdated"
    />

    <ConfirmDialog />
  </div>
</template>

<style scoped>
.role-management-tab {
  height: 100%;
}
</style>
