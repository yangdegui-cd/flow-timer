<script lang="ts" setup>
import { Space, SpaceType } from "@/data/types/type";
import { ApiList } from "@/api/base-api";
import { onMounted, watch } from "vue";

const props = defineProps<{
  modelValue: number | null,
  type: SpaceType,
  label?: string,
  disabled?: boolean,
  selectClass?: string
}>()


const duplicate_value = ref<number | null>(null)
const loading = ref(false)
const spaces = ref<Space[]>([])
const emit = defineEmits(["update:modelValue"])

function fetchSpaces() {
  loading.value = true
  ApiList("space", { type: props.type }).then((res) => {
    spaces.value = res
  }).finally(() => {
    loading.value = false
  })
}

onMounted(fetchSpaces)
watch(() => props.modelValue, (value) => duplicate_value.value = value, { immediate: true })
watch(duplicate_value, (value) => emit("update:modelValue", value))
</script>

<template>
  <FloatLabel variant="on">
    <Select v-model="duplicate_value"
            :options="spaces"
            option-value="id"
            option-label="name"
            option-group-label="name"
            option-group-children="catalogs"
            filter
            :disabled="disabled"
            :loading="loading"
            :class="selectClass"
            class="w-64"
            size="small">
      <template #option="slotProps">
        <div class="flex items-center pl-4">
          <div>{{ slotProps.option.name }}</div>
        </div>
      </template>
    </Select>
    <label>{{ label?? '所属目录'}}</label>
  </FloatLabel>
</template>
