<template>
  <PageHeader
    title="自动化日志"
    description="查看和管理所有项目的自动化操作日志"
    icon="pi pi-history"
    icon-color="text-teal-600"
  />

  <div class="p-6">
    <!-- 项目选择器 -->
    <Card class="mb-6">
      <template #content>
        <div class="flex items-center gap-4">
          <label class="text-sm font-medium text-gray-700 min-w-20">选择项目:</label>
          <Dropdown
            v-model="selectedProjectId"
            :options="projects"
            optionLabel="name"
            optionValue="id"
            placeholder="全部项目"
            showClear
            class="flex-1 max-w-md"
            @change="onProjectChange"
          >
            <template #value="{ value }">
              <div v-if="value" class="flex items-center gap-2">
                <i class="pi pi-folder text-blue-600"></i>
                <span>{{ projects.find(p => p.id === value)?.name }}</span>
              </div>
              <span v-else>全部项目</span>
            </template>
            <template #option="{ option }">
              <div class="flex items-center gap-2">
                <i class="pi pi-folder text-blue-600"></i>
                <span>{{ option.name }}</span>
              </div>
            </template>
          </Dropdown>
        </div>
      </template>
    </Card>

    <!-- 日志内容 -->
    <Card v-if="selectedProjectId">
      <template #content>
        <AutomationLogsTab :projectId="selectedProjectId" :key="selectedProjectId" />
      </template>
    </Card>

    <!-- 未选择项目时的提示 -->
    <Card v-else>
      <template #content>
        <div class="text-center py-16">
          <i class="pi pi-folder-open text-gray-400" style="font-size: 4rem"></i>
          <p class="mt-4 text-lg text-gray-600">请选择一个项目以查看日志</p>
        </div>
      </template>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import PageHeader from '@/views/layer/PageHeader.vue'
import AutomationLogsTab from '../project/AutomationLogsTab.vue'
import Card from 'primevue/card'
import Dropdown from 'primevue/dropdown'
import projectApi from '@/api/project-api'

const toast = useToast()
const projects = ref<any[]>([])
const selectedProjectId = ref<number | null>(null)
const loading = ref(false)

// 加载项目列表
const loadProjects = async () => {
  loading.value = true
  try {
    const response = await projectApi.list()
    projects.value = response

    // 如果只有一个项目,自动选中
    if (projects.value.length === 1) {
      selectedProjectId.value = projects.value[0].id
    }
  } catch (error: any) {
    console.error('加载项目列表失败:', error)
    toast.add({
      severity: 'error',
      summary: '错误',
      detail: error?.data?.msg ?? '加载项目列表失败',
      life: 3000
    })
  } finally {
    loading.value = false
  }
}

// 项目变化
const onProjectChange = () => {
  // 项目变化时,AutomationLogsTab会通过key重新加载
}

onMounted(() => {
  loadProjects()
})
</script>

<style scoped>
/* 页面样式 */
</style>
