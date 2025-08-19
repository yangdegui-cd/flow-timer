<script setup lang="ts">
import ParamsSetting from "@/nodes/view/setting/ParamsSetting.vue";
import FtpTransferSetting from "@/nodes/view/setting/FtpTransferSetting.vue";
import { computed } from "vue";
import ExecuteSqlSetting from "@/nodes/view/setting/ExecuteSqlSetting.vue";

const props = defineProps<{
  visible: boolean,
  config: any,
}>()
const localVisible = ref(false)
const emit = defineEmits(['update:visible', 'save'])
const type = computed(() => props.config?.node_type ?? '')
const config = computed(() => props.config?.config ?? {})

watch(() => props.visible, (val) => localVisible.value = val, { immediate: true })
watch(localVisible, (val) => emit('update:visible', val))

function handleSave(config) {
  console.log('handleSave', config)
  emit('save', { config })
}

</script>

<template>
  <ParamsSetting v-model:visible="localVisible" :config="config" @save="handleSave" v-if="type==='flow_params'"/>
  <FtpTransferSetting v-model:visible="localVisible" :config="config" @save="handleSave" v-if="type==='ftp_transfer'"/>
  <ExecuteSqlSetting v-model:visible="localVisible" :config="config" @save="handleSave" v-if="type==='execute_sql'"/>
</template>

<style scoped>

</style>
