<script setup lang="ts">
import { Space, SpaceType } from "@/data/types/type";
import { watch } from "vue";
import { ApiCreate } from "@/api/base-api";
import { useToast } from "primevue/usetoast";

const toast = useToast();
const resource = "space";
const props = defineProps<{
  visible: boolean,
  type: SpaceType
}>()
const _visible = ref(props.visible);
watch(() => props.visible, (val) => {
  _visible.value = val;
}, { immediate: true })
watch(_visible, (val) => {
  emit("update:visible", _visible);
})

const space = ref<Space>({
  name: "",
  space_type: props.type,
  sort: 0,
});

const initSpace = () => {
  space.value.name = "";
  space.value.space_type = props.type;
  space.value.sort = 0;
}

watch(() => props.visible, () => {
  if (props.visible) {
    initSpace();
  }
}, { immediate: true })

const emit = defineEmits(["update:visible", "onCreated"])

const save = () => {
  if (space.value.name.trim() === "") {
    toast.add({ severity: 'error', summary: 'Space name is required', life: 3000 });
    return;
  } else {
    ApiCreate(resource, space.value).then(() => {
      toast.add({ severity: 'success', summary: 'Create space success', life: 3000 });
      emit("onCreated", space.value);
      close()
    }).catch((error) => {
      toast.add({ severity: 'error', summary: 'Create space failed', detail: error.message, life: 3000 });
      close()
    });
  }
}

const close = () => {
  initSpace()
  _visible.value = false;
}
</script>

<template>
  <Dialog v-model:visible="_visible" modal header="Add Space" :style="{ width: '25rem' }" :closable="close" :dismissable-mask="true">
    <span class="text-surface-500 dark:text-surface-400 block mb-8">Set space information.</span>
    <div class="flex items-center gap-4 mb-4">
      <label for="name" class="font-semibold w-12">name</label>
      <InputText id="name" class="flex-auto" autocomplete="off" v-model="space.name"/>
    </div>
    <div class="flex items-center gap-4 mb-8">
      <label for="sort" class="font-semibold w-12">order</label>
      <InputNumber id="sort" class="flex-auto" autocomplete="off" v-model="space.sort"/>
    </div>
    <div class="flex justify-end gap-2">
      <Button type="button" label="Cancel" severity="secondary" @click="close"></Button>
      <Button type="button" label="Save" @click="save"></Button>
    </div>
  </Dialog>
</template>

<style scoped>

</style>
