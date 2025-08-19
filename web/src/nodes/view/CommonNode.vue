<script setup lang="ts">
import { Handle, type NodeProps, Position } from '@vue-flow/core'
import { computed } from "vue";
import nodes_setting from "@/nodes/nodes-setting";
import { NodeSetting } from "@/nodes/type";

const props = defineProps<NodeProps | {
  toolbar?: boolean;
}>();
const node_type = computed(() => props.data.node_type)
const node_config = computed(() => props.config)
const node_setting = computed<NodeSetting>(() => nodes_setting[unref(node_type)])

</script>

<template>
  <div :class="['custom-node', {active: selected, toolbar: toolbar}, node_setting.view.node_subtype]">
    <div class="custom-node-container">
      <!-- 左侧图标区域 -->
      <div class="custom-node-container_icon" v-if="node_setting">
        <ga-icon :icon="node_setting.view.icon"
                 :class="['db-icon',{'fa-beat-fade': selected}]"
                 :icon_type="node_setting.view.icon_type"/>
        <ga-icon icon="input" icon_type="custom"
                 :class="['input-icon', {'fa-beat-fade1': selected}]"
                 v-if="node_setting.view.node_subtype === 'input'"/>
        <ga-icon icon="output" icon_type="custom"
                 :class="['output-icon', {'fa-beat-fade1': selected}]"
                 v-if="node_setting.view.node_subtype === 'output'"/>
      </div>

      <!-- 右侧内容区域 -->
      <div class="custom-node-container_content">
        <div class="database-label">{{ data.label }}</div>
      </div>
    </div>
    <template v-if="!toolbar">
      <Handle type="target" :position="Position.Top" v-if="!node_setting?.view?.hide_target"/>
      <Handle type="source" :position="Position.Bottom" v-if="!node_setting?.view?.hide_source"/>
    </template>
  </div>
</template>


<style>
@import "../../styles/node.scss";
</style>
