<template>
  <Dialog
    v-model:visible="dialogVisible"
    modal
    header="SQL编辑器"
    class="w-full max-w-6xl h-full max-h-[90vh]"
    :closable="true"
    :draggable="false"
    :maximizable="true"
  >
    <div class="flex flex-col h-full min-h-[600px]">
      <!-- 编辑器工具栏 -->
      <div class="flex items-center justify-between p-3 bg-surface-50 border-b border-surface-200">
        <div class="flex items-center gap-2">
          <Button
            @click="formatSql"
            icon="pi pi-code"
            label="格式化"
            size="small"
            severity="secondary"
            :disabled="!sqlValue"
          />

          <Button
            @click="clearSql"
            icon="pi pi-trash"
            label="清空"
            size="small"
            severity="secondary"
            :disabled="!sqlValue"
          />

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
        </div>

        <div class="flex items-center gap-4 text-sm text-surface-600">
          <span>{{ getStats().lines }} 行</span>
          <span>{{ getStats().characters }} 字符</span>
          <span v-if="cursorPosition.line">第 {{ cursorPosition.line }} 行，第 {{ cursorPosition.column }} 列</span>
        </div>
      </div>

      <!-- SQL编辑器 -->
      <div class="flex-1 relative">
        <AceEditor
          ref="aceEditorRef"
          v-model="sqlValue"
          :placeholder="'-- 请输入SQL语句\nSELECT * FROM table_name\nWHERE condition\nLIMIT 10;'"
          :min-lines="15"
          :enable-execute-shortcut="false"
          @cursor-change="updateCursorPosition"
          wrapper-class="ace-editor-fullscreen"
        />
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <div class="text-sm text-surface-600">
          提示: 使用 Ctrl+F 搜索，Ctrl+H 替换
        </div>
        <div class="flex gap-2">
          <Button
            @click="dialogVisible = false"
            label="关闭"
            severity="secondary"
            size="small"
          />
          <Button
            @click="saveAndClose"
            label="保存并关闭"
            size="small"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { SQL_TEMPLATES } from '@/data/constants/database-constants'

import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import AceEditor from '@/components/AceEditor.vue'

// Props & Emits
const props = defineProps<{
  visible: boolean
  sql: string
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  'update:sql': [value: string]
}>()

// Data
const aceEditorRef = ref<InstanceType<typeof AceEditor>>()
const selectedTemplate = ref('')
const cursorPosition = ref({ line: 1, column: 1 })

// Computed
const dialogVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

const sqlValue = computed({
  get: () => props.sql,
  set: (value) => emit('update:sql', value)
})

const sqlTemplates = SQL_TEMPLATES

// Methods
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

const updateCursorPosition = (position: { line: number, column: number }) => {
  cursorPosition.value = position
}


const saveAndClose = () => {
  dialogVisible.value = false
}


const getStats = () => {
  const text = aceEditorRef.value?.getValue() || ''
  return {
    lines: text ? text.split('\n').length : 0,
    characters: text.length
  }
}


// Lifecycle
onMounted(() => {
  if (props.Database) {
    loadDatabases()
  }
})


// Watch
watch(() => props.Database, (newConnection) => {
  if (newConnection) {
    loadDatabases()
  }
})
</script>

<style scoped>
.ace-editor-fullscreen {
  width: 100%;
  height: 100%;
  position: relative;
}

/* Ace编辑器样式覆盖 */
:deep(.ace_editor) {
  border: none !important;
  border-radius: 0 !important;
  font-family: 'Monaco', 'Menlo', 'Consolas', monospace !important;
  font-size: 14px !important;
  line-height: 1.6 !important;
}

:deep(.ace_content) {
  background: #fafafa !important;
}

:deep(.ace_gutter) {
  background: #f5f5f5 !important;
  border-right: 1px solid #e0e0e0 !important;
}

:deep(.ace_gutter-active-line) {
  background: #e8f4fd !important;
}

:deep(.ace_active-line) {
  background: rgba(0, 0, 0, 0.02) !important;
}

:deep(.ace_cursor) {
  color: #333 !important;
}

:deep(.ace_selection) {
  background: rgba(13, 110, 253, 0.2) !important;
}

/* SQL语法高亮自定义 */
:deep(.ace_keyword) {
  color: #0969da !important;
  font-weight: bold !important;
}

:deep(.ace_string) {
  color: #0a3069 !important;
}

:deep(.ace_comment) {
  color: #656d76 !important;
  font-style: italic !important;
}

:deep(.ace_constant.ace_numeric) {
  color: #0969da !important;
}

:deep(.ace_identifier) {
  color: #24292f !important;
}

/* 占位符样式 */
:deep(.ace_emptyMessage) {
  color: #6b7280 !important;
  font-style: italic !important;
  pointer-events: none !important;
}

/* 搜索框样式 */
:deep(.ace_search) {
  background: white !important;
  border: 1px solid var(--p-surface-border) !important;
  border-radius: 4px !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15) !important;
}

:deep(.ace_search_field) {
  border: 1px solid var(--p-surface-border) !important;
  border-radius: 3px !important;
  padding: 4px 8px !important;
}

:deep(.ace_searchbtn) {
  border: 1px solid var(--p-surface-border) !important;
  border-radius: 3px !important;
  background: var(--p-surface-50) !important;
}

:deep(.ace_searchbtn:hover) {
  background: var(--p-surface-100) !important;
}

:deep(.p-dialog-content) {
  padding: 0 !important;
}

:deep(.p-datatable-tbody tr td) {
  padding: 4px 8px !important;
  font-size: 12px !important;
}

:deep(.p-datatable-thead tr th) {
  padding: 8px !important;
  font-size: 12px !important;
  background: var(--p-surface-100) !important;
}
</style>
