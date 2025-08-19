import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // 认证路由
    {
      path: '/auth/login',
      name: 'login',
      component: () => import('@/views/auth/AuthPage.vue'),
      meta: {
        title: '用户登录',
        requiresGuest: true
      }
    },
    {
      path: '/auth/register',
      name: 'register',
      component: () => import('@/views/auth/AuthPage.vue'),
      meta: {
        title: '用户注册',
        requiresGuest: true
      }
    },
    // OAuth回调路由
    {
      path: '/auth/:provider/callback',
      name: 'oauth-callback',
      component: () => import('@/views/OAuthCallback.vue'),
      meta: {
        title: 'OAuth认证中'
      }
    },
    // OAuth成功页面
    {
      path: '/auth/oauth-success',
      name: 'oauth-success',
      component: () => import('@/views/auth/OAuthSuccess.vue'),
      meta: {
        title: 'OAuth登录成功'
      }
    },
    // OAuth错误页面
    {
      path: '/auth/oauth-error',
      name: 'oauth-error',
      component: () => import('@/views/auth/OAuthError.vue'),
      meta: {
        title: 'OAuth登录失败'
      }
    },
    // 系统管理路由
    {
      path: "/",
      name: 'home',
      redirect: '/flows',
      component: () => import('@/views/layer/Layout.vue'),
      children: [
        {
          path: '/admin',
          name: 'admin-management',
          component: () => import('@/views/admin/AdminManagement.vue'),
          meta: {
            title: '系统管理',
            icon: 'pi pi-cog',
            requiresAuth: true,
            requiresPermission: null // 在组件内部检查具体权限
          }
        },
        // 保留旧路由以便兼容
        {
          path: '/admin/users',
          redirect: '/admin'
        },
        {
          path: '/admin/roles',
          redirect: '/admin'
        },
        {
          path: '/profile',
          name: 'profile',
          component: () => import('@/views/sub-pages/user/ProfilePage.vue'),
          meta: {
            title: '个人资料',
            requiresAuth: true
          }
        },
        // 流程管理相关路由
        {
          path: '/flows',
          name: 'flows',
          component: () => import('@/views/sub-pages/flow/Flow.vue'),
          meta: {
            title: '流程管理',
            icon: 'pi pi-sitemap'
          }
        },
        {
          path: '/flows/add',
          name: 'flows-add',
          component: () => import('@/views/sub-pages/flow/Edit.vue'),
          meta: {
            title: '新增流程',
            parent: 'flows'
          }
        },
        {
          path: "/flows/edit",
          name: 'flows-edit',
          component: () => import('@/views/sub-pages/flow/Edit.vue'),
          meta: {
            title: '编辑流程',
            parent: 'flows'
          }
        },
        // 任务管理相关路由
        {
          path: '/tasks',
          name: 'tasks',
          component: () => import('@/views/sub-pages/task/Task.vue'),
          meta: {
            title: '任务管理',
            icon: 'pi pi-clock'
          }
        },
        {
          path: '/task/add',
          name: 'task-add',
          component: () => import('@/views/sub-pages/task/Edit.vue'),
          meta: {
            title: '新增任务',
            parent: 'tasks'
          }
        },
        {
          path: '/task/edit',
          name: 'task-edit',
          component: () => import('@/views/sub-pages/task/Edit.vue'),
          meta: {
            title: '编辑任务',
            parent: 'tasks'
          }
        },
        // 执行记录
        {
          path: '/execution',
          name: 'execution',
          component: () => import('@/views/sub-pages/execution/Execution.vue'),
          meta: {
            title: '执行记录',
            icon: 'pi pi-play-circle'
          }
        },
        // 任务监控
        {
          path: '/resque-monitor',
          name: 'resque-monitor',
          component: () => import('@/views/sub-pages/resque/ResqueMonitor.vue'),
          meta: {
            title: '任务监控',
            icon: 'pi pi-server'
          }
        },
        // 元数据管理相关路由
        {
          path: '/metadata',
          name: 'metadata',
          component: () => import('@/views/sub-pages/metadata/Metadata.vue'),
          meta: {
            title: '元数据管理',
            icon: 'pi pi-database'
          }
        },
        {
          path: '/metadata/hosts',
          name: 'metadata-hosts',
          component: () => import('@/views/sub-pages/metadata/HostList.vue'),
          meta: {
            title: '主机管理',
            parent: 'metadata'
          }
        },
        {
          path: '/metadata/mysql',
          name: 'metadata-mysql',
          component: () => import('@/views/sub-pages/metadata/MysqlList.vue'),
          meta: {
            title: 'MySQL管理',
            parent: 'metadata'
          }
        },
        {
          path: '/metadata/trino',
          name: 'metadata-trino',
          component: () => import('@/views/sub-pages/metadata/TrinoList.vue'),
          meta: {
            title: 'Trino管理',
            parent: 'metadata'
          }
        },
        {
          path: '/metadata/hdfs',
          name: 'metadata-hdfs',
          component: () => import('@/views/sub-pages/metadata/HdfsList.vue'),
          meta: {
            title: 'HDFS管理',
            parent: 'metadata'
          }
        },
        {
          path: '/metadata/databases',
          name: 'metadata-databases',
          component: () => import('@/views/sub-pages/metadata/DatasourceList.vue'),
          meta: {
            title: 'SQL数据库源',
            parent: 'metadata'
          }
        },
        // 监控面板
        {
          path: '/monitoring',
          name: 'monitoring',
          component: () => import('@/views/sub-pages/monitoring/Monitoring.vue'),
          meta: {
            title: '监控面板',
            icon: 'pi pi-chart-line'
          }
        },
        // 系统设置
        {
          path: '/settings',
          name: 'settings',
          component: () => import('@/views/sub-pages/setting/Settings.vue'),
          meta: {
            title: '系统设置',
            icon: 'pi pi-cog'
          }
        },
        // 账号绑定管理
        {
          path: '/settings/account',
          name: 'account-binding',
          component: () => import('@/views/sub-pages/setting/AccountBinding.vue'),
          meta: {
            title: '账号绑定',
            parent: 'settings',
            requiresAuth: true
          }
        },
        // 404 页面
        {
          path: '/:pathMatch(.*)*',
          name: 'not-found',
          redirect: '/flows'
        }
      ]
    }
  ]
})

// 路由守卫
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // 初始化用户状态
  if (authStore.token && !authStore.user) {
    await authStore.init()
  }

  // 如果路由需要游客权限（如登录页），但用户已登录，重定向到首页
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next('/')
    return
  }

  // 如果路由需要认证，但用户未登录，重定向到登录页
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({
      path: '/auth/login',
      query: { redirect: to.fullPath }
    })
    return
  }

  // 如果路由需要特定权限，检查用户权限
  if (to.meta.requiresPermission && authStore.isAuthenticated) {
    if (!authStore.hasPermission(to.meta.requiresPermission)) {
      // 权限不足，显示403页面或重定向
      next('/')
      return
    }
  }

  // 特殊检查：系统管理页面需要任一管理权限
  if (to.name === 'admin-management' && authStore.isAuthenticated) {
    const hasAnyAdminPermission = authStore.hasPermission('manage_users') ||
      authStore.hasPermission('manage_roles') ||
      authStore.hasPermission('manage_system')
    if (!hasAnyAdminPermission) {
      next('/')
      return
    }
  }

  next()
})

export default router
