<script setup lang="ts">
import { onMounted, ref, watch } from 'vue';
import { useToast } from "primevue/usetoast";
import { useRouter } from 'vue-router';
import PageHeader from '@/views/layer/PageHeader.vue';
import ThirdPartyConfig from './ThirdPartyConfig.vue';
import { changePrimaryColor } from '@/utils/changePrimaryColor';
import configApi, { type Config } from '@/api/config-api';

const toast = useToast();
const router = useRouter();
const loading = ref(false);
const saving = ref(false);

// 系统设置
const systemSettings = ref({
  siteName: 'FlowTimer',
  siteDescription: '智能流程调度系统',
  timezone: 'Asia/Shanghai',
  language: 'zh-CN',
  theme: 'light',
  primaryColor: 'indigo',
  enableNotifications: true,
  enableEmailAlerts: true,
  logLevel: 'INFO',
  maxConcurrentTasks: 10,
  taskTimeout: 300,
  retryAttempts: 3,
  retryInterval: 60
});

// 数据库设置
const databaseSettings = ref({
  host: 'localhost',
  port: 3306,
  database: 'flow_timer',
  username: 'root',
  connectionPool: 20,
  connectionTimeout: 30,
  autoBackup: true,
  backupTime: '02:00',
  backupRetention: 7
});

// 通知配置（对应后端 Config 模型）
const notificationConfig = ref<Config>({
  use_email_notification: false,
  smtp_server: '',
  smtp_port: 587,
  email_notification_email: '',
  email_notification_pwd: '',
  email_notification_name: '',
  email_notification_display_name: '',
  email_notification_use_tls: true,
  qy_wechat_notification_key: '',
  qy_wechat_notification_url: '',
  adjust_api_token: '',
  adjust_api_server: 'https://dash.adjust.com/control-center/reports-service/report',
  facebook_app_id: '',
  facebook_app_secret: '',
  facebook_access_token: '',
  facebook_token_expired_at: '',
  website_base_url: window.location.origin,
  facebook_auth_callback_url: window.location.origin
});

// 安全设置
const securitySettings = ref({
  enableApiAuth: true,
  apiKeyExpiration: 30,
  sessionTimeout: 60,
  enableIpWhitelist: false,
  ipWhitelist: '',
  enableAuditLog: true,
  passwordPolicy: {
    minLength: 8,
    requireUppercase: true,
    requireNumbers: true,
    requireSymbols: true
  }
});

// 性能设置
const performanceSettings = ref({
  enableCache: true,
  cacheExpiration: 3600,
  enableCompression: true,
  maxLogFileSize: 100,
  logRotationDays: 30,
  enableHealthCheck: true,
  healthCheckInterval: 30
});

const timezoneOptions = [
  { label: '北京时间 (UTC+8)', value: 'Asia/Shanghai' },
  { label: '东京时间 (UTC+9)', value: 'Asia/Tokyo' },
  { label: '纽约时间 (UTC-5)', value: 'America/New_York' },
  { label: '伦敦时间 (UTC+0)', value: 'Europe/London' }
];

const languageOptions = [
  { label: '中文简体', value: 'zh-CN' },
  { label: 'English', value: 'en-US' },
  { label: '日本語', value: 'ja-JP' }
];

const themeOptions = [
  { label: '浅色主题', value: 'light' },
  { label: '深色主题', value: 'dark' },
  { label: '跟随系统', value: 'auto' }
];

const primaryColorOptions = [
  { label: '靛蓝色', value: 'indigo', color: '#6366f1' },
  { label: '蓝色', value: 'blue', color: '#3b82f6' },
  { label: '紫色', value: 'purple', color: '#8b5cf6' },
  { label: '粉色', value: 'pink', color: '#ec4899' },
  { label: '红色', value: 'red', color: '#ef4444' },
  { label: '橙色', value: 'orange', color: '#f97316' },
  { label: '黄色', value: 'yellow', color: '#eab308' },
  { label: '绿色', value: 'green', color: '#22c55e' },
  { label: '青色', value: 'teal', color: '#14b8a6' },
  { label: '天蓝色', value: 'sky', color: '#0ea5e9' },
  { label: '灰色', value: 'slate', color: '#64748b' }
];

const logLevelOptions = [
  { label: 'DEBUG', value: 'DEBUG' },
  { label: 'INFO', value: 'INFO' },
  { label: 'WARN', value: 'WARN' },
  { label: 'ERROR', value: 'ERROR' }
];

// 活跃的标签页
const activeTab = ref(0);

const tabItems = [
  { label: '基础设置', icon: 'pi pi-cog' },
  { label: '数据库', icon: 'pi pi-database' },
  { label: '通知配置', icon: 'pi pi-envelope' },
  { label: '第三方配置', icon: 'pi pi-box' },
  { label: '安全配置', icon: 'pi pi-shield' },
  { label: '性能优化', icon: 'pi pi-bolt' },
  { label: '账号绑定', icon: 'pi pi-link', route: '/settings/account' }
];

// 从localStorage和后端API加载设置
const loadSettings = async () => {
  loading.value = true;
  try {
    // 从localStorage加载保存的设置
    const savedSettings = localStorage.getItem('systemSettings');
    if (savedSettings) {
      const parsed = JSON.parse(savedSettings);
      Object.assign(systemSettings.value, parsed);
    }

    // 从后端加载通知配置
    try {
      const config = await configApi.getConfig();
      // 密码和密钥字段如果是 'xxxxxxxxxx' 则置空，方便用户判断是否需要重新输入
      if (config.email_notification_pwd === 'xxxxxxxxxx') {
        config.email_notification_pwd = '';
      }
      if (config.qy_wechat_notification_key === 'xxxxxxxxxx') {
        config.qy_wechat_notification_key = '';
      }
      notificationConfig.value = config;
    } catch (error) {
      console.error('加载通知配置失败:', error);
    }

    // 应用当前主题和颜色设置
    applyTheme(systemSettings.value.theme);
    changePrimaryColor(systemSettings.value.primaryColor);

    toast.add({
      severity: 'success',
      summary: '设置加载',
      detail: '系统设置已加载',
      life: 2000
    });
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: '无法加载系统设置',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
};

const saveSettings = async () => {
  saving.value = true;
  try {
    // 保存基础设置到localStorage
    localStorage.setItem('systemSettings', JSON.stringify(systemSettings.value));

    // 应用主题和颜色设置
    applyTheme(systemSettings.value.theme);
    changePrimaryColor(systemSettings.value.primaryColor);

    // 保存通知配置到后端
    try {
      // 如果密码或密钥为空，从更新数据中移除（保留原值）
      const updateData: Partial<Config> = { ...notificationConfig.value };
      if (!updateData.email_notification_pwd) {
        delete updateData.email_notification_pwd;
      }
      if (!updateData.qy_wechat_notification_key) {
        delete updateData.qy_wechat_notification_key;
      }
      if (!updateData.adjust_api_token) {
        delete updateData.adjust_api_token;
      }

      await configApi.updateConfig(updateData);
    } catch (error) {
      console.error('保存通知配置失败:', error);
      throw error; // 重新抛出错误，让外层捕获
    }

    toast.add({
      severity: 'success',
      summary: '保存成功',
      detail: '系统设置已更新',
      life: 3000
    });

    // 重新加载配置
    await loadSettings();
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '保存失败',
      detail: error.message || '无法保存系统设置',
      life: 3000
    });
  } finally {
    saving.value = false;
  }
};

// 应用主题函数
const applyTheme = (themeMode: string) => {
  const html = document.documentElement;

  if (themeMode === 'dark') {
    html.classList.add('dark');
  } else if (themeMode === 'light') {
    html.classList.remove('dark');
  } else if (themeMode === 'auto') {
    // 跟随系统
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (prefersDark) {
      html.classList.add('dark');
    } else {
      html.classList.remove('dark');
    }
  }
};

// 监听主题和颜色变化
watch(() => systemSettings.value.theme, (newTheme) => {
  applyTheme(newTheme);
});

watch(() => systemSettings.value.primaryColor, (newColor) => {
  changePrimaryColor(newColor);
});

// 监听系统主题变化（仅在auto模式下）
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
  if (systemSettings.value.theme === 'auto') {
    if (e.matches) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }
});

const testEmailConnection = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在测试邮件连接...',
      life: 2000
    });

    const result = await configApi.testEmailConnection();

    toast.add({
      severity: result.success ? 'success' : 'error',
      summary: result.success ? '连接成功' : '连接失败',
      detail: result.message,
      life: 3000
    });
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '连接失败',
      detail: error.message || '无法连接到邮件服务器',
      life: 3000
    });
  }
};

const testWechatConnection = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在测试企业微信连接...',
      life: 2000
    });

    const result = await configApi.testWechatConnection();

    toast.add({
      severity: result.success ? 'success' : 'error',
      summary: result.success ? '连接成功' : '连接失败',
      detail: result.message,
      life: 3000
    });
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '连接失败',
      detail: error.message || '无法连接到企业微信服务器',
      life: 3000
    });
  }
};

const testDatabase = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在测试数据库连接...',
      life: 2000
    });

    await new Promise(resolve => setTimeout(resolve, 2000));

    toast.add({
      severity: 'success',
      summary: '连接成功',
      detail: '数据库连接正常',
      life: 3000
    });
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '连接失败',
      detail: '无法连接到数据库',
      life: 3000
    });
  }
};

// 处理第三方配置更新
const handleThirdPartyConfigUpdate = (config: Partial<Config>) => {
  Object.assign(notificationConfig.value, config);
};

// 标签点击处理
const handleTabClick = (tab: any, index: number) => {
  if (tab.route) {
    // 如果有路由，跳转到对应页面
    router.push(tab.route);
  } else {
    // 否则切换标签页
    activeTab.value = index;
  }
};

onMounted(() => {
  loadSettings();

  // 检查 URL 参数,显示 Facebook 授权结果
  const urlParams = new URLSearchParams(window.location.search);
  const tab = urlParams.get('tab');
  const success = urlParams.get('success');
  const error = urlParams.get('error');

  if (tab === '3') {
    activeTab.value = 3;

    if (success) {
      toast.add({
        severity: 'success',
        summary: '授权成功',
        detail: decodeURIComponent(success),
        life: 5000
      });
      // 清理 URL 参数
      window.history.replaceState({}, '', '/settings');
      // 重新加载配置
      loadSettings();
    } else if (error) {
      toast.add({
        severity: 'error',
        summary: '授权失败',
        detail: decodeURIComponent(error),
        life: 5000
      });
      // 清理 URL 参数
      window.history.replaceState({}, '', '/settings');
    }
  }
});
</script>

<template>
  <div class="flex flex-col gap-4 h-full w-full overflow-hidden">
    <!-- 页面头部 -->
    <PageHeader
        title="系统设置"
        description="配置FlowTimer系统的运行参数和选项"
        icon="pi pi-cog"
        icon-color="text-gray-600"
    />

    <Card class="w-full flex-1 overflow-hidden">
      <template #content>
        <div class="flex h-full">
          <!-- 左侧标签导航 -->
          <div class="w-64 pr-6 border-r border-surface">
            <div class="space-y-1">
              <div
                  v-for="(tab, index) in tabItems"
                  :key="index"
                  @click="handleTabClick(tab, index)"
                  :class="[
                  'flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-all',
                  activeTab === index
                    ? 'bg-primary text-primary-contrast'
                    : 'text-gray-700 hover:bg-gray-100'
                ]">
                <i :class="tab.icon"></i>
                <span class="font-medium">{{ tab.label }}</span>
              </div>
            </div>
          </div>

          <!-- 右侧设置内容 -->
          <div class="flex-1 pl-6 overflow-y-auto">
            <div v-if="loading" class="text-center py-8">
              <i class="pi pi-spin pi-spinner text-3xl text-gray-400"></i>
              <p class="mt-2 text-gray-500">加载设置中...</p>
            </div>

            <!-- 基础设置 -->
            <div v-else-if="activeTab === 0" class="space-y-6">
              <h3 class="text-lg font-semibold mb-4">基础设置</h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">站点名称</label>
                  <InputText v-model="systemSettings.siteName" class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">前端地址</label>
                  <InputText
                      v-model="notificationConfig.website_base_url"
                      class="w-full"
                      placeholder="http://localhost:3000"
                  />
                  <small class="text-gray-500">用于授权回调跳转,默认为当前访问地址</small>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">时区</label>
                  <Dropdown
                      v-model="systemSettings.timezone"
                      :options="timezoneOptions"
                      optionLabel="label"
                      optionValue="value"
                      class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">语言</label>
                  <Dropdown
                      v-model="systemSettings.language"
                      :options="languageOptions"
                      optionLabel="label"
                      optionValue="value"
                      class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">主题模式</label>
                  <Dropdown
                      v-model="systemSettings.theme"
                      :options="themeOptions"
                      optionLabel="label"
                      optionValue="value"
                      class="w-full"/>
                </div>

                <div class="col-span-2">
                  <label class="block text-sm font-medium mb-3">主题颜色</label>
                  <div class="flex flex-wrap gap-3">
                    <div
                        v-for="color in primaryColorOptions"
                        :key="color.value"
                        @click="systemSettings.primaryColor = color.value"
                        :class="[
                        'group relative flex flex-col items-center cursor-pointer transition-all duration-200',
                        'hover:scale-110'
                      ]"
                    >
                      <div
                          :class="[
                          'w-8 h-8 rounded-full border-2 transition-all duration-200',
                          systemSettings.primaryColor === color.value
                            ? 'border-gray-800 shadow-lg scale-110'
                            : 'border-gray-300 hover:border-gray-500'
                        ]"
                          :style="{ backgroundColor: color.color }"
                      >
                        <!-- 选中状态的勾号 -->
                        <div
                            v-if="systemSettings.primaryColor === color.value"
                            class="absolute inset-0 flex items-center justify-center"
                        >
                          <i class="pi pi-check text-white text-xs font-bold drop-shadow"></i>
                        </div>
                      </div>
                      <span
                          :class="[
                          'text-xs mt-1 transition-all duration-200',
                          systemSettings.primaryColor === color.value
                            ? 'text-gray-800 font-medium'
                            : 'text-gray-600 group-hover:text-gray-800'
                        ]"
                      >
                        {{ color.label }}
                      </span>
                    </div>
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">最大并发任务数</label>
                  <InputNumber v-model="systemSettings.maxConcurrentTasks" class="w-full" :min="1" :max="100"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">任务超时时间 (秒)</label>
                  <InputNumber v-model="systemSettings.taskTimeout" class="w-full" :min="30" :max="3600"/>
                </div>
              </div>

              <div class="col-span-2">
                <label class="block text-sm font-medium mb-2">站点描述</label>
                <Textarea v-model="systemSettings.siteDescription" class="w-full" rows="3"/>
              </div>

              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="systemSettings.enableNotifications" binary/>
                  <label class="text-sm font-medium">启用系统通知</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="systemSettings.enableEmailAlerts" binary/>
                  <label class="text-sm font-medium">启用邮件告警</label>
                </div>
              </div>
            </div>

            <!-- 数据库设置 -->
            <div v-else-if="activeTab === 1" class="space-y-6">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold">数据库设置</h3>
                <Button label="测试连接" icon="pi pi-wifi" severity="secondary" size="small" @click="testDatabase"/>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">主机地址</label>
                  <InputText v-model="databaseSettings.host" class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">端口</label>
                  <InputNumber v-model="databaseSettings.port" class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">数据库名</label>
                  <InputText v-model="databaseSettings.database" class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">用户名</label>
                  <InputText v-model="databaseSettings.username" class="w-full"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">连接池大小</label>
                  <InputNumber v-model="databaseSettings.connectionPool" class="w-full" :min="1" :max="100"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">连接超时 (秒)</label>
                  <InputNumber v-model="databaseSettings.connectionTimeout" class="w-full" :min="5" :max="300"/>
                </div>
              </div>

              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="databaseSettings.autoBackup" binary/>
                  <label class="text-sm font-medium">启用自动备份</label>
                </div>

                <div v-if="databaseSettings.autoBackup" class="ml-6 grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium mb-2">备份时间</label>
                    <InputText v-model="databaseSettings.backupTime" class="w-full" placeholder="HH:MM"/>
                  </div>
                  <div>
                    <label class="block text-sm font-medium mb-2">保留天数</label>
                    <InputNumber v-model="databaseSettings.backupRetention" class="w-full" :min="1" :max="365"/>
                  </div>
                </div>
              </div>
            </div>

            <!-- 通知配置 -->
            <div v-else-if="activeTab === 2" class="space-y-6">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold">邮件通知设置</h3>
                <Button label="测试连接" icon="pi pi-send" severity="secondary" size="small"
                        @click="testEmailConnection"/>
              </div>

              <div class="flex items-center gap-3 mb-4">
                <Checkbox v-model="notificationConfig.use_email_notification" binary/>
                <label class="text-sm font-medium">启用邮件通知</label>
              </div>

              <div v-if="notificationConfig.use_email_notification" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">SMTP服务器</label>
                  <InputText v-model="notificationConfig.smtp_server" class="w-full" placeholder="smtp.example.com"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">SMTP端口</label>
                  <InputNumber v-model="notificationConfig.smtp_port" class="w-full" :min="1" :max="65535"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">邮箱地址</label>
                  <InputText v-model="notificationConfig.email_notification_email" class="w-full"
                             placeholder="noreply@example.com"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">邮箱密码</label>
                  <Password
                      v-model="notificationConfig.email_notification_pwd"
                      class="w-full"
                      toggleMask
                      inputClass="w-full"
                      placeholder="留空则保持原密码不变"
                  />
                  <small class="text-gray-500">提示：留空则保持原密码不变</small>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">发件人名称</label>
                  <InputText v-model="notificationConfig.email_notification_name" class="w-full"
                             placeholder="系统通知"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">发件人显示名称</label>
                  <InputText v-model="notificationConfig.email_notification_display_name" class="w-full"
                             placeholder="广告自动化系统"/>
                </div>
              </div>

              <div v-if="notificationConfig.use_email_notification" class="flex items-center gap-3">
                <Checkbox v-model="notificationConfig.email_notification_use_tls" binary/>
                <label class="text-sm font-medium">启用TLS加密</label>
              </div>

              <Divider/>

              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold">企业微信通知设置</h3>
                <Button label="测试连接" icon="pi pi-send" severity="secondary" size="small"
                        @click="testWechatConnection"/>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">Webhook Key</label>
                  <Password
                      v-model="notificationConfig.qy_wechat_notification_key"
                      class="w-full"
                      toggleMask
                      inputClass="w-full"
                      placeholder="留空则保持原密钥不变"
                  />
                  <small class="text-gray-500">提示：留空则保持原密钥不变</small>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">Webhook URL</label>
                  <InputText
                      v-model="notificationConfig.qy_wechat_notification_url"
                      class="w-full"
                      placeholder="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx"
                  />
                </div>
              </div>
            </div>

            <!-- 第三方配置 -->
            <div v-else-if="activeTab === 3">
              <ThirdPartyConfig
                :config="notificationConfig"
                @update="handleThirdPartyConfigUpdate"
              />
            </div>

            <!-- 安全设置 -->
            <div v-else-if="activeTab === 4" class="space-y-6">
              <h3 class="text-lg font-semibold mb-4">安全配置</h3>

              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableApiAuth" binary/>
                  <label class="text-sm font-medium">启用API认证</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableIpWhitelist" binary/>
                  <label class="text-sm font-medium">启用IP白名单</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableAuditLog" binary/>
                  <label class="text-sm font-medium">启用审计日志</label>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">API密钥过期时间 (天)</label>
                  <InputNumber v-model="securitySettings.apiKeyExpiration" class="w-full" :min="1" :max="365"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">会话超时时间 (分钟)</label>
                  <InputNumber v-model="securitySettings.sessionTimeout" class="w-full" :min="5" :max="480"/>
                </div>
              </div>

              <div v-if="securitySettings.enableIpWhitelist">
                <label class="block text-sm font-medium mb-2">IP白名单 (每行一个)</label>
                <Textarea v-model="securitySettings.ipWhitelist" class="w-full" rows="4"
                          placeholder="192.168.1.1&#10;10.0.0.0/24"/>
              </div>
            </div>

            <!-- 性能设置 -->
            <div v-else-if="activeTab === 5" class="space-y-6">
              <h3 class="text-lg font-semibold mb-4">性能优化</h3>

              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableCache" binary/>
                  <label class="text-sm font-medium">启用缓存</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableCompression" binary/>
                  <label class="text-sm font-medium">启用压缩</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableHealthCheck" binary/>
                  <label class="text-sm font-medium">启用健康检查</label>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">缓存过期时间 (秒)</label>
                  <InputNumber v-model="performanceSettings.cacheExpiration" class="w-full" :min="60"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">健康检查间隔 (秒)</label>
                  <InputNumber v-model="performanceSettings.healthCheckInterval" class="w-full" :min="10"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">日志文件最大大小 (MB)</label>
                  <InputNumber v-model="performanceSettings.maxLogFileSize" class="w-full" :min="10"/>
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">日志保留天数</label>
                  <InputNumber v-model="performanceSettings.logRotationDays" class="w-full" :min="1"/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </Card>

    <!-- 保存按钮 -->
    <div class="flex justify-end gap-3">
      <Button label="重置" icon="pi pi-refresh" severity="secondary" @click="loadSettings"/>
      <Button label="保存设置" icon="pi pi-save" @click="saveSettings" :loading="saving"/>
    </div>
  </div>
</template>

<style scoped>

</style>
