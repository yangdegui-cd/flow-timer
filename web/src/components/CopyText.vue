<script setup lang="ts">
import clipboard from "@/utils/clipboard";
import { useToast } from "primevue/usetoast";

const toast = useToast();
const props = defineProps<{
  text: string
}>()

const copy = () => {
  clipboard(props.text, toast);
}
</script>

<template>
  <div class="flex justify-items-start items-center gap-2">
    <slot></slot>
    <i class="pi pi-clipboard text-blue-700" v-tooltip.top="'点击复制'" @click="() => clipboard(text, toast)"></i>
  </div>
</template>

<style scoped>

</style>
