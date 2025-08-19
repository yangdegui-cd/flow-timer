<script setup lang="ts">
import { changePrimaryColor } from "@/utils/changePrimaryColor";

onMounted(() => changePrimaryColor("indigo"));
</script>

<template>
  <router-view></router-view>
  <Toast />
  <ConfirmDialog></ConfirmDialog>
</template>

<style>
</style>
