<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import DatabaseApi from '@/api/database-api'
import type { DatabaseForm, Database } from '@/data/types/database-types'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import DatasourceForm from '@/views/_form/DatasourceForm.vue'

// Props & Emits
const props = defineProps<{
  visible: boolean
  database?: Database | null
  mode: 'create' | 'edit'
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  success: []
}>()

// Services
const toast = useToast()

// Data
const loading = ref(false)
const datasourceFormRef = ref()

const form = ref<DatabaseForm>({
  name: '',
  db_type: 'mysql',
  host: '',
  port: 3306,
  username: '',
  password: '',
  description: '',
  extra_config: {},
  catalog_id: undefined
})

// Computed
const dialogVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

const dialogTitle = computed(() => {
  return props.mode === 'create' ? '新增数据库连接' : '编辑数据库连接'
})

const submitButtonLabel = computed(() => {
  return props.mode === 'create' ? '创建' : '保存'
})


// Methods
const resetForm = () => {
  form.value = {
    name: '',
    db_type: 'mysql',
    host: '',
    port: 3306,
    username: '',
    password: '',
    description: '',
    extra_config: {},
    catalog_id: undefined
  }
}

const initForm = () => {
  if (props.mode === 'edit' && props.database) {
    form.value = {
      name: props.database.name,
      db_type: props.database.db_type,
      host: props.database.host,
      port: props.database.port,
      username: props.database.username,
      password: props.database.password || '',
      description: props.database.description || '',
      extra_config: props.database.extra_config || {},
      catalog_id: props.database.catalog_id
    }
  } else {
    resetForm()
  }
}

const handleSubmit = async () => {
  // 验证表单
  if (!datasourceFormRef.value?.validateForm() || !datasourceFormRef.value?.isFormValid) {
    return
  }

  loading.value = true

  try {
    let response
    if (props.mode === 'create') {
      response = await DatabaseApi.create(form.value)
    } else {
      response = await DatabaseApi.update(props.database!.id, form.value)
    }

    if (response.code === 200) {
      toast.add({
        severity: 'success',
        summary: props.mode === 'create' ? '创建成功' : '更新成功',
        detail: response.data.message,
        life: 3000
      })

      emit('success')
      dialogVisible.value = false
      resetForm()
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: props.mode === 'create' ? '创建失败' : '更新失败',
      detail: error.message,
      life: 5000
    })
  } finally {
    loading.value = false
  }
}


// Watch
watch(() => props.visible, (newVisible) => {
  if (newVisible) {
    initForm()
  }
})
</script>

<template>
  <Dialog
    v-model:visible="dialogVisible"
    modal
    :header="dialogTitle"
    class="w-full max-w-2xl"
    content-class="pt-2"
    :closable="true"
    :draggable="false"
  >
    <DatasourceForm
      ref="datasourceFormRef"
      v-model="form"
      :mode="mode"
      :datasource="database"
      :show-test-button="true"
      @submit="handleSubmit"
    />

    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          @click="dialogVisible = false"
          label="取消"
          severity="secondary"
          size="small"
        />
        <Button
          @click="handleSubmit"
          :label="submitButtonLabel"
          size="small"
          :loading="loading"
        />
      </div>
    </template>
  </Dialog>
</template>