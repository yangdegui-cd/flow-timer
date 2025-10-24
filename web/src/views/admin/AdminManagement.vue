<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'

import UserManagementTab from '@/components/admin/UserManagementTab.vue'
import RoleManagementTab from '@/components/admin/RoleManagementTab.vue'
import SystemStatsTab from '@/components/admin/SystemStatsTab.vue'
import AuditLogsTab from '@/components/admin/AuditLogsTab.vue'
import PermissionManagementTab from "@/components/admin/PermissionManagementTab.vue";
import SubPage from "@/views/layer/SubPage.vue";

// Stores
const authStore = useAuthStore()

// Data
const activeTabIndex = ref(0)
const tabs = [
  { label: '用户管理', icon: 'pi pi-users', permission: 'sys_user:view' },
  { label: '角色管理', icon: 'pi pi-shield', permission: 'sys_role:view' },
  { label: '权限管理', icon: 'pi pi-shield', permission: 'sys_user:view' },
  { label: '系统统计', icon: 'pi pi-chart-bar', permission: 'sys_user:view' },
  { label: '审计日志', icon: 'pi pi-file-edit', permission: 'sys_user:view' }
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
    activeTabIndex.value = 1 // 角色管理
  }
})
</script>
<template>
  <sub-page title="系统管理"
            icon="pi pi-server"
            icon-color="text-primary-600"
            description="统一管理用户账号、角色权限等系统资源">
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
        <TabPanels class="admin-tab-panels">
          <TabPanel :value="0" v-if="authStore.hasPermission(tabs[0].permission)">
            <UserManagementTab @refresh="refreshData"/>
          </TabPanel>
          <TabPanel :value="1" v-if="authStore.hasPermission(tabs[1].permission)">
            <RoleManagementTab @refresh="refreshData"/>
          </TabPanel>
          <TabPanel :value="2" v-if="authStore.hasPermission(tabs[2].permission)">
            <PermissionManagementTab/>
          </TabPanel>
          <TabPanel :value="3" v-if="authStore.hasPermission(tabs[3].permission)">
            <SystemStatsTab/>
          </TabPanel>
          <TabPanel :value="4" v-if="authStore.hasPermission(tabs[4].permission)">
            <AuditLogsTab/>
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>
  </sub-page>
</template>


<style scoped>
.admin-management {
  padding: 2rem;
  max-width: 100%;
}

:deep(.admin-tabs) {
  height: 100%;
  display: flex;
  flex-direction: column;

  .p-tabview-nav {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    flex-shrink: 0;
  }

  .p-tabview-panels {
    background: transparent;
    padding: 1.5rem 0 0 0;
    flex: 1;
    min-height: 0;
  }

  .p-tabview-panel {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    padding: 1.5rem;
    height: 100%;
    overflow: auto;
  }
}

/* 设置固定高度，防止页签滚动 */
:deep(.admin-tab-panels) {
  height: calc(100vh - 180px); /* 减去页面头部、标题、页签等高度 */
  overflow: auto;
}

/* 确保各个Tab组件内部可以滚动 */
:deep(.admin-tab-panels .p-tabview-panel) {
  height: 100%;
  overflow-y: auto;
  overflow-x: hidden;
}

/* 自定义滚动条样式 */
:deep(.admin-tab-panels .p-tabview-panel::-webkit-scrollbar) {
  width: 6px;
}

:deep(.admin-tab-panels .p-tabview-panel::-webkit-scrollbar-track) {
  background: #f1f1f1;
  border-radius: 3px;
}

:deep(.admin-tab-panels .p-tabview-panel::-webkit-scrollbar-thumb) {
  background: #c1c1c1;
  border-radius: 3px;
}

:deep(.admin-tab-panels .p-tabview-panel::-webkit-scrollbar-thumb:hover) {
  background: #a8a8a8;
}

/* 确保子组件高度适配 */
:deep(.system-stats-tab),
:deep(.audit-logs-tab),
:deep(.user-management-tab),
:deep(.role-management-tab),
:deep(.permission-management-tab) {
  height: 100%;
  overflow-y: auto;
}
</style>
