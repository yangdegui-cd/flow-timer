<template>
  <Dialog
    v-model:visible="visible"
    modal
    header="分配角色"
    class="w-full max-w-6xl"
    :style="{ height: '80vh' }"
  >
    <div v-if="user" class="h-full flex flex-col space-y-4">
      <!-- 用户信息卡片 -->
      <Card class="bg-gradient-to-r from-blue-50 to-indigo-50 border-l-4 border-l-blue-500">
        <template #content>
          <div class="flex items-center space-x-4">
            <Avatar
              :label="user.name?.charAt(0).toUpperCase()"
              size="large"
              class="bg-blue-500 text-white"
            />
            <div>
              <h3 class="text-lg font-semibold text-gray-900">{{ user.name }}</h3>
              <p class="text-sm text-gray-600">{{ user.email }}</p>
              <div class="flex items-center space-x-2 mt-1">
                <Tag
                  :value="user.is_active ? '活跃' : '禁用'"
                  :severity="user.is_active ? 'success' : 'danger'"
                  size="small"
                />
                <span class="text-xs text-gray-500">当前角色: {{ user.roles?.length || 0 }} 个</span>
              </div>
            </div>
          </div>
        </template>
      </Card>

      <!-- 搜索框 -->
      <div class="flex space-x-4">
        <div class="flex-1">
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText
              v-model="searchQuery"
              placeholder="搜索可分配角色..."
              class="w-full"
              size="small"
            />
          </IconField>
        </div>
        <div class="flex-1">
          <IconField iconPosition="left">
            <InputIcon class="pi pi-search" />
            <InputText
              v-model="assignedSearchQuery"
              placeholder="搜索已分配角色..."
              class="w-full"
              size="small"
            />
          </IconField>
        </div>
      </div>

      <!-- PickList 组件 -->
      <div class="flex-1 min-h-0">
        <PickList
          v-model="roleLists"
          :listStyle="{ height: '400px' }"
          dataKey="id"
          :filter="false"
          class="role-picklist"
        >
          <template #sourceheader>
            <div class="flex items-center justify-between p-3 bg-blue-50 border-b">
              <div class="flex items-center space-x-2">
                <i class="pi pi-users text-primary-600"></i>
                <span class="font-semibold text-primary-800">可分配角色</span>
              </div>
              <Tag :value="filteredAvailableRoles.length" severity="info" size="small" />
            </div>
          </template>

          <template #targetheader>
            <div class="flex items-center justify-between p-3 bg-green-50 border-b">
              <div class="flex items-center space-x-2">
                <i class="pi pi-check-circle text-green-600"></i>
                <span class="font-semibold text-green-800">已分配角色</span>
              </div>
              <Tag :value="filteredAssignedRoles.length" severity="success" size="small" />
            </div>
          </template>

          <template #item="{ item: role, index }">
            <div class="p-3 hover:bg-surface-50 border-b border-surface-100 last:border-b-0 transition-colors">
              <div class="flex items-start space-x-3">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 rounded-full flex items-center justify-center text-white font-semibold"
                       :class="getRoleColorClass(role.name)">
                    {{ role.name?.charAt(0).toUpperCase() }}
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-center space-x-2">
                    <h4 class="font-medium text-gray-900 truncate">{{ role.name }}</h4>
                    <Tag
                      :value="role.is_system ? '系统' : '自定义'"
                      :severity="role.is_system ? 'info' : 'secondary'"
                      size="small"
                    />
                  </div>
                  <p v-if="role.description" class="text-sm text-gray-600 mt-1 line-clamp-2">
                    {{ role.description }}
                  </p>
                  <div class="flex items-center justify-between mt-2">
                    <div class="flex flex-wrap gap-1">
                      <Tag
                        v-for="permission in (role.permissions || []).slice(0, 2)"
                        :key="permission.id"
                        :value="permission.name"
                        size="small"
                        severity="secondary"
                        class="text-xs"
                      />
                      <Tag
                        v-if="(role.permissions || []).length > 2"
                        :value="`+${(role.permissions || []).length - 2}`"
                        size="small"
                        severity="secondary"
                        class="text-xs"
                      />
                    </div>
                    <div class="flex items-center space-x-2 text-xs text-gray-500">
                      <i class="pi pi-users"></i>
                      <span>{{ role.users_count || 0 }} 用户</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </template>
        </PickList>
      </div>

      <!-- 操作提示 -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-3">
        <div class="flex items-start space-x-3">
          <i class="pi pi-info-circle text-primary-600 mt-0.5"></i>
          <div class="text-sm text-primary-800">
            <p class="font-medium">操作提示：</p>
            <ul class="mt-1 space-y-1 text-xs">
              <li>• 使用中间的箭头按钮可以移动选中的角色</li>
              <li>• 双击角色项可以快速移动到另一侧</li>
              <li>• 系统角色具有预定义权限，自定义角色可自由配置</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <div class="text-sm text-gray-600">
          将分配 <strong>{{ roleLists[1].length }}</strong> 个角色给用户
        </div>
        <div class="flex space-x-2">
          <Button
            label="取消"
            @click="visible = false"
            severity="secondary"
            size="small"
          />
          <Button
            label="保存分配"
            @click="handleAssignRoles"
            :loading="loading"
            size="small"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue'
import { useToast } from 'primevue/usetoast'
import roleApi from '@/api/role-api'
import userApi from '@/api/user-api'
import type { User } from '@/data/types/auth'
import type { Role } from '@/data/types/user-types'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Card from 'primevue/card'
import Avatar from 'primevue/avatar'
import PickList from 'primevue/picklist'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'

// Props & Emits
const visible = defineModel<boolean>('visible', { default: false })
const props = defineProps<{
  user: User | null
}>()

const emit = defineEmits<{
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const allRoles = ref<Role[]>([])
const searchQuery = ref('')
const assignedSearchQuery = ref('')

// PickList v-model
const roleLists = ref<[Role[], Role[]]>([[], []])

// Computed
const filteredAvailableRoles = computed(() => {
  if (!searchQuery.value) return roleLists.value[0]
  const query = searchQuery.value.toLowerCase()
  return roleLists.value[0].filter(role =>
    role.name.toLowerCase().includes(query) ||
    role.description?.toLowerCase().includes(query)
  )
})

const filteredAssignedRoles = computed(() => {
  if (!assignedSearchQuery.value) return roleLists.value[1]
  const query = assignedSearchQuery.value.toLowerCase()
  return roleLists.value[1].filter(role =>
    role.name.toLowerCase().includes(query) ||
    role.description?.toLowerCase().includes(query)
  )
})

// Methods
const getRoleColorClass = (roleName: string) => {
  const colorMap: Record<string, string> = {
    admin: 'bg-red-500',
    developer: 'bg-blue-500',
    operator: 'bg-green-500',
    viewer: 'bg-gray-500'
  }
  return colorMap[roleName] || 'bg-purple-500'
}

const loadRoles = async () => {
  try {
    const data = await roleApi.list()
    console.log('Loaded roles:', data)
    allRoles.value = data.roles || data || []
    updateRoleLists()
  } catch (error: any) {
    console.error('加载角色失败:', error.message)
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '获取角色列表失败',
      life: 5000
    })
  }
}

const updateRoleLists = () => {
  if (!props.user || !allRoles.value.length) {
    console.log('No user or roles available')
    roleLists.value = [[], []]
    return
  }

  const userRoleIds = props.user.roles?.map(role => role.id) || []
  console.log('User role IDs:', userRoleIds)
  console.log('All roles:', allRoles.value)

  const assigned = allRoles.value.filter(role => userRoleIds.includes(role.id))
  const available = allRoles.value.filter(role => !userRoleIds.includes(role.id))

  console.log('Available roles:', available)
  console.log('Assigned roles:', assigned)

  roleLists.value = [available, assigned]
}

const handleAssignRoles = async () => {
  if (!props.user) return

  loading.value = true
  const roleIds = roleLists.value[1].map(role => role.id)

  console.log('Assigning roles to user:', props.user.id, 'Role IDs:', roleIds)

  try {
    await userApi.assignRoles(props.user.id, { role_ids: roleIds })
    toast.add({
      severity: 'success',
      summary: '分配成功',
      detail: `已为用户分配 ${roleIds.length} 个角色`,
      life: 3000
    })

    visible.value = false
    emit('success')
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '分配失败',
      detail: error.message || '角色分配失败',
      life: 5000
    })
  } finally {
    loading.value = false
  }
}

// Watch
watch(() => props.user, (newUser) => {
  if (newUser && allRoles.value.length > 0) {
    updateRoleLists()
  }
}, { immediate: true })

watch(() => allRoles.value, () => {
  if (props.user) {
    updateRoleLists()
  }
})

watch(visible, (newValue) => {
  if (newValue) {
    loadRoles()
    searchQuery.value = ''
    assignedSearchQuery.value = ''
  }
})

// Lifecycle
onMounted(() => {
  loadRoles()
})
</script>

<style scoped>
/* PickList 美化样式 */
:deep(.role-picklist .p-picklist-list) {
  border-radius: 8px;
  border: 2px solid var(--surface-200);
  overflow: hidden;
}

:deep(.role-picklist .p-picklist-source-wrapper) {
  margin-right: 1rem;
}

:deep(.role-picklist .p-picklist-target-wrapper) {
  margin-left: 1rem;
}

:deep(.role-picklist .p-picklist-buttons) {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 0.5rem;
  padding: 0 0.5rem;
}

:deep(.role-picklist .p-picklist-buttons .p-button) {
  width: 3rem;
  height: 3rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: all 0.2s ease;
}

:deep(.role-picklist .p-picklist-buttons .p-button:hover) {
  transform: scale(1.05);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

:deep(.role-picklist .p-picklist-list-wrapper) {
  border-radius: 8px;
  overflow: hidden;
}

:deep(.role-picklist .p-picklist-item) {
  transition: all 0.2s ease;
  border: none !important;
}

:deep(.role-picklist .p-picklist-item:hover) {
  transform: translateX(2px);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

:deep(.role-picklist .p-picklist-item.p-picklist-item-selected) {
  background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
  border-left: 4px solid #3b82f6 !important;
}

/* 文本截断样式 */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 自定义滚动条 */
:deep(.p-picklist-list) {
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
}

:deep(.p-picklist-list::-webkit-scrollbar) {
  width: 6px;
}

:deep(.p-picklist-list::-webkit-scrollbar-track) {
  background: #f1f5f9;
  border-radius: 3px;
}

:deep(.p-picklist-list::-webkit-scrollbar-thumb) {
  background: #cbd5e1;
  border-radius: 3px;
}

:deep(.p-picklist-list::-webkit-scrollbar-thumb:hover) {
  background: #94a3b8;
}

/* Dialog 响应式调整 */
@media (max-width: 768px) {
  :deep(.p-dialog) {
    width: 95vw !important;
    height: 90vh !important;
    margin: 0;
  }

  :deep(.role-picklist .p-picklist-buttons) {
    flex-direction: row;
    padding: 0.5rem 0;
    gap: 0.25rem;
  }

  :deep(.role-picklist .p-picklist-buttons .p-button) {
    width: 2.5rem;
    height: 2.5rem;
  }
}
</style>
