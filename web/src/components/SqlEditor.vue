<template>
  <div class="sql-editor-container">
    <!-- 工具栏 -->
    <div class="flex items-center justify-between p-3 bg-surface-50 border-b border-surface-200">
      <div class="flex items-center gap-2">
        <Button
          @click="formatSql"
          icon="pi pi-code"
          label="格式化"
          size="small"
          severity="secondary"
          :disabled="!modelValue"
        />

        <Button
          @click="clearSql"
          icon="pi pi-trash"
          label="清空"
          size="small"
          severity="secondary"
          :disabled="!modelValue"
        />

        <Divider layout="vertical" />

        <!-- SQL模板 -->
        <Dropdown
          v-model="selectedTemplate"
          :options="sqlTemplates"
          optionLabel="name"
          optionValue="sql"
          placeholder="选择模板"
          size="small"
          class="w-40"
          @change="insertTemplate"
          showClear
        />

        <Button
          @click="showFullscreen = true"
          icon="pi pi-window-maximize"
          size="small"
          severity="secondary"
          v-tooltip="'全屏编辑'"
        />
      </div>

      <div class="flex items-center gap-2 text-sm text-surface-600">
        <span v-if="modelValue">{{ getStats().lines }} 行</span>
        <span v-if="modelValue">{{ getStats().characters }} 字符</span>
      </div>
    </div>

    <!-- SQL编辑器 -->
    <div class="sql-editor-wrapper" :style="{ height: `${height}px` }">
      <AceEditor
        ref="aceEditorRef"
        v-model="internalValue"
        :height="height"
        :placeholder="placeholder"
        @execute="handleExecute"
        @cursor-change="updateCursorPosition"
      />
    </div>

    <!-- 状态栏 -->
    <div v-if="showStatusBar" class="flex items-center justify-between p-2 bg-surface-50 border-t border-surface-200 text-xs text-surface-600 min-w-160">
      <div class="flex items-center gap-4">
        <span>SQL</span>
        <span v-if="modelValue">UTF-8</span>
      </div>
      <div class="flex items-center gap-4">
        <span v-if="cursorPosition.line">第 {{ cursorPosition.line }} 行，第 {{ cursorPosition.column }} 列</span>
      </div>
    </div>

    <!-- 全屏编辑器对话框 -->
    <SqlEditorDialog
      v-model:visible="showFullscreen"
      v-model:sql="internalValue"
      :database-connection="Database"
      @execute="handleExecute"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { SQL_TEMPLATES } from '@/data/constants/database-constants'
import type { Database } from '@/data/types/database-types'

import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import Divider from 'primevue/divider'
import AceEditor from '@/components/AceEditor.vue'
import SqlEditorDialog from '@/views/_dialogs/SqlEditorDialog.vue'

// Props & Emits
const props = withDefaults(defineProps<{
  modelValue: string
  height?: number
  placeholder?: string
  showStatusBar?: boolean
  Database?: Database | null
}>(), {
  height: 200,
  placeholder: '-- 请输入SQL语句\nSELECT * FROM table_name;',
  showStatusBar: true
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  execute: [sql: string]
}>()

// Data
const aceEditorRef = ref<InstanceType<typeof AceEditor>>()
const showFullscreen = ref(false)
const selectedTemplate = ref('')
const cursorPosition = ref({ line: 1, column: 1 })

// Computed
const internalValue = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const sqlTemplates = SQL_TEMPLATES

// Methods
const updateCursorPosition = (position: { line: number, column: number }) => {
  cursorPosition.value = position
}

const formatSql = () => {
  aceEditorRef.value?.formatCode()
}

const clearSql = () => {
  aceEditorRef.value?.clear()
}

const insertTemplate = () => {
  if (selectedTemplate.value && aceEditorRef.value) {
    aceEditorRef.value.setValue(selectedTemplate.value)
    selectedTemplate.value = ''
  }
}

const getStats = () => {
  const text = aceEditorRef.value?.getValue() || ''
  return {
    lines: text ? text.split('\n').length : 0,
    characters: text.length
  }
}

const handleExecute = (sql: string) => {
  emit('execute', sql)
}

// Watch
watch(() => props.modelValue, () => {
  selectedTemplate.value = ''
})
</script>

<style scoped>
.sql-editor-container {
  border: 1px solid var(--p-surface-border);
  border-radius: 6px;
  overflow: hidden;
  background: white;
}

.sql-editor-wrapper {
  position: relative;
  overflow: hidden;
}
</style>
