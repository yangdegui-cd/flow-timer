<script setup lang="ts">
import { watch } from "vue";
import { Space } from "@/data/types/type";
import { useToast } from "primevue/usetoast";
import { ApiCreate } from "@/api/base-api";

const toast = useToast();
const props = defineProps<{
  visible: boolean,
  spaces: Space[]
}>()
const emit = defineEmits(["update:visible", "onCreated"])
const _visible = ref(props.visible);
watch(() => props.visible, (val) => _visible.value = val, { immediate: true })
watch(_visible, (val) => emit("update:visible", _visible))

const catalog = ref<Space>({
  name: "",
  space_id: 0,
  sort: 0,
});

const initCatalog = () => {
  catalog.value.name = "";
  catalog.value.space_id = 0;
  catalog.value.sort = 0;
}

watch(() => props.visible, () => {
  if (props.visible) {
    initCatalog();
  }
}, { immediate: true })

const save = () => {
  if (catalog.value.name.trim() === "") {
    toast.add({ severity: 'error', summary: 'Catalog name is required', life: 3000 });
    return;
  } else if (props.spaces.map(s => s.id).indexOf(catalog.value.space_id) < 0) {
    toast.add({ severity: 'error', summary: 'Space is required', life: 3000 });
    return;
  } else {
    ApiCreate("catalog", catalog.value).then(() => {
      toast.add({ severity: 'success', summary: 'Create catalog success', life: 3000 });
      emit("onCreated", catalog.value);
      close();
    }).catch((error) => {
      toast.add({ severity: 'error', summary: 'Create catalog failed', detail: error.message, life: 3000 });
      close();
    });
  }
}

const close = () => {
  initCatalog();
  _visible.value = false;
}

</script>

<template>
  <Dialog v-model:visible="_visible" modal header="Add Catalog" :style="{ width: '25rem' }" :closable="close"
          :dismissable-mask="true">
    <span class="text-surface-500 dark:text-surface-400 block mb-8">Set catalog information.</span>
    <div class="flex items-center gap-4 mb-4">
      <label for="name" class="font-semibold w-12">name</label>
      <InputText id="name" class="flex-auto" autocomplete="off" v-model="catalog.name" size="small"/>
    </div>
    <div class="flex items-center gap-4 mb-8">
      <label for="sort" class="font-semibold w-12">order</label>
      <InputNumber id="sort" class="flex-auto" autocomplete="off" v-model="catalog.sort" size="small"/>
    </div>
    <div class="flex items-center gap-4 mb-8">
      <label for="space" class="font-semibold w-12">space</label>
      <Select id="space" class="flex-auto" v-model="catalog.space_id" :options="spaces" option-value="id"
              option-label="name" size="small"/>
    </div>
    <div class="flex justify-end gap-2">
      <Button type="button" label="Cancel" severity="secondary" @click="close"></Button>
      <Button type="button" label="Save" @click="save"></Button>
    </div>
  </Dialog>
</template>

<style scoped>

</style>
