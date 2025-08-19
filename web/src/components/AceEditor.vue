<template>
  <div :id="editorId" class="ace-editor-base" :class="wrapperClass"></div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import ace from 'ace-builds'
import 'ace-builds/src-noconflict/mode-sql'
import 'ace-builds/src-noconflict/theme-github'
import 'ace-builds/src-noconflict/theme-monokai'
import 'ace-builds/src-noconflict/ext-language_tools'
import 'ace-builds/src-noconflict/ext-searchbox'

// Props & Emits
const props = withDefaults(defineProps<{
  modelValue: string
  placeholder?: string
  height?: number | string
  theme?: string
  mode?: string
  fontSize?: number
  minLines?: number
  maxLines?: number | null
  readonly?: boolean
  wrapperClass?: string
  enableAutoComplete?: boolean
  enableExecuteShortcut?: boolean
}>(), {
  placeholder: '-- 请输入SQL语句\nSELECT * FROM table_name;',
  theme: 'ace/theme/github',
  mode: 'ace/mode/sql',
  fontSize: 14,
  minLines: 3,
  maxLines: null,
  readonly: false,
  wrapperClass: '',
  enableAutoComplete: true,
  enableExecuteShortcut: true
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'execute': [value: string]
  'change': [value: string]
  'ready': [editor: ace.Ace.Editor]
  'cursorChange': [position: { line: number, column: number }]
}>()

// Data
const editorId = ref(`ace-editor-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`)
let aceEditor: ace.Ace.Editor | null = null

// Computed
const editorHeight = computed(() => {
  if (typeof props.height === 'number') {
    return `${props.height}px`
  }
  return props.height || '100%'
})

// Methods
const initAceEditor = () => {
  nextTick(() => {
    const element = document.getElementById(editorId.value)
    if (!element) return

    aceEditor = ace.edit(element)
    
    // 配置编辑器
    aceEditor.setTheme(props.theme)
    aceEditor.session.setMode(props.mode)
    aceEditor.setReadOnly(props.readonly)
    
    // 启用功能
    aceEditor.setOptions({
      enableBasicAutocompletion: props.enableAutoComplete,
      enableSnippets: props.enableAutoComplete,
      enableLiveAutocompletion: props.enableAutoComplete,
      fontSize: props.fontSize,
      fontFamily: 'Monaco, Menlo, Consolas, monospace',
      showPrintMargin: false,
      wrap: true,
      autoScrollEditorIntoView: false,
      maxLines: props.maxLines || undefined,
      minLines: props.minLines,
      scrollPastEnd: 0.1,
      vScrollBarAlwaysVisible: true,
      hScrollBarAlwaysVisible: false
    })

    // 设置初始值
    if (props.modelValue) {
      aceEditor.setValue(props.modelValue, -1)
    }

    // 监听变化
    aceEditor.on('change', () => {
      const value = aceEditor!.getValue()
      emit('update:modelValue', value)
      emit('change', value)
    })

    // 监听光标位置变化
    aceEditor.on('changeSelection', () => {
      if (!aceEditor) return
      const cursor = aceEditor.getCursorPosition()
      emit('cursorChange', {
        line: cursor.row + 1,
        column: cursor.column + 1
      })
    })

    // 绑定执行快捷键
    if (props.enableExecuteShortcut) {
      aceEditor.commands.addCommand({
        name: 'execute',
        bindKey: { win: 'Ctrl-Enter', mac: 'Cmd-Enter' },
        exec: () => {
          const sql = aceEditor!.getValue()
          if (sql.trim()) {
            emit('execute', sql)
          }
        }
      })
    }

    // 设置占位符文本
    if (!props.modelValue) {
      setupPlaceholder()
    }

    // 通知父组件编辑器已准备好
    emit('ready', aceEditor)
  })
}

const setupPlaceholder = () => {
  if (!aceEditor) return
  
  aceEditor.renderer.on('afterRender', function() {
    if (aceEditor!.getValue().length === 0 && !(aceEditor! as any).completer) {
      const renderer = aceEditor!.renderer as any;
      renderer.$emptyMessageNode = renderer.$emptyMessageNode || renderer.scroller.appendChild(document.createElement('div'))
      renderer.$emptyMessageNode.innerHTML = props.placeholder.replace(/\n/g, '<br>')
      renderer.$emptyMessageNode.className = 'ace_invisible ace_emptyMessage'
      renderer.$emptyMessageNode.style.padding = '12px'
      renderer.$emptyMessageNode.style.position = 'absolute'
      renderer.$emptyMessageNode.style.zIndex = '4'
      renderer.$emptyMessageNode.style.opacity = '0.5'
      renderer.$emptyMessageNode.style.lineHeight = '1.5'
    } else if ((aceEditor!.renderer as any).$emptyMessageNode) {
      (aceEditor!.renderer as any).$emptyMessageNode.style.display = 'none'
    }
  })
}

// 公开的方法供父组件调用
const setValue = (value: string) => {
  if (aceEditor) {
    aceEditor.setValue(value, -1)
  }
}

const getValue = (): string => {
  return aceEditor ? aceEditor.getValue() : ''
}

const formatCode = () => {
  if (!aceEditor || !aceEditor.getValue()) return

  // 简单的SQL格式化
  let formatted = aceEditor.getValue()
    .replace(/\s+/g, ' ') // 合并多个空格
    .replace(/\s*;\s*/g, ';\n') // 分号后换行
    .replace(/\b(SELECT|FROM|WHERE|JOIN|LEFT JOIN|RIGHT JOIN|INNER JOIN|GROUP BY|ORDER BY|HAVING|UNION|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE)\b/gi, '\n$1') // 关键字前换行
    .replace(/,\s*/g, ',\n  ') // 逗号后换行并缩进
    .split('\n')
    .map(line => line.trim())
    .filter(line => line)
    .join('\n')

  aceEditor.setValue(formatted, -1)
}

const clear = () => {
  if (aceEditor) {
    aceEditor.setValue('', -1)
  }
}

const focus = () => {
  if (aceEditor) {
    aceEditor.focus()
  }
}

const resize = () => {
  if (aceEditor) {
    aceEditor.resize()
  }
}

const getCursorPosition = () => {
  if (!aceEditor) return { line: 1, column: 1 }
  const cursor = aceEditor.getCursorPosition()
  return {
    line: cursor.row + 1,
    column: cursor.column + 1
  }
}

// 暴露方法给父组件
defineExpose({
  setValue,
  getValue,
  formatCode,
  clear,
  focus,
  resize,
  getCursorPosition,
  editor: computed(() => aceEditor)
})

// Lifecycle
onMounted(() => {
  initAceEditor()
})

onBeforeUnmount(() => {
  if (aceEditor) {
    aceEditor.destroy()
    aceEditor = null
  }
})

// Watch
watch(() => props.modelValue, (newValue) => {
  if (aceEditor && aceEditor.getValue() !== newValue) {
    aceEditor.setValue(newValue || '', -1)
  }
})

watch(() => props.height, () => {
  if (aceEditor) {
    nextTick(() => {
      aceEditor!.resize()
    })
  }
})

watch(() => props.readonly, (newValue) => {
  if (aceEditor) {
    aceEditor.setReadOnly(newValue)
  }
})

watch(() => props.theme, (newValue) => {
  if (aceEditor) {
    aceEditor.setTheme(newValue)
  }
})

watch(() => props.fontSize, (newValue) => {
  if (aceEditor) {
    aceEditor.setFontSize(newValue)
  }
})
</script>

<style scoped>
.ace-editor-base {
  width: 100%;
  height: v-bind(editorHeight);
  position: relative;
}

/* Ace编辑器样式覆盖 */
:deep(.ace_editor) {
  border: none !important;
  border-radius: 0 !important;
  font-family: 'Monaco', 'Menlo', 'Consolas', monospace !important;
  font-size: 14px !important;
  line-height: 1.5 !important;
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

/* 滚动条样式 */
:deep(.ace_scrollbar) {
  background: var(--p-surface-100) !important;
}

:deep(.ace_scrollbar-inner) {
  background: var(--p-surface-300) !important;
  border-radius: 2px !important;
}

:deep(.ace_scrollbar-inner:hover) {
  background: var(--p-surface-400) !important;
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
</style>