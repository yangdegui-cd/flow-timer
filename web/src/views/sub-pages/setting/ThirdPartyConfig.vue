<script setup lang="ts">
import { ref } from 'vue';
import { useToast } from "primevue/usetoast";
import configApi, { type Config } from '@/api/config-api';
import facebookApi from '@/api/facebook-api';
import CopyText from "@/components/CopyText.vue";

const toast = useToast();

// 接收父组件传递的配置
const props = defineProps<{
  config: Config
}>();

// 定义事件
const emit = defineEmits<{
  (e: 'update', config: Partial<Config>): void
}>();

// 当前活跃的第三方服务 tab
const activeThirdPartyTab = ref(0);

// 更新配置
const updateConfig = (field: keyof Config, value: any) => {
  emit('update', { [field]: value });
};

// 测试 Adjust 连接
const testAdjustConnection = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在测试 Adjust API 连接...',
      life: 2000
    });

    const result = await configApi.testAdjustConnection();

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
      detail: error.message || '无法连接到 Adjust API',
      life: 3000
    });
  }
};

// 测试 Facebook 连接
const testFacebookConnection = async () => {
  try {
    toast.add({ severity: 'info', summary: '测试中', detail: '正在验证 Facebook App 凭证...', life: 2000 });
    await configApi.testFacebookConnection();
    toast.add({ severity: 'success', summary: '验证成功', life: 3000 });
  } catch (error: any) {
    toast.add({ severity: 'error', summary: error.msg || '无法验证 Facebook 凭证', life: 3000 });
  }
};

// Facebook 登录授权
const refreshFacebookToken = async () => {
  toast.add({ severity: 'info', summary: '准备授权', detail: '正在打开 Facebook 授权页面...', life: 2000 });
  configApi
      .getFacebookAuthUrl()
      .then(res => window.location.href = res.auth_url)
      .catch(err => toast.add({ severity: 'error', detail: err.msg || '无法打开 Facebook 授权页面', life: 3000 }));
};

// 同步 Facebook 账号
const syncFacebookAccounts = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '同步中',
      detail: '正在同步 Facebook 广告账户...',
      life: 2000
    });

    const result = await facebookApi.syncAccounts();

    toast.add({
      severity: 'success',
      summary: '同步成功',
      detail: `成功同步 ${result.synced} 个账户 (新增: ${result.created}, 更新: ${result.updated})`,
      life: 5000
    });
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '同步失败',
      detail: error.msg || error.message || '同步广告账户失败',
      life: 3000
    });
  }
};

// 测试 Google Ads 连接
const testGoogleConnection = async () => {
  try {
    toast.add({
      severity: 'info',
      summary: '测试中',
      detail: '正在验证 Google Ads 凭证...',
      life: 2000
    });

    const result = await configApi.testGoogleConnection();

    toast.add({
      severity: 'success',
      summary: '验证成功',
      life: 3000
    });
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '验证失败',
      detail: error.msg || '无法验证 Google Ads 凭证',
      life: 3000
    });
  }
};

// Google Ads OAuth 授权
const refreshGoogleToken = () => {
  toast.add({ severity: 'info', summary: '准备授权', detail: '正在打开 Google Ads 授权页面...', life: 2000 })
  configApi
      .getGoogleAuthUrl()
      .then(res => window.location.href = res.auth_url)
      .catch(err => toast.add({ severity: 'error', detail: err.msg || '无法打开 Google Ads 授权页面', life: 3000 }))
}

</script>

<template>
  <div class="space-y-6">
    <!-- 第三方服务 Tabs -->
    <TabView v-model:activeIndex="activeThirdPartyTab">
      <!-- Adjust API Tab -->
      <TabPanel>
        <template #header>
          <div class="flex items-center gap-2">
            <i class="pi pi-chart-line"></i>
            <span>Adjust API</span>
          </div>
        </template>

        <div class="space-y-4">
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-md font-semibold">Adjust API 配置</h4>
            <Button label="测试连接" icon="pi pi-send" severity="secondary" size="small"
                    @click="testAdjustConnection"/>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium mb-2">Adjust API Token</label>
              <Password
                  :modelValue="props.config.adjust_api_token"
                  @update:modelValue="updateConfig('adjust_api_token', $event)"
                  class="w-full"
                  toggleMask
                  inputClass="w-full"
                  placeholder="留空则保持原Token不变"
              />
              <small class="text-gray-500">提示：留空则保持原Token不变</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Adjust API Server</label>
              <InputText
                  :modelValue="props.config.adjust_api_server"
                  @update:modelValue="updateConfig('adjust_api_server', $event)"
                  class="w-full"
                  placeholder="https://dash.adjust.com/control-center/reports-service/report"
              />
            </div>
          </div>
        </div>
      </TabPanel>

      <!-- Facebook API Tab -->
      <TabPanel>
        <template #header>
          <div class="flex items-center gap-2">
            <i class="pi pi-facebook"></i>
            <span>Facebook API</span>
          </div>
        </template>

        <div class="space-y-4">
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-md font-semibold">Facebook API 配置</h4>
            <div class="flex gap-2">
              <Button label="测试凭证" icon="pi pi-check-circle" severity="secondary" size="small"
                      @click="testFacebookConnection"/>
              <Button label="Facebook 登录授权" icon="pi pi-facebook" severity="info" size="small"
                      @click="refreshFacebookToken"/>
              <Button label="同步广告账号" icon="pi pi-sync" severity="success" size="small"
                      @click="syncFacebookAccounts"/>
            </div>
          </div>

          <!--          说明-->
          <div class="flex justify-between gap-3">
            <!-- Facebook 应用配置要求 -->
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 w-1/2">
              <div class="mb-3 text-blue-800 text-lg">Facebook 应用配置要求</div>
              <div class="flex items-start gap-2">
                <i class="pi pi-info-circle text-blue-600 mt-1"></i>
                <div class="text-sm text-blue-800">
                  <ol class="list-decimal ml-4 space-y-1">
                    <li>在 <a href="https://developers.facebook.com/apps" target="_blank" class="underline">Facebook
                      开发者平台</a> 创建应用(选择"消费者"类型)
                    </li>
                    <li>添加 "Facebook 登录" 产品</li>
                    <li>在 <strong>Facebook 登录 → 设置</strong> 中:
                      <ul class="ml-4 mt-1 space-y-1">
                        <li>• 将"使用严格模式处理重定向 URI"设为<strong>否</strong></li>
                        <li>• 添加有效 OAuth 重定向 URI:
                          <CopyText :text="config.facebook_auth_callback_url">
                            <code class="bg-white px-1 rounded border">{{ config.facebook_auth_callback_url }}</code>
                          </CopyText>
                        </li>
                      </ul>
                    </li>
                    <li>在 <strong>应用设置 → 基本信息</strong> 中添加应用域名
                      <CopyText :text="config.api_domain">
                        <code class="bg-white px-1 rounded border">{{ config.api_domain }}</code>
                      </CopyText>
                    </li>
                    <li>确保应用处于<strong>开发模式</strong>(开发模式允许 HTTP)</li>
                    <li>添加测试用户或将你的 Facebook 账号添加为应用管理员</li>
                  </ol>
                </div>
              </div>
            </div>
            <!-- 同步账号说明 -->
            <div class="bg-green-50 border border-green-200 rounded-lg p-4 w-1/2">
              <div class="mb-3 text-blue-800 text-lg">同步广告账号说明</div>
              <div class="flex items-start gap-2">
                <i class="pi pi-info-circle text-green-600 mt-1"></i>
                <div class="text-sm text-green-800">
                  <ul class="ml-4 space-y-1 list-disc">
                    <li>点击"同步广告账号"按钮将从 Facebook 获取您有权限访问的所有广告账户</li>
                    <li>同步后的账户将自动保存到系统中，您可以在"广告账户管理"中查看和管理</li>
                    <li>已存在的账户会自动更新信息，新账户会自动创建</li>
                    <li>请确保已完成 Facebook 登录授权且令牌未过期</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>


          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium mb-2">Facebook App ID</label>
              <InputText
                  :modelValue="props.config.facebook_app_id"
                  @update:modelValue="updateConfig('facebook_app_id', $event)"
                  class="w-full"
                  placeholder="请输入 Facebook App ID"
              />
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Facebook App Secret</label>
              <Password
                  :modelValue="props.config.facebook_app_secret"
                  @update:modelValue="updateConfig('facebook_app_secret', $event)"
                  class="w-full"
                  toggleMask
                  inputClass="w-full"
                  placeholder="留空则保持原Secret不变"
              />
              <small class="text-gray-500">提示：留空则保持原Secret不变</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">访问令牌</label>
              <InputText
                  :modelValue="props.config.facebook_access_token"
                  class="w-full"
                  disabled
                  placeholder="点击 'Facebook 登录授权' 按钮获取"
              />
              <small class="text-gray-500">通过 Facebook 登录授权后自动获取</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">令牌过期时间</label>
              <InputText
                  :modelValue="props.config.facebook_token_expired_at"
                  class="w-full"
                  disabled
                  placeholder="获取令牌后自动设置"
              />
            </div>
          </div>
        </div>
      </TabPanel>

      <!-- Google Ads API Tab -->
      <TabPanel>
        <template #header>
          <div class="flex items-center gap-2">
            <i class="pi pi-google"></i>
            <span>Google Ads API</span>
          </div>
        </template>

        <div class="space-y-4">
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-md font-semibold">Google Ads API 配置</h4>
            <div class="flex gap-2">
              <Button label="测试凭证" icon="pi pi-check-circle" severity="secondary" size="small"
                      @click="testGoogleConnection"/>
              <Button label="Google Ads 授权" icon="pi pi-google" severity="info" size="small"
                      @click="refreshGoogleToken"/>
            </div>
          </div>

          <!-- Google Ads 应用配置要求 -->
          <div header="Google Ads API 配置要求" toggleable :collapsed="true">

            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h3 class="mb-3 text-blue-800 text-lg">Google Ads API 配置要求</h3>
              <div class="flex items-start gap-2">
                <i class="pi pi-info-circle text-blue-600 mt-1"></i>
                <div class="text-sm text-blue-800">
                  <ol class="list-decimal ml-4 space-y-1">
                    <li>在 <a href="https://console.cloud.google.com" target="_blank" class="underline">Google Cloud
                      Console</a> 创建项目并启用 Google Ads API
                    </li>
                    <li>创建 OAuth 2.0 客户端 ID (应用类型选择"Web 应用")：
                      <ul class="ml-4 mt-1 space-y-1">
                        <li>• 添加授权重定向 URI:
                          <CopyText :text="config.google_auth_callback_url">
                           <code class="bg-white px-1 rounded border">{{ config.google_auth_callback_url }}</code>
                          </CopyText>
                        </li>
                      </ul>
                    </li>
                    <li>在 <a href="https://ads.google.com/home/tools/manager-accounts/" target="_blank"
                              class="underline">Google Ads Manager 账户</a> 中申请 Developer Token
                    </li>
                    <li>获取 Customer ID: 登录 Google Ads 后，在右上角查看您的客户 ID (格式: 123-456-7890)</li>
                    <li>完成 OAuth 授权后，系统将自动获取 Refresh Token</li>
                  </ol>
                </div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-medium mb-2">Client ID</label>
              <InputText
                  :modelValue="props.config.google_ads_client_id"
                  @update:modelValue="updateConfig('google_ads_client_id', $event)"
                  class="w-full"
                  placeholder="请输入 Google Ads Client ID"
              />
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Client Secret</label>
              <Password
                  :modelValue="props.config.google_ads_client_secret"
                  @update:modelValue="updateConfig('google_ads_client_secret', $event)"
                  class="w-full"
                  toggleMask
                  inputClass="w-full"
                  placeholder="留空则保持原Secret不变"
              />
              <small class="text-gray-500">提示：留空则保持原Secret不变</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Developer Token</label>
              <Password
                  :modelValue="props.config.google_ads_developer_token"
                  @update:modelValue="updateConfig('google_ads_developer_token', $event)"
                  class="w-full"
                  toggleMask
                  inputClass="w-full"
                  placeholder="留空则保持原Token不变"
              />
              <small class="text-gray-500">提示：留空则保持原Token不变</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Customer ID</label>
              <InputText
                  :modelValue="props.config.google_ads_customer_id"
                  @update:modelValue="updateConfig('google_ads_customer_id', $event)"
                  class="w-full"
                  placeholder="123-456-7890"
              />
              <small class="text-gray-500">Google Ads 账户的客户 ID</small>
            </div>

            <div>
              <label class="block text-sm font-medium mb-2">Refresh Token</label>
              <InputText
                  :modelValue="props.config.google_ads_refresh_token"
                  class="w-full"
                  disabled
                  placeholder="点击 'Google Ads 授权' 按钮获取"
              />
              <small class="text-gray-500">通过 Google Ads 授权后自动获取</small>
            </div>
          </div>
        </div>
      </TabPanel>
    </TabView>
  </div>
</template>

<style scoped>

</style>
