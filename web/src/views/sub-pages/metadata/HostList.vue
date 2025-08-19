<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useRouter } from 'vue-router'
import PageHeader from '@/views/layer/PageHeader.vue'

const router = useRouter()
const toast = useToast()
const confirm = useConfirm()

// 接口类型定义
interface HostResource {
  id: number
  name: string
  description?: string
  hostname: string
  port: number
  username: string
  status: 'active' | 'inactive' | 'error'
  environment?: string
  tags?: string[]
  notes?: string
  last_tested_at?: string
  last_test_result?: string
  needs_testing: boolean
  connection_string: string
  created_at: string
  updated_at: string
}

// 数据状态
const hosts = ref<HostResource[]>([])
const selectedHosts = ref<HostResource[]>([])
const loading = ref(false)
const showCreateDialog = ref(false)
const showEditDialog = ref(false)
const showTestDialog = ref(false)
const editingHost = ref<Partial<HostResource>>({})
const testingHost = ref<HostResource | null>(null)

// 表单数据
const hostForm = ref({
  name: '',
  description: '',
  hostname: '',
  port: 22,
  username: '',
  password: '',
  ssh_key: '',
  environment: '',
  tags: [] as string[],
  notes: ''
})

// 环境选项
const environmentOptions = [
  { label: '开发', value: 'dev' },
  { label: '测试', value: 'test' },
  { label: '生产', value: 'prod' }
]

// 状态显示配置
const statusConfig = {
  active: { label: '正常', severity: 'success' as const },
  inactive: { label: '停用', severity: 'secondary' as const },
  error: { label: '异常', severity: 'danger' as const }
}

// 加载主机列表
const loadHosts = async () => {
  loading.value = true
  try {
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 800))

    // 模拟数据
    hosts.value = [
      {
        id: 1,
        name: 'web-server-01',
        description: 'Web服务器01',
        hostname: '192.168.1.100',
        port: 22,
        username: 'root',
        status: 'active',
        environment: 'prod',
        tags: ['web', 'nginx'],
        last_tested_at: '2024-01-10T10:30:00Z',
        last_test_result: 'success',
        needs_testing: false,
        connection_string: 'ssh root@192.168.1.100:22',
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-10T10:30:00Z'
      },
      {
        id: 2,
        name: 'db-server-01',
        description: '数据库服务器01',
        hostname: '192.168.1.101',
        port: 22,
        username: 'admin',
        status: 'error',
        environment: 'prod',
        tags: ['database', 'mysql'],
        last_tested_at: '2024-01-10T09:00:00Z',
        last_test_result: 'failed',
        needs_testing: true,
        connection_string: 'ssh admin@192.168.1.101:22',
        created_at: '2024-01-02T00:00:00Z',
        updated_at: '2024-01-10T09:00:00Z'
      }
    ]
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: '加载失败',
      detail: error.message || '网络错误',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

// 测试连接
const testConnection = async (host: HostResource) => {
  testingHost.value = host
  try {
    toast.add({
      severity: 'info',
      summary: '开始测试',
      detail: `正在测试 ${host.name} 的连接...`,
      life: 2000
    })

    // 模拟测试连接
    await new Promise(resolve => setTimeout(resolve, 2000))

    // 模拟测试结果
    const success = Math.random() > 0.3
    if (success) {
      toast.add({
        severity: 'success',
        summary: '连接成功',
        detail: `${host.name} 连接测试通过`,
        life: 3000
      })
      // 更新状态
      host.status = 'active'
      host.last_test_result = 'success'
      host.needs_testing = false
    } else {
      toast.add({
        severity: 'error',
        summary: '连接失败',
        detail: `${host.name} 连接测试失败`,
        life: 3000
      })
      host.status = 'error'
      host.last_test_result = 'failed'
    }
  } finally {
    testingHost.value = null
  }
}

// 打开创建对话框
const openCreateDialog = () => {
  hostForm.value = {
    name: '',
    description: '',
    hostname: '',
    port: 22,
    username: '',
    password: '',
    ssh_key: '',
    environment: '',
    tags: [],
    notes: ''
  }
  showCreateDialog.value = true
}

// 打开编辑对话框
const openEditDialog = (host: HostResource) => {
  editingHost.value = { ...host }
  hostForm.value = {
    name: host.name,
    description: host.description || '',
    hostname: host.hostname,
    port: host.port,
    username: host.username,
    password: '', // 不回填密码
    ssh_key: '', // 不回填SSH密钥
    environment: host.environment || '',
    tags: host.tags || [],
    notes: host.notes || ''
  }
  showEditDialog.value = true
}

// 确认删除
const confirmDelete = (event: Event, host: HostResource) => {
  confirm.require({
    target: event.currentTarget as HTMLElement,
    message: `确定要删除主机 "${host.name}" 吗？`,
    header: '删除确认',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    acceptLabel: '删除',
    rejectLabel: '取消',
    accept: () => deleteHost(host),
    reject: () => {
      toast.add({ severity: 'info', summary: '已取消删除', life: 3000 })
    }
  })
}

// 删除主机
const deleteHost = async (host: HostResource) => {
  try {
    // 模拟删除API调用
    await new Promise(resolve => setTimeout(resolve, 500))

    hosts.value = hosts.value.filter(h => h.id !== host.id)
    toast.add({ severity: 'success', summary: '删除成功', life: 3000 })
  } catch (error: any) {
    toast.add({ severity: 'error', summary: '删除失败', detail: error.message, life: 3000 })
  }
}

// 保存主机
const saveHost = async () => {
  try {
    // 简单验证
    if (!hostForm.value.name || !hostForm.value.hostname || !hostForm.value.username) {
      toast.add({ severity: 'warn', summary: '请填写必填字段', life: 3000 })
      return
    }

    // 模拟保存API调用
    await new Promise(resolve => setTimeout(resolve, 1000))

    if (editingHost.value.id) {
      // 编辑模式
      const index = hosts.value.findIndex(h => h.id === editingHost.value.id)
      if (index >= 0) {
        hosts.value[index] = {
          ...hosts.value[index],
          ...hostForm.value,
          updated_at: new Date().toISOString()
        }
      }
      toast.add({ severity: 'success', summary: '更新成功', life: 3000 })
      showEditDialog.value = false
    } else {
      // 创建模式
      const newHost: HostResource = {
        id: Date.now(),
        ...hostForm.value,
        status: 'active',
        needs_testing: true,
        connection_string: `ssh ${hostForm.value.username}@${hostForm.value.hostname}:${hostForm.value.port}`,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
      hosts.value.unshift(newHost)
      toast.add({ severity: 'success', summary: '创建成功', life: 3000 })
      showCreateDialog.value = false
    }
  } catch (error: any) {
    toast.add({ severity: 'error', summary: '保存失败', detail: error.message, life: 3000 })
  }
}

// 格式化日期
const formatDate = (date?: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleString('zh-CN')
}

// 页面加载
onMounted(() => {
  loadHosts()
})
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- 页面头部 -->
    <PageHeader
      title="主机管理"
      description="SSH连接和服务器资源管理"
      icon="pi pi-desktop"
      icon-color="text-blue-600"
      show-back
      back-label="返回元数据管理"
      @back="router.push('/metadata')"
    >
      <template #actions>
        <Button
          icon="pi pi-refresh"
          severity="secondary"
          variant="outlined"
          size="small"
          :loading="loading"
          @click="loadHosts"
          v-tooltip.top="'刷新列表'" />

        <Button
          icon="pi pi-plus"
          label="添加主机"
          severity="primary"
          size="small"
          @click="openCreateDialog" />
      </template>
    </PageHeader>

    <!-- 数据表格 -->
    <div class="flex-1 overflow-hidden">
      <DataTable
        v-model:selection="selectedHosts"
        :value="hosts"
        :loading="loading"
        dataKey="id"
        scrollable
        scrollHeight="flex"
        class="h-full"
        :globalFilterFields="['name', 'hostname', 'description']">

        <Column selectionMode="multiple" headerStyle="width: 3rem" />

        <Column field="name" header="名称" :sortable="true" style="min-width: 150px">
          <template #body="{ data }">
            <div class="flex items-center gap-2">
              <div class="font-medium">{{ data.name }}</div>
              <Tag
                v-if="data.needs_testing"
                value="需要测试"
                severity="warn"
                class="text-xs" />
            </div>
            <div class="text-xs text-gray-500 mt-1">{{ data.description }}</div>
          </template>
        </Column>

        <Column field="connection_string" header="连接信息" style="min-width: 200px">
          <template #body="{ data }">
            <div class="font-mono text-sm">{{ data.hostname }}:{{ data.port }}</div>
            <div class="text-xs text-gray-500">用户: {{ data.username }}</div>
          </template>
        </Column>

        <Column field="status" header="状态" :sortable="true" style="min-width: 100px">
          <template #body="{ data }">
            <Tag
              :value="statusConfig[data.status].label"
              :severity="statusConfig[data.status].severity"
              class="text-xs" />
          </template>
        </Column>

        <Column field="environment" header="环境" style="min-width: 80px">
          <template #body="{ data }">
            <Tag
              v-if="data.environment"
              :value="data.environment"
              severity="info"
              class="text-xs" />
            <span v-else class="text-gray-400">-</span>
          </template>
        </Column>

        <Column field="last_tested_at" header="最后测试" :sortable="true" style="min-width: 140px">
          <template #body="{ data }">
            <div class="text-sm">{{ formatDate(data.last_tested_at) }}</div>
            <div v-if="data.last_test_result" class="text-xs"
                 :class="data.last_test_result === 'success' ? 'text-green-600' : 'text-red-600'">
              {{ data.last_test_result === 'success' ? '成功' : '失败' }}
            </div>
          </template>
        </Column>

        <Column header="操作" headerClass="flex justify-center" style="min-width: 200px">
          <template #body="{ data }">
            <div class="flex items-center gap-1">
              <Button
                icon="pi pi-play"
                text
                size="small"
                severity="success"
                v-tooltip.top="'测试连接'"
                :loading="testingHost?.id === data.id"
                @click="testConnection(data)" />

              <Button
                icon="pi pi-pencil"
                text
                size="small"
                severity="secondary"
                v-tooltip.top="'编辑'"
                @click="openEditDialog(data)" />

              <Button
                icon="pi pi-trash"
                text
                size="small"
                severity="danger"
                v-tooltip.top="'删除'"
                @click="confirmDelete($event, data)" />
            </div>
          </template>
        </Column>

        <template #empty>
          <div class="text-center py-8">
            <i class="pi pi-desktop text-4xl text-gray-400 mb-4 block"></i>
            <p class="text-gray-500">暂无主机配置</p>
            <Button
              label="添加第一个主机"
              icon="pi pi-plus"
              class="mt-4"
              @click="openCreateDialog" />
          </div>
        </template>
      </DataTable>
    </div>

    <!-- 创建主机对话框 -->
    <Dialog
      v-model:visible="showCreateDialog"
      header="添加主机"
      modal
      :style="{ width: '600px' }">

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium mb-1">名称 *</label>
          <InputText v-model="hostForm.name" placeholder="主机名称" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">主机地址 *</label>
          <InputText v-model="hostForm.hostname" placeholder="IP地址或域名" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">端口</label>
          <InputNumber v-model="hostForm.port" :min="1" :max="65535" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">用户名 *</label>
          <InputText v-model="hostForm.username" placeholder="SSH用户名" class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">描述</label>
          <InputText v-model="hostForm.description" placeholder="主机描述" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">密码</label>
          <Password v-model="hostForm.password" placeholder="SSH密码" class="w-full" :feedback="false" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">环境</label>
          <Select
            v-model="hostForm.environment"
            :options="environmentOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择环境"
            class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">SSH私钥</label>
          <Textarea v-model="hostForm.ssh_key" placeholder="SSH私钥内容" rows="4" class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">备注</label>
          <Textarea v-model="hostForm.notes" placeholder="备注信息" rows="2" class="w-full" />
        </div>
      </div>

      <template #footer>
        <Button label="取消" icon="pi pi-times" text @click="showCreateDialog = false" />
        <Button label="保存" icon="pi pi-check" @click="saveHost" />
      </template>
    </Dialog>

    <!-- 编辑主机对话框 -->
    <Dialog
      v-model:visible="showEditDialog"
      header="编辑主机"
      modal
      :style="{ width: '600px' }">

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium mb-1">名称 *</label>
          <InputText v-model="hostForm.name" placeholder="主机名称" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">主机地址 *</label>
          <InputText v-model="hostForm.hostname" placeholder="IP地址或域名" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">端口</label>
          <InputNumber v-model="hostForm.port" :min="1" :max="65535" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">用户名 *</label>
          <InputText v-model="hostForm.username" placeholder="SSH用户名" class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">描述</label>
          <InputText v-model="hostForm.description" placeholder="主机描述" class="w-full" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">新密码</label>
          <Password v-model="hostForm.password" placeholder="留空则不修改" class="w-full" :feedback="false" />
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">环境</label>
          <Select
            v-model="hostForm.environment"
            :options="environmentOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="选择环境"
            class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">SSH私钥</label>
          <Textarea v-model="hostForm.ssh_key" placeholder="留空则不修改" rows="4" class="w-full" />
        </div>

        <div class="col-span-2">
          <label class="block text-sm font-medium mb-1">备注</label>
          <Textarea v-model="hostForm.notes" placeholder="备注信息" rows="2" class="w-full" />
        </div>
      </div>

      <template #footer>
        <Button label="取消" icon="pi pi-times" text @click="showEditDialog = false" />
        <Button label="保存" icon="pi pi-check" @click="saveHost" />
      </template>
    </Dialog>

    <!-- 确认对话框 -->
    <ConfirmPopup />
  </div>
</template>

<style scoped lang="scss">
:deep(.p-datatable) {
  .p-datatable-thead > tr > th {
    background: #f8f9fa;
    border-bottom: 1px solid #dee2e6;
    font-weight: 600;
    color: #495057;
  }

  .p-datatable-tbody > tr:hover {
    background: #f8f9fa;
  }
}
</style>
