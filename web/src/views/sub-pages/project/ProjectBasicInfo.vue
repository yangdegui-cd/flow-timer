<script setup lang="ts">
import { ref, watch } from 'vue'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Calendar from 'primevue/calendar'
import Dropdown from 'primevue/dropdown'
import ToggleButton from 'primevue/togglebutton'
import Tag from 'primevue/tag'
import InputNumber from 'primevue/inputnumber'
import { projectStatusOptions } from '@/api/project-api'
import type { Project } from '@/data/types/project-types'

interface Props {
  project: Project
  isEditMode: boolean
}

interface Emits {
  (e: 'update:form', value: any): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 编辑表单
const form = ref({
  name: props.project.name,
  description: props.project.description || '',
  start_date: props.project.start_date ? new Date(props.project.start_date) : null,
  status: props.project.status,
  active_ads_automate: props.project.active_ads_automate,
  time_zone: props.project.time_zone || 8,
  adjust_game_token: props.project.adjust_game_token || ''
})

// 监听项目变化，更新表单
watch(() => props.project, (newProject) => {
  form.value = {
    name: newProject.name,
    description: newProject.description || '',
    start_date: newProject.start_date ? new Date(newProject.start_date) : null,
    status: newProject.status,
    active_ads_automate: newProject.active_ads_automate,
    time_zone: newProject.time_zone || 8,
    adjust_game_token: newProject.adjust_game_token || ''
  }
}, { deep: true })

// 监听表单变化，向上传递
watch(form, (newForm) => {
  emit('update:form', newForm)
}, { deep: true })
</script>

<template>
  <Card>
    <template #title>
      <div class="flex items-center">
        <i class="pi pi-info-circle text-blue-600 mr-2"></i>
        基本信息
      </div>
    </template>
    <template #content>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">项目名称</label>
          <InputText
              v-if="isEditMode"
              v-model="form.name"
              placeholder="请输入项目名称"
              class="w-full"
          />
          <div v-else class="p-2 bg-gray-50 rounded">{{ project.name }}</div>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">开始日期</label>
          <Calendar
              v-if="isEditMode"
              v-model="form.start_date"
              placeholder="选择开始日期"
              class="w-full"
          />
          <div v-else class="p-2 bg-gray-50 rounded">
            {{ project.start_date ? new Date(project.start_date).toLocaleDateString('zh-CN') : '-' }}
          </div>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">状态</label>
          <Dropdown
              v-if="isEditMode"
              v-model="form.status"
              :options="projectStatusOptions"
              optionLabel="label"
              optionValue="value"
              class="w-full"
          />
          <div v-else class="p-2">
            <Tag
                :value="projectStatusOptions.find(opt => opt.value === project.status)?.label"
                :severity="project.status === 'active' ? 'success' : 'warning'"
            />
          </div>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">广告自动化</label>
          <ToggleButton
              v-if="isEditMode"
              v-model="form.active_ads_automate"
              onLabel="启用"
              offLabel="禁用"
              class="w-full"
          />
          <div v-else class="p-2">
            <Tag
                :value="project.active_ads_automate ? '启用' : '禁用'"
                :severity="project.active_ads_automate ? 'success' : 'warning'"
            />
          </div>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">时区(UTC)</label>
          <InputNumber
              v-if="isEditMode"
              v-model="form.time_zone"
              :min="-12"
              :max="14"
              placeholder="如: 8 表示 UTC+8"
              class="w-full"
          />
          <div v-else class="p-2 bg-gray-50 rounded">
            {{ project.time_zone >= 0 ? `UTC+${project.time_zone}` : `UTC${project.time_zone}` }}
          </div>
        </div>

        <div class="space-y-2">
          <label class="text-sm font-medium text-gray-700">Adjust Game Token</label>
          <InputText
              v-if="isEditMode"
              v-model="form.adjust_game_token"
              placeholder="请输入 Adjust Game Token"
              class="w-full"
          />
          <div v-else class="p-2 bg-gray-50 rounded font-mono text-sm">
            {{ project.adjust_game_token || '未配置' }}
          </div>
        </div>

        <div class="md:col-span-2 space-y-2">
          <label class="text-sm font-medium text-gray-700">描述</label>
          <Textarea
              v-if="isEditMode"
              v-model="form.description"
              placeholder="请输入项目描述"
              rows="3"
              class="w-full"
          />
          <div v-else class="p-2 bg-gray-50 rounded min-h-[80px]">
            {{ project.description || '暂无描述' }}
          </div>
        </div>
      </div>
    </template>
  </Card>
</template>

<style scoped>
.space-y-2 > * + * {
  margin-top: 0.5rem;
}
</style>
