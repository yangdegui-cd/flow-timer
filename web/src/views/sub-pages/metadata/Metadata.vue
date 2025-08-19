<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import PageHeader from '@/views/layer/PageHeader.vue'

const router = useRouter()

// 元数据类别配置
const metadataTypes = [
  {
    key: 'databases',
    title: 'SQL数据库源',
    description: '支持MySQL、Oracle、Hive等多种数据库',
    icon: 'pi pi-database',
    color: '#8b5cf6', // purple
    path: '/metadata/databases',
    stats: {
      total: 0,
      active: 0,
      error: 0
    }
  },
  {
    key: 'hosts',
    title: '主机管理',
    description: 'SSH连接和服务器资源管理',
    icon: 'pi pi-desktop',
    color: '#3b82f6', // blue
    path: '/metadata/hosts',
    stats: {
      total: 0,
      active: 0,
      error: 0
    }
  },
  {
    key: 'mysql',
    title: 'MySQL管理',
    description: 'MySQL数据库连接配置',
    icon: 'pi pi-database',
    color: '#f59e0b', // amber
    path: '/metadata/mysql',
    stats: {
      total: 0,
      active: 0,
      error: 0
    }
  },
  {
    key: 'trino',
    title: 'Trino管理',
    description: '分布式SQL查询引擎连接',
    icon: 'pi pi-chart-bar',
    color: '#8b5cf6', // violet
    path: '/metadata/trino',
    stats: {
      total: 0,
      active: 0,
      error: 0
    }
  },
  {
    key: 'hdfs',
    title: 'HDFS管理',
    description: 'Hadoop分布式文件系统连接',
    icon: 'pi pi-folder',
    color: '#10b981', // emerald
    path: '/metadata/hdfs',
    stats: {
      total: 0,
      active: 0,
      error: 0
    }
  }
]

// 加载统计数据
const loading = ref(false)

const loadStats = async () => {
  loading.value = true
  try {
    // 这里可以调用API获取每种类型的统计数据
    // 暂时使用模拟数据
    await new Promise(resolve => setTimeout(resolve, 500))

    // 模拟数据更新
    metadataTypes[0].stats = { total: 5, active: 4, error: 1 }
    metadataTypes[1].stats = { total: 8, active: 7, error: 1 }
    metadataTypes[2].stats = { total: 3, active: 3, error: 0 }
    metadataTypes[3].stats = { total: 2, active: 1, error: 1 }
  } finally {
    loading.value = false
  }
}

// 导航到具体类型页面
const navigateToType = (type: any) => {
  router.push(type.path)
}

// 页面加载时获取统计数据
loadStats()
</script>

<template>
  <div class="h-full flex flex-col bg-gray-50 w-full">
    <!-- 页面头部 -->
    <PageHeader
      title="元数据管理"
      description="统一管理各种数据源连接和配置信息"
      icon="pi pi-database"
      icon-color="text-blue-600"
    >
      <template #actions>
        <Button
          icon="pi pi-refresh"
          severity="secondary"
          variant="outlined"
          size="small"
          :loading="loading"
          @click="loadStats"
          v-tooltip.top="'刷新统计数据'" />
      </template>
    </PageHeader>

    <!-- 类型卡片网格 -->
    <div class="flex-1 p-6">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div
          v-for="type in metadataTypes"
          :key="type.key"
          class="bg-white rounded-xl shadow-sm border border-surface hover:shadow-md transition-all cursor-pointer group"
          @click="navigateToType(type)">

          <!-- 卡片头部 -->
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div
                class="w-12 h-12 rounded-lg flex items-center justify-center group-hover:scale-105 transition-transform"
                :style="{ backgroundColor: `${type.color}20` }">
                <i
                  :class="type.icon"
                  class="text-xl"
                  :style="{ color: type.color }">
                </i>
              </div>

              <i class="pi pi-arrow-right text-gray-400 group-hover:text-gray-600 group-hover:translate-x-1 transition-all"></i>
            </div>

            <h3 class="text-lg font-semibold text-gray-900 mb-2">{{ type.title }}</h3>
            <p class="text-sm text-gray-600 mb-4 leading-relaxed">{{ type.description }}</p>

            <!-- 统计信息 -->
            <div class="grid grid-cols-3 gap-3">
              <div class="text-center">
                <div class="text-lg font-bold text-gray-900">{{ type.stats.total }}</div>
                <div class="text-xs text-gray-500">总数</div>
              </div>
              <div class="text-center">
                <div class="text-lg font-bold text-green-600">{{ type.stats.active }}</div>
                <div class="text-xs text-gray-500">正常</div>
              </div>
              <div class="text-center">
                <div class="text-lg font-bold text-red-600">{{ type.stats.error }}</div>
                <div class="text-xs text-gray-500">异常</div>
              </div>
            </div>
          </div>

          <!-- 卡片底部状态条 -->
          <div class="h-1 bg-gray-100 rounded-b-xl overflow-hidden">
            <div
              class="h-full transition-all duration-500"
              :style="{
                width: type.stats.total > 0 ? `${(type.stats.active / type.stats.total) * 100}%` : '0%',
                backgroundColor: type.color
              }">
            </div>
          </div>
        </div>
      </div>

      <!-- 快速操作区域 -->
      <div class="mt-8 bg-white rounded-xl shadow-sm border border-surface p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <i class="pi pi-bolt text-blue-600"></i>
          快速操作
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <Button
            icon="pi pi-plus"
            label="添加数据库"
            severity="secondary"
            variant="outlined"
            size="small"
            class="w-full"
            @click="router.push('/metadata/databases')" />

          <Button
            icon="pi pi-plus"
            label="添加主机"
            severity="secondary"
            variant="outlined"
            size="small"
            class="w-full"
            @click="router.push('/metadata/hosts')" />

          <Button
            icon="pi pi-plus"
            label="添加MySQL"
            severity="secondary"
            variant="outlined"
            size="small"
            class="w-full"
            @click="router.push('/metadata/mysql')" />

          <Button
            icon="pi pi-plus"
            label="添加Trino"
            severity="secondary"
            variant="outlined"
            size="small"
            class="w-full"
            @click="router.push('/metadata/trino')" />

          <Button
            icon="pi pi-plus"
            label="添加HDFS"
            severity="secondary"
            variant="outlined"
            size="small"
            class="w-full"
            @click="router.push('/metadata/hdfs')" />
        </div>
      </div>

      <!-- 使用说明 -->
      <div class="mt-8 bg-blue-50 border border-blue-200 rounded-xl p-6">
        <h2 class="text-lg font-semibold text-blue-900 mb-3 flex items-center gap-2">
          <i class="pi pi-info-circle text-blue-600"></i>
          使用说明
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-800">
          <div>
            <h3 class="font-semibold mb-2">📊 主机管理</h3>
            <p>管理SSH连接配置，支持密码和密钥认证，用于远程服务器操作。</p>
          </div>

          <div>
            <h3 class="font-semibold mb-2">🗄️ MySQL管理</h3>
            <p>配置MySQL数据库连接，支持连接池和超时设置，用于数据存储和查询。</p>
          </div>

          <div>
            <h3 class="font-semibold mb-2">⚡ Trino管理</h3>
            <p>管理分布式SQL查询引擎连接，支持多catalog和schema配置。</p>
          </div>

          <div>
            <h3 class="font-semibold mb-2">📁 HDFS管理</h3>
            <p>配置Hadoop分布式文件系统，支持Kerberos认证和WebHDFS接口。</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
// 自定义卡片悬停效果
.group:hover {
  transform: translateY(-2px);
}

// 统计数字动画
.text-lg {
  transition: all 0.3s ease;
}
</style>
