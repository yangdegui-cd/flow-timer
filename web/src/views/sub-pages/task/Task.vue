<script setup lang="ts">
import { SpaceType } from "@/data/types/type";
import TaskList from "@/views/_tables/TaskList.vue";
import Catalog from "@/views/sub-pages/catalog/Catalog.vue";


const space_type = SpaceType.TASK;
const checked_catalogs = ref<number[]>([]);
</script>

<template>
  <div class="flex gap-4 h-full flex-1 w-full overflow-auto">
    <div class="w-64 h-full overflow-hidden border border-surface rounded-2xl flex flex-col">
      <catalog :type="space_type" @on-change="(catalogs: number[]) => checked_catalogs = catalogs"></catalog>
    </div>
    <div class="flex-1 h-full overflow-hidden flex border border-surface rounded-2xl">
      <task-list :catalogs="checked_catalogs"/>
    </div>
  </div>
</template>


<style scoped lang="scss">
.catalog {
  .action {
    display: none;
  }
  &:hover {
    .action {
      display: flex;
    }
  }
}
</style>
