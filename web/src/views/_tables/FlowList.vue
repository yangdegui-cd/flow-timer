<script setup lang="ts">
import { onMounted, Ref, watch } from "vue";
import { ApiList } from "@/api/base-api";
import { ApiGetFlowStatistics, ApiBatchUpdateFlowStatus, ApiBatchDeleteFlows } from "@/api/flow-api";
import { useRouter } from "vue-router";
import { SpaceType } from "@/data/types/type";
import clipboard from "@/utils/clipboard";
import { useToast } from "primevue/usetoast";
import { useConfirm } from 'primevue/useconfirm';

const router = useRouter()
const toast = useToast();
const confirm = useConfirm();
const props = defineProps<{ catalogs: Ref<int[]> }>()

watch(() => props.catalogs, () => {
  console.log("Catalogs changed:", props.catalogs)
  handleGetRows()
})

const loading_data = ref(false)
const filters = ref({
  global: {
    value: '',
    matchMode: 'contains'
  }
})

onMounted(() => {
  handleGetCatalogConfig()
  handleGetRows()
})

const rows = ref([])
const locked_rows = ref([])
const editing_rows = ref([])
const selected_rows = ref([])
const name_popover = ref();
const params_popover = ref();
const version_popover = ref();
// 鼠标点击查看行
const view_row = ref(null);
const catalog_config = ref<Record<any, any>>({})

const displayPopover = (event, row, popover) => {
  unref(popover)?.hide()
  if (view_row.value?.id === row.id) {
    view_row.value = null;
  } else {
    view_row.value = row;
    nextTick(() => unref(popover)?.show(event));
  }
};

const hidePopover = (popover) => {
  unref(popover)?.hide()
  view_row.value = null;
}

const toggleLock = (data, frozen, index) => {
  if (frozen) {
    locked_rows.value = locked_rows.value.filter((c, i) => i !== index);
    rows.value.push(data);
  } else {
    rows.value = rows.value.filter((c, i) => i !== index);
    locked_rows.value.push(data);
  }
  rows.value.sort((val1, val2) => {
    return val1.id < val2.id ? -1 : 1;
  });
};

const handleGetRows = () => {
  loading_data.value = true
  ApiList("ft_flow", { catalog_id: props.catalogs }).then((res) => {
    rows.value = res
  }).catch((error) => {
    console.error("Failed to fetch flows:", error)
    toast.add({ severity: 'error', summary: '加载失败', detail: error.msg || '获取流程列表失败', life: 3000 });
  }).finally(() => {
    loading_data.value = false
  })
}

const handleGetCatalogConfig = () => {
  ApiList("space", { type: "FLOW" }).then((res) => {
    catalog_config.value = res.reduce((acc, item) => {
      item.catalogs.forEach((catalog) => {
        acc[catalog.id] = {
          space_name: item.name,
          catalog_name: catalog.name,
          space_id: item.id,
          catalog_id: catalog.id
        };
      });
      return acc;
    }, {});
  }).catch((error) => {
    console.error("Failed to fetch catalog config:", error)
  });
}

// 批量删除流程
const batchDeleteFlows = () => {
  if (selected_rows.value.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请先选择要删除的流程', life: 3000 });
    return;
  }

  confirm.require({
    message: `确定要删除选中的 ${selected_rows.value.length} 个流程吗？`,
    header: '批量删除确认',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => {
      const flowIds = selected_rows.value.map(flow => flow.id);
      ApiBatchDeleteFlows(flowIds).then(() => {
        toast.add({
          severity: 'success',
          summary: '删除成功',
          detail: `已删除 ${selected_rows.value.length} 个流程`,
          life: 3000
        });
        selected_rows.value = [];
        handleGetRows();
      }).catch((error) => {
        toast.add({
          severity: 'error',
          summary: '删除失败',
          detail: error.msg || '删除流程失败',
          life: 3000
        });
      });
    }
  });
}

// 批量更新状态
const batchUpdateStatus = (status: string) => {
  if (selected_rows.value.length === 0) {
    toast.add({ severity: 'warn', summary: '提示', detail: '请先选择要更新的流程', life: 3000 });
    return;
  }

  const flowIds = selected_rows.value.map(flow => flow.id);
  const statusLabels = {
    'active': '激活',
    'inactive': '停用',
    'draft': '草稿'
  };

  ApiBatchUpdateFlowStatus(flowIds, status).then(() => {
    toast.add({
      severity: 'success',
      summary: '状态更新成功',
      detail: `已将 ${selected_rows.value.length} 个流程设为${statusLabels[status]}`,
      life: 3000
    });
    selected_rows.value = [];
    handleGetRows();
  }).catch((error) => {
    toast.add({
      severity: 'error',
      summary: '状态更新失败',
      detail: error.msg || '更新流程状态失败',
      life: 3000
    });
  });
}

// 获取流程状态显示样式
const getStatusSeverity = (status: string) => {
  switch (status) {
    case 'active': return 'success';
    case 'inactive': return 'warning';
    case 'draft': return 'info';
    case 'error': return 'danger';
    default: return 'secondary';
  }
}

// 格式化时间显示
const formatDateTime = (dateString: string) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleString('zh-CN');
}

</script>

<template>
  <DataTable :value="rows"
             :frozenValue="locked_rows"
             v-model:editing-rows="editing_rows"
             v-model:selection="selected_rows"
             :loading="loading_data"
             :globalFilterFields="['name', 'description', 'status']"
             :filters="filters"
             tableStyle="min-width: 50rem; padding: 10px"
             class="w-full h-full"
             edit-mode="row"
             data-key="id"
             paginator
             :rows="20"
             size="small"
             scrollable
             scrollHeight="calc(100% - 200px)"
             sortMode="multiple"
             rowGroupMode="subheader"
             groupRowsBy="catalog_id"
             :rowsPerPageOptions="[5, 10, 20, 50]"
             paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
             currentPageReportTemplate="{first} to {last} of {totalRecords}"
             :pt="{
                table: { style: 'min-width: 50rem' },
                bodyrow: ({ props }) => ({
                    class: [{ 'font-bold bg-gray-100': props.frozenRow }]
                }),
                rowGroupHeader: [{ 'hidden': props.frozenRow }],
                header: { style: 'border-bottom: 1px solid var(--surface-border)' },
            }">
    <template #header>
      <div class="flex xl:items-center justify-between gap-2 flex-col xl:flex-row">
        <div class="flex items-center gap-2">
          <Button icon="pi pi-check"
                  aria-label="batch activate"
                  variant="outlined"
                  label="批量激活"
                  size="small"
                  :disabled="selected_rows.length === 0"
                  @click="batchUpdateStatus('active')"/>
          <Button icon="pi pi-pause"
                  aria-label="batch deactivate"
                  variant="outlined"
                  label="批量停用"
                  size="small"
                  :disabled="selected_rows.length === 0"
                  @click="batchUpdateStatus('inactive')"/>
          <Button icon="pi pi-refresh"
                  aria-label="refresh"
                  variant="outlined"
                  label="刷新"
                  size="small"
                  @click="handleGetRows"/>
          <Button icon="pi pi-trash"
                  aria-label="delete"
                  severity="danger"
                  variant="outlined"
                  label="删除"
                  :disabled="selected_rows.length === 0"
                  @click="batchDeleteFlows"
                  size="small"/>
          <Button icon="pi pi-plus"
                  aria-label="add"
                  label="新增流程"
                  size="small"
                  @click="router.push('/flows/add')"/>
        </div>
        <div class="flex items-center gap-2">
          <FloatLabel variant="on">
            <IconField>
              <InputIcon class="pi pi-search"/>
              <InputText id="flow_search" v-model="filters['global'].value" autocomplete="on" size="small"/>
            </IconField>
            <label for="flow_search">搜索流程</label>
          </FloatLabel>
          <Button icon="pi pi-filter" aria-label="filter" severity="secondary" variant="outlined" size="small"/>
        </div>
      </div>
    </template>
    <template #empty>
      <div class="text-center py-4">
        <i class="pi pi-sitemap text-4xl text-gray-400 mb-4 block"></i>
        <p class="text-gray-500">暂无流程数据</p>
      </div>
    </template>
    <template #loading>
      <div class="text-center py-4">
        <i class="pi pi-spin pi-spinner text-2xl text-blue-500 mb-2 block"></i>
        <p>加载流程数据中...</p>
      </div>
    </template>
    <template #groupheader="{data, frozenRow}">
      <div class="flex items-center gap-2" v-if="!frozenRow">
        <Tag class="font-bold px-5 py-2">
          <i class="pi pi-folder text-sm mr-1"></i>
          {{ catalog_config[data.catalog_id]?.space_name }} /
          {{ catalog_config[data.catalog_id]?.catalog_name }}
        </Tag>
      </div>
    </template>

    <Column selectionMode="multiple" headerStyle="width: 3rem"></Column>

    <Column field="name" sortable header="流程名称">
      <template #body="{ data }">
        <span @click="displayPopover($event, data, name_popover)"
              v-tooltip.top="'点击查看详情'"
              class="cursor-pointer text-blue-700 hover:text-blue-500 hover:underline">
          {{ data.name }}
        </span>
      </template>
    </Column>

    <Column field="status" sortable header="状态">
      <template #body="{ data }">
        <Tag :value="data.status"
             :severity="getStatusSeverity(data.status)"
             class="text-xs">
          {{ data.status === 'active' ? '运行中' :
               data.status === 'inactive' ? '已停用' :
               data.status === 'draft' ? '草稿' :
               data.status === 'error' ? '错误' : data.status }}
        </Tag>
      </template>
    </Column>

    <Column field="created_at" sortable header="创建时间">
      <template #body="{ data }">
        <span class="text-sm">{{ formatDateTime(data.created_at) }}</span>
      </template>
    </Column>

    <Column field="params" header="参数">
      <template #body="{ data }">
        <span @mouseenter="displayPopover($event, data, params_popover)"
              @mouseleave="hidePopover(params_popover)"
              v-tooltip.top="'查看参数配置'"
              class="cursor-pointer text-blue-500 hover:text-blue-700 text-sm">
          {{ (data.params && data.params.length) || 0 }} 个参数
        </span>
      </template>
    </Column>

    <Column field="ft_flow_version.version" header="版本">
      <template #body="{ data }">
        <span @click="displayPopover($event, data, version_popover)"
              v-tooltip.top="'点击查看版本详情'"
              class="cursor-pointer text-indigo-600 hover:text-indigo-800 font-mono text-sm bg-indigo-100 px-2 py-1 rounded">
          v{{ data.ft_flow_version?.version || 1 }}
        </span>
      </template>
    </Column>

    <Column field="task_count" sortable header="任务数">
      <template #body="{ data }">
        <div class="flex items-center gap-1">
          <i class="pi pi-list text-xs text-orange-500"></i>
          <span class="text-sm">{{ data.task_count || 0 }}</span>
        </div>
      </template>
    </Column>

    <Column field="actions" header="操作" headerClass="flex justify-center" bodyClass="text-center">
      <template #body="{ data, frozenRow, index }">
        <div class="inline-flex gap-1 items-center justify-center">
          <Button icon="pi pi-play"
                  text
                  severity="success"
                  v-tooltip.top="'运行流程'"
                  size="small"/>
          <Button icon="pi pi-pencil"
                  text
                  severity="secondary"
                  v-tooltip.top="'编辑流程'"
                  @click="$router.push({path: '/flows/edit', query: { id: data.id } })"
                  size="small"/>
          <Button icon="pi pi-plus-circle"
                  text
                  severity="info"
                  v-tooltip.top="'添加任务'"
                  @click="$router.push({path: '/task/add', query: { flow_id: data.flow_id } })"
                  size="small"/>
          <Button icon="pi pi-list"
                  text
                  severity="secondary"
                  v-tooltip.top="'查看任务'"
                  @click="$router.push({path: '/tasks', query: { flow_id: data.flow_id } })"
                  size="small"/>
          <Button type="button"
                  :icon="frozenRow ? 'pi pi-lock-open' : 'pi pi-lock'"
                  :disabled="frozenRow ? false : locked_rows.length >= 3"
                  text
                  severity="secondary"
                  v-tooltip.top="frozenRow ? '解锁行' : '锁定行'"
                  size="small"
                  @click="toggleLock(data, frozenRow, index)"/>
        </div>
      </template>
    </Column>
  </DataTable>

  <!-- 流程详情弹窗 -->
  <Popover ref="name_popover">
    <div class="flex flex-col gap-3 p-4 min-w-80">
      <div class="border-b pb-2 mb-2">
        <h3 class="font-bold text-lg">{{ view_row?.name }}</h3>
        <p class="text-sm text-gray-600">{{ view_row?.description }}</p>
      </div>

      <div class="grid grid-cols-2 gap-2 text-sm">
        <div class="flex items-center gap-2">
          <span class="font-semibold">流程ID:</span>
          <span class="font-mono bg-gray-100 px-2 py-1 rounded text-xs">{{ view_row?.flow_id }}</span>
          <Button icon="pi pi-copy" text size="small"
                  @click="clipboard(view_row?.flow_id, toast)"/>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">状态:</span>
          <Tag :value="view_row?.status"
               :severity="getStatusSeverity(view_row?.status)"
               class="text-xs"/>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">版本:</span>
          <span class="font-mono bg-indigo-100 px-2 py-1 rounded text-xs">v{{ view_row?.ft_flow_version?.version || 1 }}</span>
        </div>

        <div class="flex items-center gap-2">
          <span class="font-semibold">任务数:</span>
          <span>{{ view_row?.task_count || 0 }} 个</span>
        </div>

        <div class="col-span-2 flex items-center gap-2">
          <span class="font-semibold">创建时间:</span>
          <span>{{ formatDateTime(view_row?.created_at) }}</span>
        </div>

        <div class="col-span-2 flex items-center gap-2">
          <span class="font-semibold">更新时间:</span>
          <span>{{ formatDateTime(view_row?.updated_at) }}</span>
        </div>
      </div>
    </div>
  </Popover>

  <!-- 参数详情弹窗 -->
  <Popover ref="params_popover" class="w-auto">
    <div class="flex flex-col gap-2 p-3">
      <h4 class="font-bold mb-2">流程参数</h4>
      <div class="flex items-center justify-between gap-4"
           v-for="param in view_row?.params" :key="param.key">
        <span class="font-semibold text-sm">{{ param.key }}:</span>
        <span class="text-sm bg-gray-100 px-2 py-1 rounded">{{ param.type }}</span>
      </div>
      <div v-if="!view_row?.params || view_row?.params.length === 0"
           class="text-gray-500 text-center py-2">
        <i class="pi pi-info-circle mr-2"></i>
        <span>暂无参数配置</span>
      </div>
    </div>
  </Popover>

  <!-- 版本详情弹窗 -->
  <Popover ref="version_popover">
    <div class="flex flex-col gap-2 p-3">
      <h4 class="font-bold mb-2">版本详情</h4>
      <div class="text-sm space-y-1">
        <div><strong>当前版本:</strong> v{{ view_row?.ft_flow_version?.version || 1 }}</div>
        <div><strong>版本创建时间:</strong> {{ formatDateTime(view_row?.ft_flow_version?.created_at) }}</div>
        <div><strong>流程创建时间:</strong> {{ formatDateTime(view_row?.created_at) }}</div>
        <div><strong>最后更新:</strong> {{ formatDateTime(view_row?.updated_at) }}</div>
      </div>
    </div>
  </Popover>
</template>

<style scoped>

</style>
