<script setup lang="ts">

import SettingLayout from "@/nodes/view/setting/SettingLayout.vue";
import SettingColumn from "@/nodes/view/setting/SettingColumn.vue";
import { watch,unref } from "vue";

const props = defineProps<{
  visible?: boolean
  config?: any
}>()
const localVisible = ref(props.visible)
const params = ref([])
const emit = defineEmits(['update:visible', 'save'])
watch(() => props.visible, (val) => localVisible.value = val)
watch(localVisible, (val) => emit('update:visible', val))

watch(() => props.config, (val) => {
  if (val) params.value = JSON.parse(JSON.stringify(val.params ?? []))
}, { immediate: true })



const types = ref([
  { label: 'String', code: 'string' },
  { label: 'Int', code: 'int' },
  { label: 'Float', code: 'float' },
  { label: 'Boolean', code: 'boolean' },
  { label: 'Datetime', code: 'datetime' },
  { label: 'Date', code: 'date' },
])
const addParam = () => {
  params.value.push({
    key: `参数${params.value.length + 1}`,
    type: 'string',
  })
}
</script>

<template>
  <SettingLayout v-model:visible="localVisible">
    <template #header>
      <h1 class="text-lg font-semibold">参数设置</h1>
    </template>
    <SettingColumn title="参数设置" class="w-full">
      <template v-slot:actions>
        <Button type="primary" size="small" @click="addParam">添加参数</Button>
      </template>
      <div class="form-item" v-for="(param, index) in params" :key="index">
        <div class="flex items-center gap-2 mb-2">
          <FloatLabel class="w-full md:w-40" variant="on">
            <InputText v-model="param.key" size="small" class="w-full"/>
            <label for="over_label">参数名</label>
          </FloatLabel>

          <FloatLabel class="w-full md:w-56" variant="on">
            <Select v-model="param.type" :options="types" optionLabel="label" option-value="code" fluid size="small"/>
            <label for="over_label">参数类型</label>
          </FloatLabel>
          <Button severity="danger" aria-label="Cancel" icon="pi pi-trash" @click="params.splice(index, 1)" size="small"/>
        </div>
      </div>
    </SettingColumn>
    <template #footer>
      <Button @click="$emit('save', {params: JSON.parse(JSON.stringify(params))})" type="primary">保存设置</Button>
      <Button @click="localVisible = false">关闭</Button>
    </template>
  </SettingLayout>
</template>

<style scoped>

</style>
