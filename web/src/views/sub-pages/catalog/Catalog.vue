<script setup lang="ts">
import { onMounted, unref, watch } from "vue";
import { ApiDelete, ApiList, ApiUpdate } from "@/api/base-api";
import { SpaceType } from "@/data/types/type";
import AddCatalog from "@/views/_dialogs/AddCatalog.vue";
import AddSpace from "@/views/_dialogs/AddSpace.vue";
import { useRoute, useRouter } from "vue-router";
import { useToast } from "primevue/usetoast";
import { useConfirm } from "primevue/useconfirm";
import draggable from "vuedraggable";

const route = useRoute()
const router = useRouter()
const toast = useToast();
const confirm = useConfirm();

const props = defineProps<{ type: SpaceType }>()
const emit = defineEmits(["onChange"])

const filter = ref("")
const edit_catalog = ref<int>(null)
const edit_catalog_name = ref<string>("")
const edit_space = ref<int>(null)
const edit_space_name = ref<string>("")
const spaces = ref<Space[]>([])
const checked_catalogs = ref<int[]>([])
const show_create_space_popup = ref(false)
const show_create_catalog_popup = ref(false)

const tryFindFirstCatalog = () => {
  for (let _space of unref(spaces)) {
    if (_space.catalogs && _space.catalogs.length > 0) {
      console.log("Found first catalog:", _space.catalogs[0].id)
      return [_space.catalogs[0].id];
    }
  }
  return [];
};

const handleGetAllSpaces = () => {
  ApiList("space", { type: props.type }).then((data) => {
    spaces.value = data
    if (checked_catalogs.value.length === 0) {
      checked_catalogs.value = tryFindFirstCatalog()
    }
  }).catch((error) => {
    console.error("Failed to fetch spaces:", error)
    toast.add({ severity: 'error', summary: '获取空间失败', detail: error.msg || '网络错误', life: 3000 });
  })
}

// 编辑目录
const handleEditCatalog = (catalog_id: int, catalog_name: string) => {
  edit_catalog.value = catalog_id
  edit_catalog_name.value = catalog_name
}

// 保存目录编辑
const handleSaveEditCatalog = () => {
  if (edit_catalog_name.value.trim() === "") {
    toast.add({ severity: 'error', summary: '目录名称不能为空', life: 3000 });
    return
  }
  ApiUpdate("catalog", edit_catalog.value, { name: edit_catalog_name.value }).then(() => {
    toast.add({ severity: 'success', summary: '重命名成功', life: 3000 });
    cancelEditCatalog()
    handleGetAllSpaces()
  }).catch((error) => {
    toast.add({ severity: 'error', summary: '重命名失败', detail: error.msg || '网络错误', life: 3000 });
  })
}

// 取消目录编辑
const cancelEditCatalog = () => {
  edit_catalog.value = null
  edit_catalog_name.value = ""
}

// 确认删除目录
const confirmDeleteCatalog = (event, catalog_id: int, catalog_name: string) => {
  confirm.require({
    target: event.currentTarget,
    message: `确定要删除目录 "${catalog_name}" 吗？`,
    header: '删除目录',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    acceptLabel: '删除',
    rejectLabel: '取消',
    accept: () => {
      handleDeleteCatalog(catalog_id);
    },
    reject: () => {
      toast.add({ severity: 'info', summary: '已取消删除', life: 3000 });
    }
  });
};

// 删除目录
const handleDeleteCatalog = (catalog_id: int) => {
  ApiDelete("catalog", catalog_id).then(() => {
    toast.add({ severity: 'success', summary: '删除目录成功', life: 3000 });
    // 如果删除的目录在选中列表中，需要移除
    if (checked_catalogs.value.includes(catalog_id)) {
      checked_catalogs.value = checked_catalogs.value.filter(id => id !== catalog_id);
      // 如果没有选中的目录了，尝试选择第一个可用目录
      if (checked_catalogs.value.length === 0) {
        setTimeout(() => {
          checked_catalogs.value = tryFindFirstCatalog();
        }, 100);
      }
    }
    handleGetAllSpaces()
  }).catch((error) => {
    toast.add({ severity: 'error', summary: '删除目录失败', detail: error.msg || '网络错误', life: 3000 });
  })
}

// 编辑空间
const handleEditSpace = (space_id: int, space_name: string) => {
  edit_space.value = space_id
  edit_space_name.value = space_name
}

// 保存空间编辑
const handleSaveEditSpace = () => {
  if (edit_space_name.value.trim() === "") {
    toast.add({ severity: 'error', summary: '空间名称不能为空', life: 3000 });
    return
  }
  ApiUpdate("space", edit_space.value, { name: edit_space_name.value }).then(() => {
    toast.add({ severity: 'success', summary: '重命名成功', life: 3000 });
    cancelEditSpace()
    handleGetAllSpaces()
  }).catch((error) => {
    toast.add({ severity: 'error', summary: '重命名失败', detail: error.msg || '网络错误', life: 3000 });
  })
}

// 取消空间编辑
const cancelEditSpace = () => {
  edit_space.value = null
  edit_space_name.value = ""
}

// 确认删除空间
const confirmDeleteSpace = (event, space_id: int, space_name: string) => {
  confirm.require({
    target: event.currentTarget,
    message: `确定要删除空间 "${space_name}" 及其所有目录吗？此操作不可撤销！`,
    header: '删除空间',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    acceptLabel: '删除',
    rejectLabel: '取消',
    accept: () => {
      handleDeleteSpace(space_id);
    },
    reject: () => {
      toast.add({ severity: 'info', summary: '已取消删除', life: 3000 });
    }
  });
};

// 删除空间
const handleDeleteSpace = (space_id: int) => {
  ApiDelete("space", space_id).then(() => {
    toast.add({ severity: 'success', summary: '删除空间成功', life: 3000 });
    // 如果删除的空间包含选中的目录，需要重新选择
    const deletedSpace = spaces.value.find(s => s.id === space_id);
    if (deletedSpace && deletedSpace.catalogs) {
      const deletedCatalogIds = deletedSpace.catalogs.map(c => c.id);
      const hasSelectedCatalogs = deletedCatalogIds.some(id => checked_catalogs.value.includes(id));
      if (hasSelectedCatalogs) {
        checked_catalogs.value = checked_catalogs.value.filter(id => !deletedCatalogIds.includes(id));
        // 如果没有选中的目录了，尝试选择第一个可用目录
        setTimeout(() => {
          if (checked_catalogs.value.length === 0) {
            checked_catalogs.value = tryFindFirstCatalog();
          }
        }, 100);
      }
    }
    handleGetAllSpaces()
  }).catch((error) => {
    toast.add({ severity: 'error', summary: '删除空间失败', detail: error.msg || '网络错误', life: 3000 });
  })
}

// 拖拽相关状态
const drag_state = ref({
  dragging_catalog_id: null as number | null,
  drag_over_space_id: null as number | null,
  drag_over_catalog_id: null as number | null,
  drop_position: null as 'before' | 'after' | null,
  is_dragging: false,
  drag_type: null as 'move' | 'sort' | null
})

// 拖拽事件处理
const handleDragStart = (event: DragEvent, catalog_id: number, source_space_id: number) => {
  if (edit_catalog.value || edit_space.value) return; // 编辑模式下不允许拖拽

  drag_state.value.dragging_catalog_id = catalog_id
  drag_state.value.is_dragging = true

  // 设置拖拽数据
  event.dataTransfer!.effectAllowed = 'move'
  event.dataTransfer!.setData('text/plain', JSON.stringify({
    catalog_id,
    source_space_id
  }))
}

const handleDragEnd = () => {
  drag_state.value.dragging_catalog_id = null
  drag_state.value.drag_over_space_id = null
  drag_state.value.drag_over_catalog_id = null
  drag_state.value.drop_position = null
  drag_state.value.is_dragging = false
  drag_state.value.drag_type = null
}

const handleDragOver = (event: DragEvent, space_id: number) => {
  event.preventDefault()
  event.dataTransfer!.dropEffect = 'move'
  drag_state.value.drag_over_space_id = space_id
}

const handleDragLeave = (event: DragEvent) => {
  // 只有当离开的是空间容器本身时才清除状态
  if (!event.currentTarget?.contains(event.relatedTarget as Node)) {
    drag_state.value.drag_over_space_id = null
  }
}

// 目录排序相关拖拽处理
const handleCatalogDragOver = (event: DragEvent, catalog_id: number, space_id: number) => {
  event.preventDefault()
  event.dataTransfer!.dropEffect = 'move'
  
  // 获取拖拽数据
  try {
    const data = JSON.parse(event.dataTransfer!.getData('text/plain'))
    const { catalog_id: dragging_id, source_space_id } = data
    
    // 如果是同一个目录，不处理
    if (dragging_id === catalog_id) return
    
    // 确定拖拽类型
    if (source_space_id === space_id) {
      // 同空间内排序
      drag_state.value.drag_type = 'sort'
      drag_state.value.drag_over_catalog_id = catalog_id
      
      // 计算放置位置（上半部分为before，下半部分为after）
      const rect = event.currentTarget.getBoundingClientRect()
      const midY = rect.top + rect.height / 2
      drag_state.value.drop_position = event.clientY < midY ? 'before' : 'after'
    } else {
      // 跨空间移动
      drag_state.value.drag_type = 'move'
      drag_state.value.drag_over_space_id = space_id
    }
  } catch (error) {
    console.error('Drag over error:', error)
  }
}

const handleCatalogDragLeave = (event: DragEvent) => {
  // 只有当真正离开目录项时才清除状态
  if (!event.currentTarget?.contains(event.relatedTarget as Node)) {
    drag_state.value.drag_over_catalog_id = null
    drag_state.value.drop_position = null
  }
}

const handleCatalogDrop = async (event: DragEvent, target_catalog_id: number, target_space_id: number) => {
  event.preventDefault()
  event.stopPropagation() // 防止冒泡到空间处理器
  
  try {
    const data = JSON.parse(event.dataTransfer!.getData('text/plain'))
    const { catalog_id, source_space_id } = data
    
    if (drag_state.value.drag_type === 'sort' && source_space_id === target_space_id) {
      // 同空间内排序 - 这个逻辑已由vuedraggable的@end事件处理
      console.log('Catalog sorting within same space - handled by vuedraggable')
    } else if (drag_state.value.drag_type === 'move') {
      // 跨空间移动
      await moveCatalogToSpace(catalog_id, target_space_id)
    }
    
  } catch (error) {
    console.error('Catalog drop handling error:', error)
    toast.add({ 
      severity: 'error', 
      summary: '操作失败', 
      detail: '拖拽数据解析失败', 
      life: 3000 
    });
  } finally {
    handleDragEnd()
  }
}

const handleDrop = async (event: DragEvent, target_space_id: number) => {
  event.preventDefault()

  try {
    const data = JSON.parse(event.dataTransfer!.getData('text/plain'))
    const { catalog_id, source_space_id } = data

    // 检查是否真的需要移动
    if (source_space_id === target_space_id) {
      toast.add({
        severity: 'info',
        summary: '无需移动',
        detail: '目录已在目标空间中',
        life: 3000
      });
      return
    }

    // 调用移动API
    await moveCatalogToSpace(catalog_id, target_space_id)

  } catch (error) {
    console.error('Drop handling error:', error)
    toast.add({
      severity: 'error',
      summary: '移动失败',
      detail: '拖拽数据解析失败',
      life: 3000
    });
  } finally {
    handleDragEnd()
  }
}

// 移动目录到指定空间
const moveCatalogToSpace = async (catalog_id: number, target_space_id: number) => {
  try {
    await ApiUpdate('catalog', catalog_id, { space_id: target_space_id })

    toast.add({
      severity: 'success',
      summary: '移动成功',
      detail: '目录已成功移动到新空间',
      life: 3000
    });

    // 刷新数据
    handleGetAllSpaces()

  } catch (error) {
    console.error('Move catalog error:', error)
    toast.add({
      severity: 'error',
      summary: '移动失败',
      detail: error.msg || '网络错误',
      life: 3000
    });
  }
}

// 处理目录排序变化
const handleCatalogSort = async (space: any) => {
  try {
    // 构建排序数据
    const sortData = space.catalogs.map((catalog: any, index: number) => ({
      id: catalog.id,
      sort: index
    }));

    // 调用批量排序API
    const response = await fetch('/catalog/batch_sort', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        space_id: space.id,
        catalog_sorts: sortData
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const result = await response.json();

    if (result.code === 200) {
      toast.add({
        severity: 'success',
        summary: '排序成功',
        detail: '目录顺序已保存',
        life: 2000
      });
    } else {
      throw new Error(result.msg || '排序失败');
    }

  } catch (error) {
    console.error('Sort catalog error:', error);
    toast.add({
      severity: 'error',
      summary: '排序失败',
      detail: error.message || '网络错误',
      life: 3000
    });
    
    // 失败时刷新数据恢复原状态
    handleGetAllSpaces();
  }
}

// 跨空间移动目录
const handleCatalogMove = async (evt: any, targetSpace: any) => {
  if (evt.from === evt.to) return; // 同一空间内移动，已由排序处理
  
  const movedCatalog = evt.item._underlying_vm_;
  if (movedCatalog) {
    await moveCatalogToSpace(movedCatalog.id, targetSpace.id);
  }
}


// 计算属性
const catalogs_from_url = computed(() => {
  if (!route.query.catalogs) {
    return []
  } else {
    return route.query.catalogs.toString().split(',').map(Number) ?? []
  }
})

const filter_spaces = computed(() => {
  if (filter.value.trim() === "") {
    return unref(spaces)
  } else {
    const keyword = filter.value.trim().toLowerCase()
    return unref(spaces).map(space => {
      if (space.name.toLowerCase().includes(keyword)) {
        return space
      }
      const filtered_catalogs = space.catalogs.filter(catalog => catalog.name.toLowerCase().includes(keyword))
      return { ...space, catalogs: filtered_catalogs }
    })
  }
})

// 生命周期和监听
onMounted(() => handleGetAllSpaces())

watch(() => catalogs_from_url.value, (value) => {
  if (value.length > 0) {
    checked_catalogs.value = value
    emit("onChange", value)
  }
}, { immediate: true })

watch(() => checked_catalogs.value, (value) => {
  router.push({ path: route.path, query: { catalogs: value.join(',') } })
  emit("onChange", value)
}, { immediate: true })
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- 搜索栏 -->
    <div class="h-14 flex items-center justify-between gap-2 p-2 border-surface border-b bg-gray-50">
      <FloatLabel variant="on" class="flex-1">
        <IconField>
          <InputIcon class="pi pi-search"/>
          <InputText id="catalog_search" v-model="filter" autocomplete="on" size="small" class="w-full"/>
        </IconField>
        <label for="catalog_search">搜索空间或目录</label>
      </FloatLabel>
    </div>

    <!-- 空间和目录列表 -->
    <div class="flex-1 flex flex-col overflow-auto justify-between gap-4 pt-4 pb-4 px-4">
      <div class="flex-1 overflow-auto flex flex-col gap-3">
        <div class="space-item relative" v-for="space in unref(filter_spaces)" :key="space.id">
          <!-- 空间标题 -->
          <div class="flex items-center justify-between group p-2 rounded-lg hover:bg-gray-50 transition-colors"
               :class="{
                 'bg-blue-50 border-2 border-dashed border-blue-300': drag_state.drag_over_space_id === space.id,
                 'bg-gray-100': drag_state.is_dragging && drag_state.drag_over_space_id !== space.id
               }"
               @dragover="handleDragOver($event, space.id)"
               @dragleave="handleDragLeave"
               @drop="handleDrop($event, space.id)">

            <!-- 拖拽提示 -->
            <div v-if="drag_state.drag_over_space_id === space.id && drag_state.is_dragging"
                 class="absolute inset-0 flex items-center justify-center bg-blue-50 bg-opacity-90 rounded-lg border-2 border-dashed border-blue-400 z-10">
              <div class="text-blue-600 font-medium flex items-center gap-2">
                <i class="pi pi-arrow-down"></i>
                将目录移动到此空间
              </div>
            </div>
            <div class="flex items-center gap-2">
              <i class="pi pi-folder text-blue-500"></i>
              <div v-if="edit_space !== space.id"
                   class="text-sm font-semibold text-gray-700 cursor-pointer"
                   @click="handleEditSpace(space.id, space.name)">
                {{ space.name }}
              </div>
              <InputText v-else
                         v-model="edit_space_name"
                         size="small"
                         class="text-sm font-semibold w-full"
                         @keyup.enter="handleSaveEditSpace"
                         @keyup.escape="cancelEditSpace"/>
            </div>

            <!-- 空间操作按钮 -->
            <div class="space-actions flex items-center gap-0 opacity-0 group-hover:opacity-100 transition-opacity">
              <template v-if="edit_space !== space.id">
                <Button icon="pi pi-pencil"
                        text
                        size="small"
                        severity="secondary"
                        v-tooltip.top="'编辑空间'"
                        @click="handleEditSpace(space.id, space.name)"/>
                <Button icon="pi pi-trash"
                        text
                        size="small"
                        severity="danger"
                        v-tooltip.top="'删除空间'"
                        @click="confirmDeleteSpace($event, space.id, space.name)"/>
              </template>
              <template v-else>
                <Button icon="pi pi-check"
                        text
                        size="small"
                        severity="success"
                        v-tooltip.top="'保存'"
                        @click="handleSaveEditSpace"/>
                <Button icon="pi pi-times"
                        text
                        size="small"
                        severity="secondary"
                        v-tooltip.top="'取消'"
                        @click="cancelEditSpace"/>
              </template>
            </div>
          </div>

          <!-- 目录列表 -->
          <div class="ml-2 flex flex-col gap-1">
            <draggable 
              v-model="space.catalogs"
              group="catalogs"
              item-key="id"
              class="flex flex-col gap-1"
              :disabled="edit_catalog || edit_space"
              @end="handleCatalogSort(space)"
              @add="handleCatalogMove($event, space)"
              ghost-class="ghost-catalog"
              chosen-class="chosen-catalog"
              drag-class="drag-catalog">
              
              <template #item="{ element: catalog }">
                <div class="catalog-item cursor-pointer text-color px-2 py-1 rounded-lg flex items-center gap-0 hover:bg-blue-50 transition-all flex-row justify-between group"
                     :class="{
                       'bg-blue-100 border-l-4 border-blue-500': checked_catalogs.includes(catalog.id),
                       'cursor-move': !edit_catalog && !edit_space
                     }"
                     :key="catalog.id">

                  <div class="flex items-center gap-3 flex-1">
                    <Checkbox v-model="checked_catalogs" :value="catalog.id"/>
                    <div v-if="edit_catalog !== catalog.id"
                         class="flex-1"
                         @click="handleEditCatalog(catalog.id, catalog.name)">
                      <span class="text-sm">{{ catalog.name }}</span>
                    </div>
                    <InputText v-else
                               v-model="edit_catalog_name"
                               size="small"
                               class="flex-1 w-1/2"
                               @keyup.enter="handleSaveEditCatalog"
                               @keyup.escape="cancelEditCatalog"/>
                  </div>

                  <!-- 目录操作按钮 -->
                  <div class="catalog-actions flex items-center gap-0 opacity-0 group-hover:opacity-100 transition-opacity">
                    <template v-if="edit_catalog !== catalog.id">
                      <Button icon="pi pi-pencil"
                              text
                              size="small"
                              class="p-0"
                              severity="secondary"
                              v-tooltip.top="'编辑目录'"
                              @click="handleEditCatalog(catalog.id, catalog.name)"/>
                      <Button icon="pi pi-trash"
                              text
                              size="small"
                              severity="danger"
                              v-tooltip.top="'删除目录'"
                              @click="confirmDeleteCatalog($event, catalog.id, catalog.name)"/>
                    </template>
                    <template v-else>
                      <Button icon="pi pi-check"
                              text
                              size="small"
                              severity="success"
                              v-tooltip.top="'保存'"
                              @click="handleSaveEditCatalog"/>
                      <Button icon="pi pi-times"
                              text
                              size="small"
                              severity="secondary"
                              v-tooltip.top="'取消'"
                              @click="cancelEditCatalog"/>
                    </template>
                  </div>
                </div>
              </template>
            </draggable>
          </div>
        </div>

        <!-- 空状态 -->
        <div v-if="unref(filter_spaces).length === 0" class="text-center py-8">
          <i class="pi pi-folder-open text-4xl text-gray-400 mb-4 block"></i>
          <p class="text-gray-500">暂无空间或目录</p>
          <p class="text-gray-400 text-sm mt-2">创建新的空间来组织您的内容</p>
        </div>
      </div>
    </div>

    <div class="flex flex-col gap-3 border-t p-2 border-surface">
      <Button icon="pi pi-plus"
              label="添加空间"
              class="w-full"
              severity="primary"
              variant="outlined"
              size="small"
              @click="show_create_space_popup = true"/>
      <Button icon="pi pi-plus"
              label="添加目录"
              class="w-full"
              severity="secondary"
              variant="outlined"
              size="small"
              :disabled="spaces.length === 0"
              @click="show_create_catalog_popup = true"/>
    </div>

    <!-- 弹出框 -->
    <AddSpace v-model:visible="show_create_space_popup"
              :type="type"
              @on-created="handleGetAllSpaces"/>
    <AddCatalog v-model:visible="show_create_catalog_popup"
                :spaces="unref(spaces)"
                @on-created="handleGetAllSpaces"/>

  </div>
</template>

<style scoped lang="scss">
.space-item {
  .space-actions {
    transition: opacity 0.2s ease;
  }
}

.catalog-item {
  .catalog-actions {
    transition: opacity 0.2s ease;
  }
}

// 确保悬停时显示操作按钮
.group:hover .space-actions,
.group:hover .catalog-actions {
  opacity: 1 !important;
}

// 拖拽相关样式
.catalog-item[draggable="true"] {
  transition: all 0.2s ease;
}

.catalog-item[draggable="true"]:hover {
  transform: scale(1.02);
}

.space-item {
  transition: all 0.3s ease;

  &.drag-over {
    background-color: rgba(59, 130, 246, 0.1);
    border: 2px dashed #3b82f6;
    transform: scale(1.02);
  }

  &.drag-inactive {
    opacity: 0.6;
  }
}

// 拖拽时的视觉提示
.catalog-item.dragging {
  opacity: 0.5;
  transform: rotate(2deg) scale(0.95);
  z-index: 1000;
}

// 拖拽放置区域高亮
.drop-zone-highlight {
  background: linear-gradient(45deg, rgba(59, 130, 246, 0.1), rgba(59, 130, 246, 0.2));
  border: 2px dashed #3b82f6;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

// Draggable样式
.ghost-catalog {
  opacity: 0.5;
  background: rgba(59, 130, 246, 0.1);
  border: 2px dashed #3b82f6;
  transform: rotate(1deg);
}

.chosen-catalog {
  opacity: 0.8;
  transform: scale(1.02);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.drag-catalog {
  opacity: 0.9;
  transform: rotate(-1deg) scale(1.05);
  z-index: 1000;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
}

// Space drag样式
.ghost-space {
  opacity: 0.5;
  background: rgba(34, 197, 94, 0.1);
  border: 2px dashed #22c55e;
  transform: rotate(0.5deg);
}

.chosen-space {
  opacity: 0.8;
  transform: scale(1.01);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.drag-space {
  opacity: 0.9;
  transform: rotate(-0.5deg) scale(1.02);
  z-index: 999;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}
</style>
