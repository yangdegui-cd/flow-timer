<script setup lang="ts">
import { updatePreset } from '@primeuix/themes';
import { onMounted, computed } from "vue";
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

// 导入Divider组件
import Divider from 'primevue/divider';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();

// 导航菜单项
const menuItems = [
  {
    key: 'flows',
    label: '流程管理',
    icon: 'pi pi-sitemap',
    path: '/flows',
    tooltip: '流程设计和管理'
  },
  {
    key: 'tasks',
    label: '任务管理',
    icon: 'pi pi-clock',
    path: '/tasks',
    tooltip: '定时任务调度'
  },
  {
    key: 'execution',
    label: '执行记录',
    icon: 'pi pi-play-circle',
    path: '/execution',
    tooltip: '任务执行历史'
  },
  {
    key: 'resque-monitor',
    label: '任务监控',
    icon: 'pi pi-server',
    path: '/resque-monitor',
    tooltip: 'Resque任务监控'
  },
  {
    key: 'metadata',
    label: '元数据管理',
    icon: 'pi pi-database',
    path: '/metadata',
    tooltip: '数据源和连接管理'
  },
  {
    key: 'monitoring',
    label: '监控面板',
    icon: 'pi pi-chart-line',
    path: '/monitoring',
    tooltip: '系统监控和统计'
  }
];

// 系统管理菜单项（需要权限）
const adminMenuItems = [
  {
    key: 'admin-management',
    label: '系统管理',
    icon: 'pi pi-users',
    path: '/admin',
    tooltip: '用户、角色和系统管理',
    permission: null // 只要有任何管理权限即可访问
  }
];

const settingsItems = [
  {
    key: 'settings',
    label: '系统设置',
    icon: 'pi pi-cog',
    path: '/settings',
    tooltip: '系统配置'
  }
];

// 可见的管理菜单项（基于权限过滤）
const visibleAdminItems = computed(() => {
  return adminMenuItems.filter(item => {
    // 检查是否有任何管理权限
    return authStore.hasPermission('manage_users') ||
           authStore.hasPermission('manage_roles') ||
           authStore.hasPermission('manage_system');
  });
});

// 当前活跃的菜单项
const activeKey = computed(() => {
  const currentPath = route.path;
  // 检查当前路径是否匹配菜单项
  const allItems = [...menuItems, ...visibleAdminItems.value, ...settingsItems];
  const matched = allItems.find(item => {
    if (currentPath === item.path) return true;
    if (currentPath.startsWith(item.path + '/')) return true;
    return false;
  });
  return matched?.key || '';
});

// 导航到指定路径
const navigateTo = (path: string) => {
  if (route.path !== path) {
    router.push(path);
  }
};

// 判断菜单项是否激活
const isActive = (key: string) => {
  return activeKey.value === key;
};

// 登出功能
const logout = async () => {
  try {
    await authStore.logout();
    router.push('/auth/login');
  } catch (error) {
    console.error('登出失败:', error);
  }
};

function changePrimaryColor() {
  updatePreset({
    semantic: {
      primary: {
        50: '{indigo.50}',
        100: '{indigo.100}',
        200: '{indigo.200}',
        300: '{indigo.300}',
        400: '{indigo.400}',
        500: '{indigo.500}',
        600: '{indigo.600}',
        700: '{indigo.700}',
        800: '{indigo.800}',
        900: '{indigo.900}',
        950: '{indigo.950}'
      }
    }
  })
}

onMounted(async () => {
  changePrimaryColor();

  // 初始化用户状态
  if (authStore.token && !authStore.user) {
    try {
      await authStore.init();
    } catch (error) {
      console.error('初始化用户状态失败:', error);
    }
  }
});
</script>

<template>
  <div class="w-auto rounded-2xl p-5 bg-surface-50 dark:bg-surface-900 h-full flex flex-col justify-between">
    <!-- 顶部区域 -->
    <div class="w-12 flex flex-col items-center">
      <!-- Logo区域 -->
      <div class="flex items-center gap-3 mb-8">
        <div class="w-11 h-11 border border-primary rounded-xl flex items-center justify-center bg-primary/10">
          <i class="pi pi-clock text-xl text-primary"></i>
        </div>
        <div class="hidden text-surface-950 dark:text-surface-0 font-medium text-xl">FlowTimer</div>
      </div>

      <!-- 主要导航菜单 -->
      <div class="flex flex-col gap-2">
        <div
            v-for="item in menuItems"
            :key="item.key"
            @click="navigateTo(item.path)"
            v-tooltip.right="item.tooltip"
            :class="[
              'px-4 py-1 flex items-center gap-3 cursor-pointer text-base rounded-lg transition-all select-none w-12 justify-center py-4',
              isActive(item.key)
                ? 'text-primary-contrast bg-primary hover:bg-primary-emphasis'
                : 'text-muted-color hover:bg-emphasis bg-transparent hover:text-primary'
            ]">
          <i :class="item.icon"></i>
          <span class="hidden">・</span>
          <span class="hidden">{{ item.label }}</span>
        </div>
      </div>

      <!-- 管理菜单分隔 -->
      <div v-if="visibleAdminItems.length > 0" class="mt-6 mb-2">
        <div class="w-full h-px bg-surface-200 dark:bg-surface-700"></div>
      </div>

      <!-- 管理菜单 -->
      <div v-if="visibleAdminItems.length > 0" class="flex flex-col gap-2">
        <div
            v-for="item in visibleAdminItems"
            :key="item.key"
            @click="navigateTo(item.path)"
            v-tooltip.right="item.tooltip"
            :class="[
              'px-4 py-1 flex items-center gap-3 cursor-pointer text-base rounded-lg transition-all select-none w-12 justify-center py-4',
              isActive(item.key)
                ? 'text-primary-contrast bg-primary hover:bg-primary-emphasis'
                : 'text-muted-color hover:bg-emphasis bg-transparent hover:text-primary'
            ]">
          <i :class="item.icon"></i>
          <span class="hidden">・</span>
          <span class="hidden">{{ item.label }}</span>
        </div>
      </div>

      <!-- 状态指示器 -->
      <div class="mt-8 w-full">
        <div class="flex items-center justify-center">
          <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse" v-tooltip.right="'系统运行正常'"></div>
        </div>
      </div>
    </div>

    <!-- 底部区域 -->
    <div class="w-12 flex flex-col items-center">
      <!-- 设置菜单 -->
      <div class="flex flex-col gap-2 mb-4">
        <div
            v-for="item in settingsItems"
            :key="item.key"
            @click="navigateTo(item.path)"
            v-tooltip.right="item.tooltip"
            :class="[
              'px-4 py-1 flex items-center gap-3 cursor-pointer text-base rounded-lg transition-all select-none w-12 justify-center py-4',
              isActive(item.key)
                ? 'text-primary-contrast bg-primary hover:bg-primary-emphasis'
                : 'text-muted-color hover:bg-emphasis bg-transparent hover:text-primary'
            ]">
          <i :class="item.icon"></i>
          <span class="hidden">・</span>
          <span class="hidden">{{ item.label }}</span>
        </div>
      </div>

      <!-- 分隔线 -->
      <Divider class="my-2 opacity-50" />

      <!-- 用户信息区域 -->
      <div v-if="authStore.isAuthenticated" class="justify-center flex items-center mt-2">
        <div
          class="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center cursor-pointer hover:bg-primary/30 transition-colors"
          @click="navigateTo('/profile')"
          :v-tooltip.right="authStore.user?.name || '用户'"
        >
          <i v-if="!authStore.user?.avatar_url" class="pi pi-user text-sm text-primary"></i>
          <img
            v-else
            :src="authStore.user.avatar_url"
            :alt="authStore.user.name"
            class="w-full h-full rounded-full object-cover"
          />
        </div>
        <div class="hidden ml-2">
          <div class="text-sm font-medium">{{ authStore.user?.name }}</div>
          <div class="text-xs text-muted-color">{{ authStore.user?.email }}</div>
        </div>
      </div>

      <!-- 未登录状态 -->
      <div v-else class="justify-center flex items-center mt-2">
        <div
          class="w-8 h-8 rounded-full bg-surface-200 dark:bg-surface-700 flex items-center justify-center cursor-pointer hover:bg-surface-300 dark:hover:bg-surface-600 transition-colors"
          @click="navigateTo('/auth/login')"
          v-tooltip.right="'点击登录'"
        >
          <i class="pi pi-sign-in text-sm text-muted-color"></i>
        </div>
      </div>

      <!-- 登出按钮 -->
      <div v-if="authStore.isAuthenticated" class="mt-2">
        <div
          @click="logout"
          v-tooltip.right="'退出登录'"
          class="w-8 h-8 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center cursor-pointer hover:bg-red-200 dark:hover:bg-red-800/50 transition-colors mx-auto"
        >
          <i class="pi pi-sign-out text-sm text-red-600 dark:text-red-400"></i>
        </div>
      </div>

      <!-- 版本信息 -->
      <Tag class="mt-4 text-xs text-muted-color text-center">
        <div>v1.0.0</div>
      </Tag>
    </div>
  </div>
</template>

<style scoped>
@import "../../styles/layout.scss";
@import "../../styles/icon.scss";
</style>
