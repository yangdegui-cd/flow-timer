<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from "vue-router";

// Props
interface Props {
  title: string
  description?: string
  icon?: string
  iconColor?: string
  showBack?: boolean
  backLabel?: string
  size?: 'small' | 'medium' | 'large'
}

const router = useRouter()
const route = useRoute()

const props = withDefaults(defineProps<Props>(), {
  description: '',
  icon: '',
  iconColor: 'text-primary-600',
  showBack: false,
  backLabel: '返回',
  size: 'medium'
})

// Emits
const emit = defineEmits<{
  'back': []
}>()

// Computed
const titleSize = computed(() => {
  switch (props.size) {
    case 'small': return 'text-lg'
    case 'large': return 'text-3xl'
    default: return 'text-2xl'
  }
})

const iconSize = computed(() => {
  switch (props.size) {
    case 'small': return 'text-base'
    case 'large': return 'text-2xl'
    default: return 'text-xl'
  }
})

// Methods
const handleBack = () => {
  router.back()
}
</script>

<template>
  <div class="h-full w-full flex flex-col">
    <div class="bg-white border-b border-surface p-6">
      <div class="flex items-center justify-between">
        <!-- 左侧标题区域 -->
        <div class="flex items-center gap-3">
          <!-- 返回按钮 -->
          <Button
              v-if="showBack"
              icon="pi pi-arrow-left"
              text
              severity="secondary"
              size="small"
              :aria-label="backLabel"
              v-tooltip.bottom="backLabel"
              @click="handleBack"
          />

          <!-- 标题和描述 -->
          <div>
            <h1 :class="['font-bold text-gray-900 flex items-center gap-3', titleSize]">
              <i v-if="icon" :class="[icon, iconColor, iconSize]"></i>
              {{ title }}
            </h1>
            <p v-if="description" class="text-gray-600 mt-1 text-sm">
              {{ description }}
            </p>
          </div>
        </div>

        <!-- 右侧操作区域 -->
        <div class="flex items-center gap-3">
          <slot name="actions" />
        </div>
      </div>
    </div>
    <div class="h-full overflow-auto">
      <slot />
    </div>
  </div>

</template>

<style scoped>
/* 页面头部样式 */
</style>
