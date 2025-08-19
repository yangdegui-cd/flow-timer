<script setup lang="ts">

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
