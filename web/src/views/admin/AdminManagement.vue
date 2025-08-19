<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

import UserManagementTab from '@/components/admin/UserManagementTab.vue'
import RoleManagementTab from '@/components/admin/RoleManagementTab.vue'
import SystemStatsTab from '@/components/admin/SystemStatsTab.vue'
import AuditLogsTab from '@/components/admin/AuditLogsTab.vue'

// Stores
const authStore = useAuthStore()

// Data
const activeTabIndex = ref(0)
const tabs = [
  { label: '用户管理', icon: 'pi pi-users', permission: 'manage_users' },
  { label: '角色管理', icon: 'pi pi-shield', permission: 'manage_roles' },
  { label: '系统统计', icon: 'pi pi-chart-bar', permission: 'manage_system' },
  { label: '审计日志', icon: 'pi pi-file-edit', permission: 'manage_system' }
]

// Methods
const refreshData = () => {
  // 刷新数据的通用方法，可以根据需要扩展
  console.log('Refreshing admin data...')
}

// Lifecycle
onMounted(() => {
  // 根据权限设置默认激活的标签页
  if (!authStore.hasPermission('manage_users') && authStore.hasPermission('manage_roles')) {
    activeTabIndex.value = 0 // 角色管理
  }
})
</script>
<template>
  <div class="h-full flex flex-col bg-gray-50 w-full">
    <div class="bg-white border-b border-surface p-6">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900 flex items-center gap-3">
            <i class="pi pi-server text-blue-600"></i>
            系统管理
          </h1>
          <p class="text-gray-600 mt-1">统一管理用户账号、角色权限等系统资源</p>
        </div>
      </div>
    </div>

    <div>
      <!-- 标签页导航 -->
      <Tabs v-model:value="activeTabIndex" class="admin-tabs" content-class="p-4">
        <TabList>
          <template v-for="(tab,index) in tabs">
            <Tab :value="index" :key="index" v-if="authStore.hasPermission(tab.permission)">
              <div class="flex items-center space-x-2">
                <i :class="tab.icon"></i>
                <span>{{ tab.label }}</span>
              </div>
            </Tab>
          </template>
        </TabList>
        <TabPanels class="h-2/3">
          <TabPanel :value="0">
            <UserManagementTab @refresh="refreshData"/>
          </TabPanel>
          <TabPanel :value="1">
            <RoleManagementTab @refresh="refreshData"/>
          </TabPanel>
          <TabPanel :value="2">
            <SystemStatsTab/>
          </TabPanel>
          <TabPanel :value="3">
            <AuditLogsTab/>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>
  </div>
</template>


<style scoped>
.admin-management {
  padding: 2rem;
  max-width: 100%;
}

:deep(.admin-tabs) {
  .p-tabview-nav {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }

  .p-tabview-panels {
    background: transparent;
    padding: 1.5rem 0 0 0;
  }

  .p-tabview-panel {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    padding: 1.5rem;
  }
}
</style>
