<template>
  <PageHeader
    title="自动化日志"
    description="查看和管理所有项目的自动化操作日志"
    icon="pi pi-history"
    icon-color="text-teal-600"
  />

  <div class="p-4">
    <!-- 日志内容 -->
    <AutomationLogsTab />
  </div>
</template>

<script setup lang="ts">
import PageHeader from '@/views/layer/PageHeader.vue'
import AutomationLogsTab from './AutomationLogsTab.vue'
</script>

<style scoped>
/* 页面样式 */
</style>
