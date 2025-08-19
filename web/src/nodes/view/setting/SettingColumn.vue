<script setup lang="ts">
defineProps<{
  title: string
  description?: string
}>()
</script>

<template>
  <div class="ga-node-setting_column">
    <div class="ga-node-setting_column_header">
      <div class="ga-node-setting_column_header_label">{{ title}}</div>
      <div class="ga-node-setting_column_header_actions">
        <slot name="actions"></slot>
      </div>
    </div>
    <div class="ga-node-setting_column_content">
      <slot></slot>
    </div>
  </div>
</template>

<style scoped>
@import "@/styles/node-setting.scss";
</style>
