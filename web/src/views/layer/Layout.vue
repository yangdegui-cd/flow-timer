<script setup lang="ts">

import Sider from "./Sider.vue";
</script>

<template>
<!--<div class="bg-surface-0 border border-black/10 dark:border-white/20 dark:bg-surface-950 w-full h-[100vh]  p-3 hidden lg:flex items-start gap-6 overflow-hidden">-->
<div class="border border-black/10 dark:border-white/20 w-full h-[100vh]  p-3 hidden lg:flex items-start gap-4 overflow-hidden">
  <sider></sider>
  <router-view></router-view>
</div>
</template>

<style scoped>
@import "../../styles/layout.scss";
</style>
