<script setup lang="ts">
import SettingLayout from "@/nodes/view/setting/SettingLayout.vue";
import SettingColumn from "@/nodes/view/setting/SettingColumn.vue";
import HostConfigSetting from "@/components/node-setting/HostConfigSetting.vue";
import uploadCos from "@/nodes/setting/upload-cos";
import { watch, computed } from "vue";
import type { UploadCosConfig, MetaCos } from '@/data/types/cos-types'
import {
  COS_REGION_OPTIONS,
  COS_STORAGE_CLASS_OPTIONS,
  COS_ACL_OPTIONS,
  COS_CONFIG_TYPE_OPTIONS,
  SOURCE_TYPE_OPTIONS,
  ENVIRONMENT_OPTIONS
} from '@/data/constants/cos-constants'
import { createUploadCosConfigDefaults } from '@/data/defaults/cos-defaults'
import { getCosMetaList } from '@/api/cos-api'
import { getMetaHostList } from '@/api/meta-api'

const props = defineProps<{
  visible?: boolean
  config?: any
}>()

const localVisible = ref(props.visible)
const emit = defineEmits(['update:visible', 'save'])

watch(() => props.visible, (val) => localVisible.value = val)
watch(localVisible, (val) => emit('update:visible', val))

// 从配置文件获取初始配置
const initConfig = () => JSON.parse(JSON.stringify(uploadCos.init))

// 使用类型化的配置
const config = ref<UploadCosConfig>(createUploadCosConfigDefaults())

watch(() => props.config, (val) => {
  if (val) {
    config.value = { ...initConfig(), ...val }
  }
}, { immediate: true, deep: true })

// 使用常量配置替代硬编码选项




// 选项数据 - 使用常量配置
const sourceTypeOptions = SOURCE_TYPE_OPTIONS
const regionOptions = COS_REGION_OPTIONS
const storageClassOptions = COS_STORAGE_CLASS_OPTIONS
const aclOptions = COS_ACL_OPTIONS
const cosConfigTypeOptions = COS_CONFIG_TYPE_OPTIONS
const environmentOptions = ENVIRONMENT_OPTIONS

// 主机列表和COS元配置列表
const hostList = ref<any[]>([])
const loading = ref(false)

// COS元配置列表
const cosMetaList = ref([])
const cosLoading = ref(false)

// 计算属性：是否显示主机配置
const showHostSetting = computed(() => config.value.source_setting.source_type === 'custom')

// 计算属性：是否显示COS手动配置
const showManualCosConfig = computed(() => config.value.cos_setting.config_type === 'manual')

// 计算属性：是否显示文件名配置
const showFileName = computed(() =>
  config.value.source_setting.multifile_merge && !config.value.source_setting.use_original_name
)

// 加载主机列表
const loadHostList = async () => {
  try {
    loading.value = true
    hostList.value = await getMetaHostList()
  } catch (error) {
    console.error('Failed to load host list:', error)
    hostList.value = []
  } finally {
    loading.value = false
  }
}

// 加载COS元配置列表
const loadCosMetaList = async () => {
  try {
    cosLoading.value = true
    const list = await getCosMetaList()
    // 只显示状态为active的配置
    cosMetaList.value = list.filter(item => item.status === 'active')
  } catch (error) {
    console.error('Failed to load COS meta list:', error)
    cosMetaList.value = []
  } finally {
    cosLoading.value = false
  }
}

// 监听源类型变化，加载主机列表
watch(() => config.value.source_setting.source_type, (newType) => {
  if (newType === 'metadata') {
    loadHostList()
  }
}, { immediate: true })

// 监听COS配置类型变化，加载COS元配置列表
watch(() => config.value.cos_setting.config_type, (newType) => {
  if (newType === 'metadata') {
    loadCosMetaList()
  }
}, { immediate: true })

// 添加文件
const addFile = () => {
  config.value.source_setting.files.push("")
}

// 删除文件
const removeFile = (index: number) => {
  config.value.source_setting.files.splice(index, 1)
}

// 保存配置
const handleSave = () => {
  emit('save', { ...config.value })
}

// 监听多文件合并选项变化
watch(() => config.value.source_setting.multifile_merge, (val) => {
  if (val) {
    config.value.source_setting.use_original_name = false
  }
})

// 测试COS连接
const testConnection = () => {
  // TODO: 实现COS连接测试逻辑
  console.log('Testing COS connection...', config.value.cos_setting)
}
</script>

<template>
  <SettingLayout v-model:visible="localVisible">
    <template #header>
      <h1 class="text-lg font-semibold">上传COS设置</h1>
    </template>

    <!-- 源文件设置 -->
    <SettingColumn title="源文件设置">
      <!-- 源类型选择 -->
      <div class="form-item mb-4 flex gap-2">
        <FloatLabel variant="on" class="flex-1">
          <Select
            v-model="config.source_setting.source_type"
            :options="sourceTypeOptions"
            optionLabel="label"
            optionValue="value"
            fluid
            size="small"
          />
          <label>源类型</label>
        </FloatLabel>

        <!-- 元数据主机选择 -->
        <FloatLabel variant="on" class="flex-1" v-if="config.source_setting.source_type === 'metadata'">
          <Select
            v-model="config.source_setting.choose_host"
            :options="hostList"
            optionLabel="name"
            optionValue="id"
            fluid
            size="small"
            :loading="loading"
            placeholder="选择主机"
          />
          <label>选择主机</label>
        </FloatLabel>
      </div>

      <!-- 自定义主机配置 -->
      <HostConfigSetting
        v-if="showHostSetting"
        v-model="config.source_setting.host_setting"
        title="源主机配置"
        :show-actions="true"
      />

      <!-- 本机提示 -->
      <div v-if="config.source_setting.source_type === 'localhost'" class="localhost-info mb-4">
        <div class="p-3 bg-blue-50 border border-blue-200 rounded-md">
          <div class="flex items-center text-primary-700">
            <i class="pi pi-info-circle mr-2"></i>
            <span class="text-sm">将使用服务器本机进行文件操作</span>
          </div>
        </div>
      </div>

      <!-- 文件配置 -->
      <div class="file-setting mb-4">
        <div class="flex items-center justify-between mb-3">
          <label class="font-medium">文件列表</label>
          <Button type="primary" size="small" @click="addFile">添加文件</Button>
        </div>

        <div v-for="(file, index) in config.source_setting.files" :key="index" class="flex items-center gap-2 mb-2">
          <FloatLabel variant="on" class="flex-1">
            <InputText v-model="config.source_setting.files[index]" size="small" class="w-full"/>
            <label>文件路径</label>
          </FloatLabel>
          <Button severity="danger" icon="pi pi-trash" @click="removeFile(index)" size="small"/>
        </div>
      </div>

      <!-- 文件处理选项 -->
      <div class="file-options mb-4">
        <div class="grid grid-cols-2 gap-4 mb-3">
          <div class="flex items-center">
            <Checkbox v-model="config.source_setting.multifile_merge" inputId="multifile_merge" binary/>
            <label for="multifile_merge" class="ml-2">多文件合并</label>
          </div>
          <div class="flex items-center">
            <Checkbox v-model="config.source_setting.use_original_name" inputId="use_original_name" binary :disabled="config.source_setting.multifile_merge"/>
            <label for="use_original_name" class="ml-2">使用原名称</label>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-3">
          <div class="flex items-center">
            <Checkbox v-model="config.source_setting.use_zip" inputId="use_zip" binary/>
            <label for="use_zip" class="ml-2">使用压缩</label>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 w-full">
          <FloatLabel variant="on">
            <InputText v-model="config.source_setting.tmp_folder" size="small" class="w-full"/>
            <label>临时目录</label>
          </FloatLabel>
          <FloatLabel variant="on" v-if="showFileName">
            <InputText v-model="config.source_setting.file_name" size="small" class="w-full"/>
            <label>目标文件名</label>
          </FloatLabel>
        </div>
      </div>
    </SettingColumn>

    <!-- COS配置设置 -->
    <SettingColumn title="COS配置设置" class="min-w-100">
      <!-- 配置类型选择 -->
      <div class="cos-config-type mb-4">
        <div class="grid grid-cols-2 gap-4">
          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.config_type"
              :options="cosConfigTypeOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
            />
            <label>配置类型</label>
          </FloatLabel>

          <!-- 元数据配置选择 -->
          <FloatLabel variant="on" v-if="config.cos_setting.config_type === 'metadata'">
            <Select
              v-model="config.cos_setting.meta_cos_id"
              :options="cosMetaList"
              optionLabel="name"
              optionValue="id"
              fluid
              size="small"
              :loading="cosLoading"
              placeholder="选择COS配置"
            />
            <label>选择COS配置</label>
          </FloatLabel>
        </div>
      </div>

      <!-- 元数据配置提示 -->
      <div v-if="config.cos_setting.config_type === 'metadata'" class="metadata-info mb-4">
        <div class="p-3 bg-green-50 border border-green-200 rounded-md">
          <div class="flex items-center text-green-700">
            <i class="pi pi-info-circle mr-2"></i>
            <span class="text-sm">将使用已保存的COS元配置，可在下方覆盖部分设置</span>
          </div>
        </div>
      </div>

      <!-- 基本配置 -->
      <div class="cos-basic-config mb-4" v-if="showManualCosConfig">
        <div class="grid grid-cols-2 gap-4 mb-3">
          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.region"
              :options="regionOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
            />
            <label>地域</label>
          </FloatLabel>

          <FloatLabel variant="on">
            <InputText v-model="config.cos_setting.bucket" size="small" class="w-full"/>
            <label>存储桶名称</label>
          </FloatLabel>
        </div>

        <div class="grid grid-cols-1 gap-4 mb-3">
          <FloatLabel variant="on">
            <InputText v-model="config.cos_setting.secret_id" size="small" class="w-full"/>
            <label>SecretId</label>
          </FloatLabel>

          <FloatLabel variant="on">
            <Password v-model="config.cos_setting.secret_key" size="small" class="w-full" :feedback="false" toggleMask/>
            <label>SecretKey</label>
          </FloatLabel>
        </div>

        <div class="grid grid-cols-1 gap-4 mb-3">
          <FloatLabel variant="on">
            <InputText v-model="config.cos_setting.prefix" size="small" class="w-full" placeholder="文件前缀路径，如：uploads/"/>
            <label>文件前缀</label>
          </FloatLabel>
        </div>
      </div>

      <!-- 元数据配置的覆盖设置 -->
      <div class="cos-metadata-override mb-4" v-if="config.cos_setting.config_type === 'metadata'">
        <h4 class="font-medium mb-3">覆盖设置（可选）</h4>

        <div class="grid grid-cols-1 gap-4 mb-3">
          <FloatLabel variant="on">
            <InputText v-model="config.cos_setting.prefix" size="small" class="w-full" placeholder="覆盖元配置中的文件前缀"/>
            <label>文件前缀</label>
          </FloatLabel>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-3">
          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.storage_class"
              :options="storageClassOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
              placeholder="覆盖存储类型"
            />
            <label>存储类型</label>
          </FloatLabel>

          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.acl"
              :options="aclOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
              placeholder="覆盖访问权限"
            />
            <label>访问权限</label>
          </FloatLabel>
        </div>

        <div class="flex items-center">
          <Checkbox v-model="config.cos_setting.overwrite" inputId="overwrite_meta" binary/>
          <label for="overwrite_meta" class="ml-2">覆盖同名文件</label>
        </div>
      </div>

      <!-- 高级配置 -->
      <div class="cos-advanced-config mb-4" v-if="showManualCosConfig">
        <h4 class="font-medium mb-3">高级配置</h4>

        <div class="grid grid-cols-2 gap-4 mb-3">
          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.storage_class"
              :options="storageClassOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
            />
            <label>存储类型</label>
          </FloatLabel>

          <FloatLabel variant="on">
            <Select
              v-model="config.cos_setting.acl"
              :options="aclOptions"
              optionLabel="label"
              optionValue="value"
              fluid
              size="small"
            />
            <label>访问权限</label>
          </FloatLabel>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-3">
          <div class="flex items-center">
            <Checkbox v-model="config.cos_setting.overwrite" inputId="overwrite" binary/>
            <label for="overwrite" class="ml-2">覆盖同名文件</label>
          </div>
          <div class="flex items-center">
            <Checkbox v-model="config.cos_setting.use_ssl" inputId="use_ssl" binary/>
            <label for="use_ssl" class="ml-2">使用SSL</label>
          </div>
        </div>
      </div>

      <!-- COS连接测试 -->
      <div class="cos-test mb-4">
        <div class="p-3 bg-gray-50 border border-gray-200 rounded-md">
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-700">测试COS连接配置</span>
            <Button size="small" @click="testConnection" severity="secondary">测试连接</Button>
          </div>
        </div>
      </div>

      <!-- 配置说明 -->
      <div class="cos-info">
        <div class="p-3 bg-blue-50 border border-blue-200 rounded-md">
          <div class="flex items-start text-primary-700">
            <i class="pi pi-info-circle mr-2 mt-0.5"></i>
            <div class="text-sm">
              <p class="mb-2">配置说明：</p>
              <ul class="list-disc list-inside space-y-1 text-xs">
                <li>SecretId和SecretKey用于腾讯云COS身份验证</li>
                <li>存储桶名称格式：bucket-appid，如 mytest-1250000000</li>
                <li>文件前缀可以为空，用于指定上传文件的目录结构</li>
                <li>存储类型影响存储成本和访问速度</li>
                <li>建议在生产环境中使用私有读写权限</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </SettingColumn>

    <template #footer>
      <Button @click="handleSave" type="primary">保存设置</Button>
      <Button @click="localVisible = false">关闭</Button>
    </template>
  </SettingLayout>
</template>

<style scoped>
.form-item {
  margin-bottom: 1rem;
}

.file-setting {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}

.file-options {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}

.cos-basic-config,
.cos-advanced-config,
.cos-metadata-override {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}

.cos-config-type {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}

.cos-test {
  margin-bottom: 1rem;
}

.localhost-info {
  margin-bottom: 1rem;
}
</style>
