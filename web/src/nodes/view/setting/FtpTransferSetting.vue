<script setup lang="ts">
import SettingLayout from "@/nodes/view/setting/SettingLayout.vue";
import SettingColumn from "@/nodes/view/setting/SettingColumn.vue";
import HostConfigSetting from "@/components/node-setting/HostConfigSetting.vue";
import { ApiList } from "@/api/base-api";
import ftpTransfer from "@/nodes/setting/ftp-transfer";
import { watch, computed } from "vue";

const props = defineProps<{
  visible?: boolean
  config?: any
}>()

const localVisible = ref(props.visible)
const emit = defineEmits(['update:visible', 'save'])

watch(() => props.visible, (val) => localVisible.value = val)
watch(localVisible, (val) => emit('update:visible', val))

// 从配置文件获取初始配置
const initConfig = () => JSON.parse(JSON.stringify(ftpTransfer.init))

const config = ref(initConfig())

watch(() => props.config, (val) => {
  if (val) {
    config.value = { ...initConfig(), ...val }
  }
}, { immediate: true, deep: true })

// 源类型选项
const sourceTypeOptions = [
  { label: '自定义', value: 'custom' },
  { label: '元数据', value: 'metadata' },
  { label: '本机', value: 'localhost' }
]

// 主机列表
const sourceHostList = ref([])
const targetHostList = ref([])
const loading = ref(false)

// 计算属性：是否显示主机配置
const showSourceHostSetting = computed(() => config.value.source_setting.source_type === 'custom')
const showTargetHostSetting = computed(() => config.value.target_setting.source_type === 'custom')

// 计算属性：是否显示文件名配置
const showFileName = computed(() =>
  config.value.source_setting.multifile_merge && !config.value.source_setting.use_original_name
)

// 加载主机列表
const loadHostList = async () => {
  try {
    loading.value = true
    const response = await ApiList('host_resource')
    const hostList = response.data || []
    sourceHostList.value = hostList
    targetHostList.value = hostList
  } catch (error) {
    console.error('Failed to load host list:', error)
    sourceHostList.value = []
    targetHostList.value = []
  } finally {
    loading.value = false
  }
}

// 监听源类型变化，加载主机列表
watch(() => config.value.source_setting.source_type, (newType) => {
  if (newType === 'metadata') {
    loadHostList()
  }
}, { immediate: true })

watch(() => config.value.target_setting.source_type, (newType) => {
  if (newType === 'metadata') {
    loadHostList()
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
</script>

<template>
  <SettingLayout v-model:visible="localVisible">
    <template #header>
      <h1 class="text-lg font-semibold">FTP传输设置</h1>
    </template>

    <!-- 源设置 -->
    <SettingColumn title="源设置">
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
            :options="sourceHostList"
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
        v-if="showSourceHostSetting"
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

    <!-- 目标设置 -->
    <SettingColumn title="目标设置" class="min-w-100">
      <!-- 目标类型选择 -->
      <div class="form-item mb-4 flex gap-2">
        <FloatLabel variant="on" class="flex-1">
          <Select
            v-model="config.target_setting.source_type"
            :options="sourceTypeOptions"
            optionLabel="label"
            optionValue="value"
            fluid
            size="small"
          />
          <label>目标类型</label>
        </FloatLabel>

        <!-- 元数据主机选择 -->
        <FloatLabel variant="on" class="flex-1" v-if="config.target_setting.source_type === 'metadata'">
          <Select
            v-model="config.target_setting.choose_host"
            :options="targetHostList"
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
        v-if="showTargetHostSetting"
        v-model="config.target_setting.host_setting"
        title="目标主机配置"
        :show-actions="true"
      />

      <!-- 本机提示 -->
      <div v-if="config.target_setting.source_type === 'localhost'" class="localhost-info mb-4">
        <div class="p-3 bg-blue-50 border border-blue-200 rounded-md">
          <div class="flex items-center text-primary-700">
            <i class="pi pi-info-circle mr-2"></i>
            <span class="text-sm">将使用服务器本机进行文件操作</span>
          </div>
        </div>
      </div>

      <!-- 目标目录 -->
      <div class="form-item mb-4">
        <FloatLabel variant="on" class="w-full">
          <InputText v-model="config.target_setting.folder" size="small" class="w-full"/>
          <label>目标目录</label>
        </FloatLabel>
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

.localhost-info {
  margin-bottom: 1rem;
}
</style>
