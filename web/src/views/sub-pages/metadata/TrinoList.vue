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
            <i class="pi pi-chart-bar text-violet-600"></i>
            Trino管理
          </h2>
          <p class="text-sm text-gray-600">分布式SQL查询引擎连接管理</p>
        </div>
      </div>
    </div>

    <!-- 内容区域 -->
    <div class="flex-1 flex items-center justify-center">
      <div class="text-center">
        <i class="pi pi-chart-bar text-6xl text-violet-400 mb-4 block"></i>
        <h3 class="text-xl font-semibold text-gray-700 mb-2">Trino管理功能开发中</h3>
        <p class="text-gray-500 mb-6">
          即将支持Trino查询引擎连接配置、catalog管理、查询测试等功能
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