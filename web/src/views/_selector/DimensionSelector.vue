<script setup lang="ts">
import { watch } from "vue";
import { useMetricsStore } from "@/stores/metrics";

const props = defineProps<{
  modelValue: number[] | number | null,
  multiple?: boolean,
  label?: string,
  disabled?: boolean,
  selectClass?: string,
  size?: string
}>()
const duplicate_value = ref<number[] | number | null>(null)
const emit = defineEmits(["update:modelValue"])

const onMultiSelectChange = (value: string[]) => {
  const time_dim = []
  const other_dims = []
  value.forEach((dim) => {
    if (getDimCategory(dim) === 'time') {
      time_dim[0] = dim
    } else {
      other_dims.push(dim)
    }
  })
  duplicate_value.value = [...time_dim, ...other_dims];
}

const onMultiSelectAllChange = (value) => {
  console.log(value)
  duplicate_value.value = [...time_dim, ...other_dims];
}

watch(() => props.modelValue, (value) => duplicate_value.value = value, { immediate: true })
watch(duplicate_value, (value) => {
  emit("update:modelValue", value)
})
const metricsStore =  useMetricsStore()
const { dimensions, loading } = storeToRefs(metricsStore)
const { getDimCategory } = metricsStore

</script>

<template>

  <MultiSelect v-model="duplicate_value"
               :options="dimensions"
               v-if="multiple"
               option-value="name"
               option-label="display_name"
               option-group-children="dimensions"
               option-group-label="category"
               scroll-height="30rem"
               filter
               :size="size"
               @value-change="onMultiSelectChange"
               :disabled="disabled"
               :loading="loading">
    <template #option="slotProps">
      <div class="flex items-center gap-2">
        <div
            class="w-3 h-3 rounded-full flex-shrink-0"
            :style="{ backgroundColor: slotProps.option.color }"
        ></div>
        <span>{{ slotProps.option.display_name }}</span>
      </div>
    </template>
  </MultiSelect>
  <Select v-model="duplicate_value"
          :options="dimensions"
          v-else
          option-value="name"
          option-label="display_name"
          option-group-children="dimensions"
          option-group-label="category"
          scroll-height="30rem"
          filter
          :size="size"
          :disabled="disabled"
          :loading="loading">
    <template #option="slotProps">
      <div class="flex items-center gap-2">
        <div
            class="w-3 h-3 rounded-full flex-shrink-0"
            :style="{ backgroundColor: slotProps.option.color }"
        ></div>
        <span>{{ slotProps.option.display_name }}</span>
      </div>
    </template>
  </Select>
</template>
<style scoped>

</style>
