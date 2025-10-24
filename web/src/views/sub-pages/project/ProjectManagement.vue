<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import projectApi from '@/api/project-api'
import ProjectList from '@/views/_tables/ProjectList.vue'
import PageHeader from '@/views/layer/PageHeader.vue'
import { useToast } from 'primevue/usetoast'
import { Project } from "@/data/types/project-types";

const projects = ref<Project[]>([])
const loading = ref(false)

const router = useRouter()
const toast = useToast()

const loadProjects = () => {
  loading.value = true
  projectApi.list().then(data => {
    projects.value = data
  }).catch(err => {
    console.error('加载项目列表失败:', err)
    toast.add({ severity: 'error', summary: '错误', detail: '加载项目列表失败', life: 3000 })
  }).finally(() => {
    loading.value = false
  })
}

const handleCreate = () => {
  router.push('/project/new')
}

const handleEdit = (project: Project) => {
  router.push(`/project/${project.id}`)
}

const handleAssignUsers = (project: Project) => {
  router.push(`/project/${project.id}`)
}

const handleDelete = (project: Project) => {
  // 确认删除逻辑
  if (confirm(`确定要删除项目 "${project.name}" 吗？此操作不可撤销。`)) {
    projectApi.delete(project.id).then(() => {
      toast.add({ severity: 'success', summary: '成功', detail: '项目删除成功', life: 3000 })
      loadProjects()
    }).catch(err => {
      console.error('删除项目失败:', err)
      toast.add({ severity: 'error', summary: '错误', detail: '删除项目失败', life: 3000 })
    })
  }
}


onMounted(() => {
  loadProjects()
})
</script>

<template>
  <div class="flex flex-col h-full">
    <PageHeader
        title="项目管理"
        description="管理系统中的所有项目，包括项目信息和用户分配"
        icon="pi pi-folder"
        icon-color="text-blue-600"
    >
      <template #actions>
        <Button @click="handleCreate" size="small" class="flex items-center">
          <i class="pi pi-plus mr-2"></i>
          新建项目
        </Button>
      </template>
    </PageHeader>

    <div class="flex-1 overflow-hidden">
      <Card class="h-full m-4">
        <template #content>
          <ProjectList
              :projects="projects"
              :loading="loading"
              @edit="handleEdit"
              @assign="handleAssignUsers"
              @delete="handleDelete"
          />
        </template>
      </Card>
    </div>
  </div>
</template>

<style scoped>
</style>
