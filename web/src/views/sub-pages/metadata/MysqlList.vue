<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <div class="h-full flex flex-col">
    <!-- 页面头部 -->
    <div class="flex items-center justify-between p-4 border-b border-surface bg-gray-50">
      <div class="flex items-center gap-3">
        <Button 
          icon="pi pi-arrow-left" 
          text 
          severity="secondary"
          size="small"
          @click="router.push('/metadata')" 
          v-tooltip.top="'返回元数据管理'" />
        
        <div>
          <h2 class="text-xl font-semibold text-gray-800 flex items-center gap-2">
            <i class="pi pi-database text-amber-600"></i>
            MySQL管理
          </h2>
          <p class="text-sm text-gray-600">MySQL数据库连接配置管理</p>
        </div>
      </div>
    </div>

    <!-- 内容区域 -->
    <div class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <i class="pi pi-database text-6xl text-amber-400 mb-4 block"></i>
        <h3 class="text-xl font-semibold text-gray-700 mb-2">MySQL管理功能开发中</h3>
        <p class="text-gray-500 mb-6">
          即将支持MySQL数据库连接配置、连接测试、连接池管理等功能
        </p>
        <div class="flex gap-3 justify-center">
          <Button 
            label="返回上级" 
            icon="pi pi-arrow-left" 
            severity="secondary"
            @click="router.push('/metadata')" />
        </div>
      </div>
    </div>
  </div>
</template>