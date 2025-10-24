<script setup lang="ts">
import { ref, watch } from 'vue'
import projectApi, { projectStatusOptions } from '@/api/project-api'
import { useToast } from 'primevue/usetoast'
import { Project } from "@/data/types/project-types";

interface Props {
  visible: boolean
  mode: 'create' | 'edit'
  project?: Project | null
}

interface Emits {
  (e: 'update:visible', value: boolean): void
  (e: 'saved'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
const toast = useToast()

const form = ref({
  name: '',
  start_date: '',
  active_ads_automate: true,
  description: '',
  status: 'active'
})

const loading = ref(false)
const submitted = ref(false)

const resetForm = () => {
  form.value = {
    name: '',
    start_date: '',
    active_ads_automate: true,
    description: '',
    status: 'active'
  }
  submitted.value = false
}

watch(() => props.visible, (visible) => {
  if (visible) {
    if (props.mode === 'edit' && props.project) {
      Object.assign(form.value, {
        name: props.project.name,
        start_date: props.project.start_date,
        active_ads_automate: props.project.active_ads_automate,
        description: props.project.description || '',
        status: props.project.status
      })
    } else if (props.mode === 'create') {
      resetForm()
    }
  }
})

const handleClose = () => {
  emit('update:visible', false)
  resetForm()
}

const validateForm = () => {
  return form.value.name.trim() !== '' && form.value.start_date !== ''
}

const handleSave = () => {
  submitted.value = true

  if (!validateForm()) {
    toast.add({
      severity: 'warn',
      summary: '表单验证失败',
      detail: '请填写必填字段',
      life: 3000
    })
    return
  }

  loading.value = true

  const apiCall = props.mode === 'create'
    ? projectApi.create(form.value)
    : projectApi.update(props.project!.id, form.value)

  apiCall.then(() => {
    emit('saved')
    handleClose()
  }).catch(err => {
    console.error('保存项目失败:', err)
    toast.add({
      severity: 'error',
      summary: '保存失败',
      detail: err.message || '保存项目时发生错误',
      life: 3000
    })
  }).finally(() => {
    loading.value = false
  })
}

const isFieldInvalid = (fieldName: string) => {
  return submitted.value && !form.value[fieldName as keyof typeof form.value]
}
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="emit('update:visible', $event)"
    :header="mode === 'create' ? '新建项目' : '编辑项目'"
    modal
    class="p-fluid"
    style="width: 600px"
    @hide="handleClose"
  >
    <template #header>
      <div class="flex items-center gap-2">
        <i class="pi pi-briefcase text-blue-600"></i>
        <span class="font-semibold">{{ mode === 'create' ? '新建项目' : '编辑项目' }}</span>
      </div>
    </template>

    <div class="flex flex-col gap-6 p-4">
      <!-- 项目名称 -->
      <div class="field">
        <FloatLabel variant="on">
          <InputText
            id="name"
            v-model="form.name"
            :class="{ 'p-invalid': isFieldInvalid('name') }"
            maxlength="100"
            class="w-full"
          />
          <label for="name">项目名称 <span class="text-red-500">*</span></label>
        </FloatLabel>
        <small v-if="isFieldInvalid('name')" class="p-error">项目名称不能为空</small>
      </div>

      <!-- 开始日期 -->
      <div class="field">
        <FloatLabel variant="on">
          <Calendar
            id="start_date"
            v-model="form.start_date"
            dateFormat="yy-mm-dd"
            :class="{ 'p-invalid': isFieldInvalid('start_date') }"
            :showButtonBar="true"
            :touchUI="false"
            class="w-full"
          />
          <label for="start_date">开始日期 <span class="text-red-500">*</span></label>
        </FloatLabel>
        <small v-if="isFieldInvalid('start_date')" class="p-error">开始日期不能为空</small>
      </div>

      <!-- 项目状态 -->
      <div class="field">
        <FloatLabel variant="on">
          <Dropdown
            id="status"
            v-model="form.status"
            :options="projectStatusOptions"
            optionLabel="label"
            optionValue="value"
            class="w-full"
          />
          <label for="status">项目状态</label>
        </FloatLabel>
      </div>

      <!-- 广告自动化 -->
      <div class="field">
        <div class="flex align-items-center gap-3">
          <Checkbox
            v-model="form.active_ads_automate"
            inputId="ads_automate"
            binary
          />
          <label for="ads_automate" class="font-medium">启用广告自动化</label>
        </div>
        <small class="text-gray-600">启用后，该项目将自动执行广告相关的任务流程</small>
      </div>

      <!-- 项目描述 -->
      <div class="field">
        <FloatLabel variant="on">
          <Textarea
            id="description"
            v-model="form.description"
            rows="4"
            maxlength="500"
            autoResize
            class="w-full"
          />
          <label for="description">项目描述</label>
        </FloatLabel>
        <small class="text-gray-600">
          {{ form.description.length }}/500 字符
        </small>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          @click="handleClose"
          text
          size="small"
          severity="secondary"
          :disabled="loading"
        >
          <i class="pi pi-times mr-2"></i>
          取消
        </Button>
        <Button
          @click="handleSave"
          :loading="loading"
          size="small"
          severity="primary"
        >
          <i class="pi pi-check mr-2" v-if="!loading"></i>
          {{ mode === 'create' ? '创建' : '保存' }}
        </Button>
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
.field {
  margin-bottom: 1.5rem;
}

.p-error {
  display: block;
  margin-top: 0.25rem;
}

:deep(.p-dialog-content) {
  padding: 0;
}

:deep(.p-floatlabel label) {
  color: #64748b;
  font-weight: 500;
}

:deep(.p-floatlabel:focus-within label) {
  color: #3b82f6;
}

:deep(.p-checkbox) {
  width: 1.25rem;
  height: 1.25rem;
}
</style>
