<script setup lang="ts" name="ga-icon">
import icon_types from './ga-icon.ts'

defineProps({
  icon: {
    type: String,
    required: true,
  },
  icon_type: {
    type: String,
    default: "prime",
    required: false,
  },
  height: {
    type: String,
    default: "1em",
  },
  width: {
    type: String,
    default: "1em",
  },
  viewBox: {
    type: String,
    default: "0 0 1024 1024",
  },
  color: String
})
</script>

<template>
  <i v-if="icon_type === 'custom'">
    <svg viewBox="0 0 1024 1024">
      <template v-if="icon_types[icon]">
        <path :d="path" v-for="path in icon_types[icon]"></path>
      </template>
      <template v-else>
        <use :xlink:href="`#icon-${icon}`"></use>
      </template>
    </svg>
  </i>
  <i v-else :class="icon"/>
</template>


<style scoped>
svg {
  width: 1em;
  height: 1em;
  display: inline-block;
  vertical-align: middle;
  fill: currentColor;
  color: currentColor;
}
</style>
