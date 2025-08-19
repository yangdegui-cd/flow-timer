<script setup lang="ts">
defineProps<{
  visible?: boolean
}>()
</script>
<template>
  <div class="ga-node-setting-layout" :class="{ 'visible': visible }">
    <div class="ga-node-setting-layout_header">
      <slot name="header">
        <h1>节点设置</h1>
      </slot>
    </div>
    <div class="ga-node-setting-layout_content">
      <slot/>
    </div>
    <div class="ga-node-setting-layout_footer flex justify-end gap-2">
      <slot name="footer">
      </slot>
    </div>
  </div>
</template>

<style scoped>
@import "@/styles/node-setting.scss";
</style>
