<script setup lang="ts">
import { onMounted, ref, unref, watch } from "vue";
import { useVueFlow, VueFlow } from '@vue-flow/core'
import { Controls } from "@vue-flow/controls";
import { Background } from "@vue-flow/background";
import SpecialEdge from "@/components/SpecialEdge.vue";
import NodeSidebar from "@/nodes/view/NodesMenu.vue";
import CommonNode from "@/nodes/view/CommonNode.vue";
import useDragAndDrop from "@/nodes/useDnD.ts";
import { FtFlow, FtFlowVersion, Space, SpaceType } from "@/data/types/type";
import { ApiCreate, ApiList, ApiShow, ApiUpdate } from "@/api/base-api";
import { MiniMap } from "@vue-flow/minimap";
import { ApiGetFlowCurrentVersion } from "@/api/flow-api";
import { useToast } from "primevue/usetoast";
import FlowConfigSetting from "@/nodes/view/setting/FlowConfigSetting.vue";
import { useRoute } from "vue-router";
import CatalogSelector from "@/views/_selector/CatalogSelector.vue";

defineProps<{ spaces: Space[] }>()
const toast = useToast()
const { onInit, onNodeDragStop, onConnect, addEdges, setViewport, toObject, findNode, updateNode } = useVueFlow()
const { onDragOver, onDrop, onDragLeave, isDragOver } = useDragAndDrop()
const loading_flow = ref(false)
const loading_flow_version = ref(false)
const route = useRoute()
const flow = ref<FtFlow>({
  name: "新增流程",
  description: "新增流程",
  catalog_id: null,
})
const flow_version = ref<FtFlowVersion>({
  flow_config: {
    nodes: [],
    edges: [],
  }
})
const flow_id = ref<number>(null)
watch(() => route.query.id, (id) => {
  console.log('route params id changed', route)
  if (id) {
    flow_id.value = id as number
  } else {
    flow_id.value = null
  }
}, { immediate: true })
const is_changed_config = ref(false)

watch(() => flow_id.value, () => initFlowFormId(), { immediate: true })

function initFlowFormId() {
  if (flow_id.value) {
    loading_flow.value = true
    loading_flow_version.value = true
    ApiShow("ft_flow", flow_id.value).then((res) => {
      flow.value = res
    }).finally(() => {
      loading_flow.value = false
    })
    ApiGetFlowCurrentVersion(flow_id.value).then((res) => {
      flow_version.value = res
    }).finally(() => {
      loading_flow_version.value = false
    })
  }
}
function handleSaveFlow() {
  console.log(toObject())
  if (!flow_id.value) {
    // create flow
    ApiCreate("ft_flow", {
      ...flow.value,
      flow_config: flow_version.value.flow_config
    }).then((res) => {
      // router.replace({ name: "flow_edit", params: { id: res.id } })
      toast.add({ severity: 'success', summary: '保存流程成功', detail: '流程已保存', life: 3000 });
    }).catch((e) => {
      toast.add({ severity: 'error', summary: '保存流程失败', detail: e.msg });
    })
  } else {
    // update flow
    const params = { ...flow.value }
    if (is_changed_config) params.flow_config = flow_version.value.flow_config
    ApiUpdate("ft_flow", flow_id.value, params).then((res) => {
      toast.add({ severity: 'success', summary: '修改流程成功', detail: '流程已保存', life: 3000 });
    }).catch((e) => {
      toast.add({ severity: 'error', summary: '修改流程失败', detail: e.msg });
    })
  }
}

function handleSaveConfig() {
  try {
    flow_version.value.flow_config = toObject()
    toast.add({ severity: 'success', summary: '保存配置成功', detail: '流程配置已保存', life: 3000 });
  } catch (e) {
    toast.add({ severity: 'error', summary: '保存配置失败', detail: '请检查流程配置是否正确', life: 3000 });
  }
}

const visibleLeft = ref(false)

onConnect((connection) => {
  addEdges(connection)
})

const editing_node_id = ref<string | null>(null)
const editing_node_config = ref<any>({})

const setNodeConfig = (config) => {
  visibleLeft.value = true
  editing_node_id.value = unref(config.id)
  editing_node_config.value = { ...unref(config).data }
}

watch(() => visibleLeft.value, () => {
  if (!visibleLeft.value) {
    editing_node_id.value = null
    editing_node_config.value = {}
  }
})

function handleNodeConfigChange(newConfig) {
  updateNode(editing_node_id.value, {
    data: {
      ...editing_node_config.value,
      ...newConfig
    }
  })
  toast.add({
    severity: 'success',
    summary: `'${editing_node_config.value.label}' 节点配置已保存`,
    life: 3000
  });
}

</script>
<template>
  <div class="w-full h-full overflow-hidden border border-surface rounded-2xl flex flex-col">
    <div class="flex items-center justify-between gap-2 p-4 border-b border-surface">
      <div class="flex items-center gap-4" :loading="loading_flow">
        <FloatLabel variant="on">
          <InputText v-model="flow.name" placeholder="Enter flow name" class="w-64" size="small"/>
          <label>流程名</label>
        </FloatLabel>
        <FloatLabel variant="on">
          <InputText v-model="flow.name" placeholder="Enter flow description" class="w-90" size="small"/>
          <label>描述</label>
        </FloatLabel>
        <catalog-selector v-model="flow.catalog_id" :type="SpaceType.FLOW" />
      </div>
      <div class="inline-flex gap-2">
        <Button icon="pi pi-save" label="保存" size="small" @click="handleSaveFlow"/>
        <Button icon="pi pi-save" label="保存配置" size="small" @click="handleSaveConfig"/>
        <Button icon="pi pi-save" label="发布" size="small" @click="handleSaveFlow"/>
      </div>
    </div>
    <div class="flex-1 h-full overflow-hidden flex flex-col">
      <div class="flex  items-center justify-between px-4 m-0 border-b border-surface h-14">
        <node-sidebar class="w-1/2 h-14 border-0"></node-sidebar>
        <div class="inline-flex gap-2">
          <Button icon="pi pi-plus" label="导入JSON" size="small" @click="visibleLeft = true"/>
          <Button icon="pi pi-plus" label="导出JSON" size="small" @click="handleSaveConfig"/>
        </div>
      </div>

      <div class="flex-1 h-full w-full" @drop="onDrop" :loading="loading_flow_version">
        <VueFlow :nodes="flow_version.flow_config.nodes" :edges="flow_version.flow_config.edges" @dragover="onDragOver"
                 @dragleave="onDragLeave">
          <!-- bind your custom node type to a component by using slots, slot names are always `node-<type>` -->
          <Background pattern-color="#aaa" :gap="8"/>
          <MiniMap/>

          <Controls/>
          <template #node-common="specialNodeProps">
            <CommonNode v-bind="specialNodeProps" @dblclick="setNodeConfig(specialNodeProps)"/>
          </template>
          <!-- bind your custom edge type to a component by using slots, slot names are always `edge-<type>` -->
          <template #edge-special="specialEdgeProps">
            <SpecialEdge v-bind="specialEdgeProps"/>
          </template>
        </VueFlow>
      </div>
    </div>
    <flow-config-setting v-model:visible="visibleLeft" :config="editing_node_config" @save="handleNodeConfigChange"/>
  </div>

</template>
