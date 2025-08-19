<script setup lang="ts">
import { ApiCreate } from "@/api/base-api";
import { computed } from "vue";
import { useToast } from "primevue/usetoast";
import { useConfirm } from "primevue/useconfirm";

const props = defineProps<{
  modelValue: {
    host: string
    port: number
    username: string
    authentication_type: string
    password: string
    pem: string
  }
  title?: string
  showActions?: boolean
}>()

const emit = defineEmits(['update:modelValue'])

const toast = useToast();
const confirm = useConfirm();

// 认证类型选项
const authTypeOptions = [
  { label: '密码认证', value: 'password' },
  { label: 'PEM文件', value: 'pem' }
]

const saving = ref(false)
const showSaveDialog = ref(false)
const saveForm = ref({
  name: '',
  description: '',
  environment: 'production',
  tags: 'ftp,auto-created'
})

// 环境选项
const environmentOptions = [
  { label: '生产环境', value: 'production' },
  { label: '测试环境', value: 'test' },
  { label: '开发环境', value: 'development' }
]

// 计算属性
const config = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

// 打开保存弹框
const openSaveDialog = (event) => {
  if (!config.value.host || !config.value.username) {
    toast.add({ severity: 'warn', summary: '请填写主机地址和用户名', life: 3000 });
    return
  }

  // 设置默认值
  saveForm.value.name = `${config.value.username}@${config.value.host}:${config.value.port}`
  saveForm.value.description = `自动保存的FTP主机配置`
  showSaveDialog.value = true
}

// 保存为元数据
const saveAsMetadata = async () => {
  if (!saveForm.value.name.trim()) {
    toast.add({ severity: 'warn', summary: '请填写主机名称', life: 3000 });
    return
  }

  saving.value = true
  const hostData = {
    name: saveForm.value.name,
    description: saveForm.value.description,
    hostname: config.value.host,
    port: config.value.port,
    username: config.value.username,
    password: config.value.authentication_type === 'password' ? config.value.password : '',
    ssh_key: config.value.authentication_type === 'pem' ? config.value.pem : '',
    auth_type: config.value.authentication_type,
    environment: saveForm.value.environment,
    status: 'active',
    tags: saveForm.value.tags.split(',').map(tag => tag.trim()),
    notes: '通过FTP传输节点自动创建'
  }
  ApiCreate('host_resource', hostData).then((res) => {
    toast.add({ severity: 'success', summary: '主机配置已保存到元数据', life: 3000 });
    showSaveDialog.value = false
  }).catch((err) => {
    toast.add({ severity: 'error', summary: '保存主机配置失败', detail: err.msg || '网络错误', life: 3000 });
  }).finally(
      saving.value = false
  )
}

// 取消保存
const cancelSave = () => {
  showSaveDialog.value = false
  saveForm.value.name = ''
  saveForm.value.description = ''
  saveForm.value.environment = 'production'
  saveForm.value.tags = 'ftp,auto-created'
}
</script>

<template>
  <div class="host-config-setting">
    <div class="grid grid-cols-2 gap-4 mb-3">
      <FloatLabel variant="on">
        <InputText v-model="config.host" size="small" class="w-full"/>
        <label>主机地址</label>
      </FloatLabel>
      <FloatLabel variant="on">
        <InputNumber v-model="config.port" size="small" class="w-full"/>
        <label>端口</label>
      </FloatLabel>
    </div>

    <div class="grid grid-cols-2 gap-4 mb-3">
      <FloatLabel variant="on">
        <InputText v-model="config.username" size="small" class="w-full"/>
        <label>用户名</label>
      </FloatLabel>
      <FloatLabel variant="on">
        <Select
            v-model="config.authentication_type"
            :options="authTypeOptions"
            optionLabel="label"
            optionValue="value"
            size="small"
            class="w-full"
        />
        <label>认证方式</label>
      </FloatLabel>
    </div>

    <div v-if="config.authentication_type === 'password'" class="grid grid-cols-2 gap-4 mb-3">
      <FloatLabel variant="on">
        <Password v-model="config.password" size="small" class="w-full" :feedback="false"/>
        <label>密码</label>
      </FloatLabel>
      <Button
          v-if="showActions"
          @click="openSaveDialog"
          size="small"
          :loading="saving"
          icon="pi pi-save"
          label="保存为元数据"/>
    </div>

    <div v-if="config.authentication_type === 'pem'" class="mb-3">
      <FloatLabel variant="on">
        <Textarea v-model="config.pem" rows="6" class="w-full"/>
        <label>PEM文件内容</label>
      </FloatLabel>
      <div class="flex items-center justify-end my-3" v-if="showActions">
        <Button
            @click="openSaveDialog"
            size="small"
            :loading="saving"
            icon="pi pi-save"
            label="保存为元数据"/>
      </div>
    </div>

    <!-- 保存配置弹框 -->
    <Dialog v-model:visible="showSaveDialog" modal header="保存主机配置" :style="{width: '450px'}">
      <div class="flex flex-col gap-4 mt-3">
        <div>
          <FloatLabel variant="on">
            <InputText v-model="saveForm.name" class="w-full"/>
            <label>主机名称 *</label>
          </FloatLabel>
        </div>

        <div>
          <FloatLabel variant="on">
            <InputText v-model="saveForm.description" class="w-full"/>
            <label>描述</label>
          </FloatLabel>
        </div>

        <div>
          <FloatLabel variant="on">
            <Select
                v-model="saveForm.environment"
                :options="environmentOptions"
                optionLabel="label"
                optionValue="value"
                class="w-full"
            />
            <label>环境</label>
          </FloatLabel>
        </div>

        <div>
          <FloatLabel variant="on">
            <InputText v-model="saveForm.tags" class="w-full"/>
            <label>标签 (逗号分隔)</label>
          </FloatLabel>
        </div>
      </div>

      <template #footer>
        <Button label="取消" icon="pi pi-times" size="small" @click="cancelSave" severity="secondary"/>
        <Button label="保存" icon="pi pi-check" size="small"  @click="saveAsMetadata" :loading="saving"/>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.host-config-setting {
  padding: 1rem;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background-color: #f9f9f9;
}
</style>
