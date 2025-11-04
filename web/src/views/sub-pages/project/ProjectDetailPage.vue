<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import PageHeader from '@/views/layer/PageHeader.vue'
import ProjectBasicInfo from './ProjectBasicInfo.vue'
import ProjectManageAccount from './ProjectManageAccount.vue'
import ProjectManageUser from './ProjectManageUser.vue'
import ProjectManageAutomation from './ProjectManageAutomation.vue'
import AutomationLogsTab from '../logs/AutomationLogsTab.vue'
import projectApi from '@/api/project-api'
import Card from 'primevue/card'
import Button from 'primevue/button'
import { Project } from "@/data/types/project-types"
import DateRangeSelector from "@/views/_selector/DateRangeSelector.vue";

const route = useRoute()
const router = useRouter()
const toast = useToast()

const projectId = computed(() => route.params.id as string)
const isEditMode = ref(false)
const loading = ref(false)
const saving = ref(false)

// 项目基本信息
const project = ref<Project>({
  id: 0,
  name: '',
  description: '',
  start_date: '',
  status: 'active',
  active_ads_automate: true,
  time_zone: 8,
  adjust_game_token: '',
  sys_users: [],
  user_count: 0
})

// 编辑表单
const form = ref({
  name: '',
  description: '',
  start_date: null as Date | null,
  status: 'active',
  active_ads_automate: true,
  time_zone: 8,
  adjust_game_token: ''
})

// 加载项目详情
const loadProject = () => {
  if (projectId.value === 'new') {
    isEditMode.value = true
    return
  }

  loading.value = true
  projectApi.show(parseInt(projectId.value)).then(data => {
    project.value = data

    // 填充编辑表单
    form.value = {
      name: data.name,
      description: data.description || '',
      start_date: data.start_date ? new Date(data.start_date) : null,
      status: data.status,
      active_ads_automate: data.active_ads_automate,
      time_zone: data.time_zone || 8,
      adjust_game_token: data.adjust_game_token || ''
    }
  }).catch(err => {
    console.error('加载项目失败:', err)
    toast.add({ severity: 'error', summary: '错误', detail: '加载项目失败', life: 3000 })
  }).finally(() => {
    loading.value = false
  })
}

// 保存项目
const saveProject = () => {
  saving.value = true
  const formData = {
    ...form.value,
    start_date: form.value.start_date ? form.value.start_date.toISOString().split('T')[0] : null
  }

  if (projectId.value === 'new') {
    projectApi.create(formData).then(newProject => {
      toast.add({ severity: 'success', summary: '成功', detail: '项目创建成功', life: 3000 })
      router.push(`/project/${newProject.id}`)
    }).catch(err => {
      console.error('保存项目失败:', err)
      toast.add({ severity: 'error', summary: '错误', detail: '保存项目失败', life: 3000 })
    }).finally(() => {
      saving.value = false
    })
  } else {
    projectApi.update(parseInt(projectId.value), formData).then(() => {
      loadProject()
      isEditMode.value = false
      toast.add({ severity: 'success', summary: '成功', detail: '项目更新成功', life: 3000 })
    }).catch(err => {
      console.error('保存项目失败:', err)
      toast.add({ severity: 'error', summary: '错误', detail: '保存项目失败', life: 3000 })
    }).finally(() => {
      saving.value = false
    })
  }
}

// 取消编辑
const cancelEdit = () => {
  if (projectId.value === 'new') {
    router.push('/project')
    return
  }

  isEditMode.value = false
  form.value = {
    name: project.value.name,
    description: project.value.description || '',
    start_date: project.value.start_date ? new Date(project.value.start_date) : null,
    status: project.value.status,
    active_ads_automate: project.value.active_ads_automate,
    time_zone: project.value.time_zone || 8,
    adjust_game_token: project.value.adjust_game_token || ''
  }
}

// 页面标题
const pageTitle = computed(() => {
  if (projectId.value === 'new') return '新建项目'
  return isEditMode.value ? '编辑项目' : '项目详情'
})

// 监听表单更新
const handleFormUpdate = (newForm: any) => {
  form.value = newForm
}

onMounted(() => {
  loadProject()
})
</script>

<template>
  <PageHeader
      :title="pageTitle"
      :description="projectId === 'new' ? '创建新的项目' : project.name"
      icon="pi pi-folder"
      icon-color="text-blue-600"
  >
    <template #actions>
      <Button
          v-if="!isEditMode && projectId !== 'new'"
          @click="isEditMode = true"
          size="small"
          class="mr-2"
      >
        <i class="pi pi-pencil mr-2"></i>
        编辑项目
      </Button>

      <Button
          v-if="isEditMode"
          @click="saveProject"
          :loading="saving"
          size="small"
          class="mr-2"
      >
        <i class="pi pi-check mr-2"></i>
        保存
      </Button>

      <Button
          v-if="isEditMode"
          @click="cancelEdit"
          size="small"
          severity="secondary"
          class="mr-2"
      >
        <i class="pi pi-times mr-2"></i>
        取消
      </Button>

      <Button
          @click="router.push('/project')"
          size="small"
          severity="secondary"
      >
        <i class="pi pi-arrow-left mr-2"></i>
        返回列表
      </Button>
    </template>
  </PageHeader>

  <div class="flex-1 overflow-auto p-4 h-[calc(100vh-130px)]">
    <div class="max-w-7xl mx-auto space-y-4">
      <!-- 基本信息 -->
      <ProjectBasicInfo :project="project" :is-edit-mode="isEditMode" @update:form="handleFormUpdate"/>

      <!-- 自动化规则 -->
      <ProjectManageAutomation :project="project" />

      <!-- 绑定广告账户 -->
      <ProjectManageAccount :project="project" :is-edit-mode="isEditMode" />

      <!-- 分配用户 -->
      <ProjectManageUser :project="project" />

      <!-- 自动化日志 -->
      <Card>
        <template #title>
          <div class="flex items-center">
            <i class="pi pi-history text-teal-600 mr-2"></i>
            自动化日志
          </div>
        </template>
        <template #content>
          <AutomationLogsTab :projectId="parseInt(projectId)"/>
        </template>
      </Card>
    </div>
  </div>
</template>

<style scoped>
.space-y-4 > * + * {
  margin-top: 1rem;
}
</style>
