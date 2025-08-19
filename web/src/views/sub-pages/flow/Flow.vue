<script setup lang="ts">
import { SpaceType } from "@/data/types/type";
import FlowList from "@/views/_tables/FlowList.vue";
import Catalog from "@/views/sub-pages/catalog/Catalog.vue";

const space_type = SpaceType.FLOW;
const checked_catalogs = ref<int[]>([])
</script>

<template>
  <div class="flex gap-4 h-full flex-1 w-full overflow-auto">
    <div class="w-64 h-full overflow-hidden border border-surface rounded-2xl flex flex-col">
      <catalog :type="space_type" @on-change="(catalogs: number[]) => checked_catalogs = catalogs"/>
    </div>
    <div class="flex-1 h-full overflow-hidden flex border border-surface rounded-2xl">
      <flow-list :catalogs="checked_catalogs" :catalog_config="catalog_config"/>
    </div>
  </div>
</template>


<style scoped lang="scss">

</style>
