<script setup lang="ts">
import { watch } from "vue";
import { AdsAccount } from "@/data/types/ads-types";
import { storeToRefs } from "pinia";
import Tag from "primevue/tag";
import { useCommonDataStore } from "@/stores/common-data";

const props = defineProps<{
  modelValue: number[] | number | null,
  options?: AdsAccount[],
  multiple?: boolean,
  disabled?: boolean,
}>()

const duplicate_value = ref<number[] | number | null>(null)
const emit = defineEmits(["update:modelValue"])

watch(() => props.modelValue, (value) => duplicate_value.value = value, { immediate: true })
watch(duplicate_value, (value) => emit("update:modelValue", value))

const commonStore = useCommonDataStore()
const { adsAccounts, loading } = storeToRefs(commonStore)

</script>

<template>

  <MultiSelect v-model="duplicate_value"
               :options="options ?? adsAccounts"
               v-if="multiple"
               display="chip"
               option-value="id"
               option-label="name"
               scroll-height="30rem"
               filter
               :disabled="disabled"
               :loading="loading">
    <template #option="{ option }">
      <div class="flex items-center gap-2">
        <Tag :value="option.ads_platform?.name || '未知平台'" severity="info"/>
        <span>{{ option.name }}</span>
        <span class="text-gray-500 text-sm">({{ option.account_id }})</span>
      </div>
    </template>
  </MultiSelect>
  <Select v-model="duplicate_value"
          :options="options ?? adsAccounts"
          v-else
          option-value="account_id"
          option-label="name"
          scroll-height="30rem"
          filter
          :disabled="disabled"
          :loading="loading">
    <template #option="{ option }">
      <div class="flex items-center gap-2">
        <Tag :value="option.ads_platform?.name || '未知平台'" severity="info"/>
        <span>{{ option.name }}</span>
        <span class="text-gray-500 text-sm">({{ option.account_id }})</span>
      </div>
    </template>
  </Select>
</template>
<style scoped>

</style>
