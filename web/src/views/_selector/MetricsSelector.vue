<script setup lang="ts">
import { SpaceType } from "@/data/types";
import { Metrics } from "@/data/types/ads-types";
import { useMetrics } from "@/data/composables/use-metrics";
import { watch } from "vue";

const props = defineProps<{
  modelValue: number[] | number | null,
  multiple?: boolean,
  type: SpaceType,
  label?: string,
  disabled?: boolean,
  selectClass?: string
}>()
const duplicate_value = ref<number[] | number | null>(null)
const metrics = ref<Metrics[]>([])
useMetrics(metrics)

watch(() => props.modelValue, (value) => duplicate_value.value = value, { immediate: true })
watch(duplicate_value, (value) => emit("update:modelValue", value))
</script>

<template>
  <FloatLabel variant="on">
    <Select v-model="duplicate_value"
            :options="metrics"
            :multiple="multiple"
            option-value="id"
            option-label="name"
            option-group-label="name"
            option-group-children="catalogs"
            filter
            :disabled="disabled"
            :loading="loading"
            :class="selectClass"
            class="w-full"
            size="small">
      <template #option="slotProps">
        <div class="flex items-center pl-4">
          <div>{{ slotProps.option.name }}</div>
        </div>
      </template>
    </Select>
    <label>{{ label?? "选择指标"}}</label>
  </FloatLabel>
</template>
<style scoped>

</style>
