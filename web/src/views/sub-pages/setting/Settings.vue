<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useToast } from "primevue/usetoast";
import { useRouter } from 'vue-router';
import PageHeader from '@/views/layer/PageHeader.vue';

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

// 邮件设置
const emailSettings = ref({
  enabled: true,
  smtpHost: 'smtp.example.com',
  smtpPort: 587,
  username: 'noreply@example.com',
  password: '********',
  enableTLS: true,
  fromName: 'FlowTimer System',
  fromEmail: 'noreply@example.com'
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
  { label: '邮件通知', icon: 'pi pi-envelope' },
  { label: '安全配置', icon: 'pi pi-shield' },
  { label: '性能优化', icon: 'pi pi-bolt' },
  { label: '账号绑定', icon: 'pi pi-link', route: '/settings/account' }
];

const loadSettings = async () => {
  loading.value = true;
  try {
    // 模拟加载设置
    await new Promise(resolve => setTimeout(resolve, 1000));
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
    // 模拟保存设置
    await new Promise(resolve => setTimeout(resolve, 2000));
    toast.add({
      severity: 'success',
      summary: '保存成功',
      detail: '系统设置已更新',
      life: 3000
    });
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '保存失败',
      detail: '无法保存系统设置',
      life: 3000
    });
  } finally {
    saving.value = false;
  }
};

const testEmailConnection = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在测试邮件连接...',
      life: 2000
    });

    await new Promise(resolve => setTimeout(resolve, 3000));

    toast.add({
      severity: 'success',
      summary: '连接成功',
      detail: '邮件服务器连接正常',
      life: 3000
    });
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: '连接失败',
      detail: '无法连接到邮件服务器',
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
});
</script>

<template>
  <div class="flex flex-col gap-4 h-full w-full overflow-auto">
    <!-- 页面头部 -->
    <PageHeader
      title="系统设置"
      description="配置FlowTimer系统的运行参数和选项"
      icon="pi pi-cog"
      icon-color="text-gray-600"
    />

    <Card class="w-full h-full">
      <template #content>
        <div class="flex">
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
          <div class="flex-1 pl-6">
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
                  <InputText v-model="systemSettings.siteName" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">时区</label>
                  <Dropdown
                    v-model="systemSettings.timezone"
                    :options="timezoneOptions"
                    optionLabel="label"
                    optionValue="value"
                    class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">语言</label>
                  <Dropdown
                    v-model="systemSettings.language"
                    :options="languageOptions"
                    optionLabel="label"
                    optionValue="value"
                    class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">主题</label>
                  <Dropdown
                    v-model="systemSettings.theme"
                    :options="themeOptions"
                    optionLabel="label"
                    optionValue="value"
                    class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">最大并发任务数</label>
                  <InputNumber v-model="systemSettings.maxConcurrentTasks" class="w-full" :min="1" :max="100" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">任务超时时间 (秒)</label>
                  <InputNumber v-model="systemSettings.taskTimeout" class="w-full" :min="30" :max="3600" />
                </div>
              </div>

              <div class="col-span-2">
                <label class="block text-sm font-medium mb-2">站点描述</label>
                <Textarea v-model="systemSettings.siteDescription" class="w-full" rows="3" />
              </div>

              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="systemSettings.enableNotifications" binary />
                  <label class="text-sm font-medium">启用系统通知</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="systemSettings.enableEmailAlerts" binary />
                  <label class="text-sm font-medium">启用邮件告警</label>
                </div>
              </div>
            </div>

            <!-- 数据库设置 -->
            <div v-else-if="activeTab === 1" class="space-y-6">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold">数据库设置</h3>
                <Button label="测试连接" icon="pi pi-wifi" severity="secondary" size="small" @click="testDatabase" />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">主机地址</label>
                  <InputText v-model="databaseSettings.host" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">端口</label>
                  <InputNumber v-model="databaseSettings.port" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">数据库名</label>
                  <InputText v-model="databaseSettings.database" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">用户名</label>
                  <InputText v-model="databaseSettings.username" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">连接池大小</label>
                  <InputNumber v-model="databaseSettings.connectionPool" class="w-full" :min="1" :max="100" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">连接超时 (秒)</label>
                  <InputNumber v-model="databaseSettings.connectionTimeout" class="w-full" :min="5" :max="300" />
                </div>
              </div>

              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="databaseSettings.autoBackup" binary />
                  <label class="text-sm font-medium">启用自动备份</label>
                </div>

                <div v-if="databaseSettings.autoBackup" class="ml-6 grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium mb-2">备份时间</label>
                    <InputText v-model="databaseSettings.backupTime" class="w-full" placeholder="HH:MM" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium mb-2">保留天数</label>
                    <InputNumber v-model="databaseSettings.backupRetention" class="w-full" :min="1" :max="365" />
                  </div>
                </div>
              </div>
            </div>

            <!-- 邮件设置 -->
            <div v-else-if="activeTab === 2" class="space-y-6">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold">邮件通知设置</h3>
                <Button label="测试连接" icon="pi pi-send" severity="secondary" size="small" @click="testEmailConnection" />
              </div>

              <div class="flex items-center gap-3 mb-4">
                <Checkbox v-model="emailSettings.enabled" binary />
                <label class="text-sm font-medium">启用邮件服务</label>
              </div>

              <div v-if="emailSettings.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">SMTP服务器</label>
                  <InputText v-model="emailSettings.smtpHost" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">SMTP端口</label>
                  <InputNumber v-model="emailSettings.smtpPort" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">用户名</label>
                  <InputText v-model="emailSettings.username" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">密码</label>
                  <Password v-model="emailSettings.password" class="w-full" toggleMask />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">发件人名称</label>
                  <InputText v-model="emailSettings.fromName" class="w-full" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">发件人邮箱</label>
                  <InputText v-model="emailSettings.fromEmail" class="w-full" />
                </div>
              </div>

              <div v-if="emailSettings.enabled" class="flex items-center gap-3">
                <Checkbox v-model="emailSettings.enableTLS" binary />
                <label class="text-sm font-medium">启用TLS加密</label>
              </div>
            </div>

            <!-- 安全设置 -->
            <div v-else-if="activeTab === 3" class="space-y-6">
              <h3 class="text-lg font-semibold mb-4">安全配置</h3>

              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableApiAuth" binary />
                  <label class="text-sm font-medium">启用API认证</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableIpWhitelist" binary />
                  <label class="text-sm font-medium">启用IP白名单</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="securitySettings.enableAuditLog" binary />
                  <label class="text-sm font-medium">启用审计日志</label>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">API密钥过期时间 (天)</label>
                  <InputNumber v-model="securitySettings.apiKeyExpiration" class="w-full" :min="1" :max="365" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">会话超时时间 (分钟)</label>
                  <InputNumber v-model="securitySettings.sessionTimeout" class="w-full" :min="5" :max="480" />
                </div>
              </div>

              <div v-if="securitySettings.enableIpWhitelist">
                <label class="block text-sm font-medium mb-2">IP白名单 (每行一个)</label>
                <Textarea v-model="securitySettings.ipWhitelist" class="w-full" rows="4"
                          placeholder="192.168.1.1&#10;10.0.0.0/24" />
              </div>
            </div>

            <!-- 性能设置 -->
            <div v-else-if="activeTab === 4" class="space-y-6">
              <h3 class="text-lg font-semibold mb-4">性能优化</h3>

              <div class="space-y-4">
                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableCache" binary />
                  <label class="text-sm font-medium">启用缓存</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableCompression" binary />
                  <label class="text-sm font-medium">启用压缩</label>
                </div>

                <div class="flex items-center gap-3">
                  <Checkbox v-model="performanceSettings.enableHealthCheck" binary />
                  <label class="text-sm font-medium">启用健康检查</label>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-sm font-medium mb-2">缓存过期时间 (秒)</label>
                  <InputNumber v-model="performanceSettings.cacheExpiration" class="w-full" :min="60" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">健康检查间隔 (秒)</label>
                  <InputNumber v-model="performanceSettings.healthCheckInterval" class="w-full" :min="10" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">日志文件最大大小 (MB)</label>
                  <InputNumber v-model="performanceSettings.maxLogFileSize" class="w-full" :min="10" />
                </div>

                <div>
                  <label class="block text-sm font-medium mb-2">日志保留天数</label>
                  <InputNumber v-model="performanceSettings.logRotationDays" class="w-full" :min="1" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
    </Card>

    <!-- 保存按钮 -->
    <div class="flex justify-end gap-3">
      <Button label="重置" icon="pi pi-refresh" severity="secondary" @click="loadSettings" />
      <Button label="保存设置" icon="pi pi-save" @click="saveSettings" :loading="saving" />
    </div>
  </div>
</template>

<style scoped>

</style>
