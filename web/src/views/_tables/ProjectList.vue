<script setup lang="ts">
import { ref } from 'vue'
import { getProjectStatusSeverity } from '@/api/project-api'
import { Project } from "@/data/types/project-types";

interface Props {
  projects: Project[]
  loading: boolean
}

interface Emits {
  (e: 'edit', project: Project): void
  (e: 'assign', project: Project): void
  (e: 'delete', project: Project): void
}

defineProps<Props>()
defineEmits<Emits>()

const globalFilter = ref('')

const formatStartDate = (dateString: string) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN')
}

const formatDate = (dateString: string, format?: string) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  if (format === 'YYYY-MM-DD HH:mm') {
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  }
  return date.toLocaleDateString('zh-CN')
}

const getStatusLabel = (status: string) => {
  switch (status) {
    case 'active':
      return '活跃'
    case 'inactive':
      return '非活跃'
    case 'archived':
      return '已归档'
    default:
      return status
  }
}
</script>

<template>
  <DataTable
    :value="projects"
    :loading="loading"
    class="p-datatable-sm"
    dataKey="id"
    stripedRows
    :globalFilterFields="['name', 'description', 'status']"
    scrollable
    scrollHeight="calc(100vh - 300px)"
    :paginator="true"
    :rows="20"
    :rowsPerPageOptions="[10, 20, 50]"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    currentPageReportTemplate="显示 {first} 到 {last} 条，共 {totalRecords} 条记录"
  >
    <!-- 表格头部工具栏 -->
    <template #header>
      <div class="flex justify-between items-center">
        <div class="flex items-center gap-2">
          <i class="pi pi-table text-gray-500"></i>
          <span class="text-gray-700 font-medium">项目列表</span>
          <Badge :value="projects?.length" severity="info" />
        </div>
        <div class="flex items-center gap-2">
          <span class="p-input-icon-left">
            <i class="pi pi-search"></i>
            <InputText
              placeholder="搜索项目..."
              class="p-inputtext-sm"
              v-model="globalFilter"
            />
          </span>
        </div>
      </div>
    </template>

    <!-- 项目名称列 -->
    <Column field="name" header="项目名称" sortable>
      <template #body="{ data }">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded bg-blue-100 flex items-center justify-center">
            <i class="pi pi-briefcase text-blue-600 text-sm"></i>
          </div>
          <div>
            <div class="font-medium text-gray-900">{{ data.name }}</div>
            <div class="text-sm text-gray-500" v-if="data.description">
              {{ data.description.length > 40 ? data.description.substring(0, 40) + '...' : data.description }}
            </div>
          </div>
        </div>
      </template>
    </Column>

    <!-- 开始日期列 -->
    <Column field="start_date" header="开始日期" sortable>
      <template #body="{ data }">
        <div class="flex items-center gap-2">
          <i class="pi pi-calendar text-gray-400"></i>
          <span class="text-gray-700">{{ formatStartDate(data.start_date) }}</span>
        </div>
      </template>
    </Column>

    <!-- 广告自动化状态列 -->
    <Column field="active_ads_automate" header="广告自动化" sortable>
      <template #body="{ data }">
        <Tag
          :value="data.active_ads_automate ? '启用' : '禁用'"
          :severity="data.active_ads_automate ? 'success' : 'warning'"
          :icon="data.active_ads_automate ? 'pi pi-check' : 'pi pi-times'"
        />
      </template>
    </Column>

    <!-- 项目状态列 -->
    <Column field="status" header="状态" sortable>
      <template #body="{ data }">
        <Tag
          :value="getStatusLabel(data.status)"
          :severity="getProjectStatusSeverity(data.status)"
        />
      </template>
    </Column>

    <!-- 分配用户数量列 -->
    <Column field="user_count" header="分配用户" sortable>
      <template #body="{ data }">
        <div class="flex items-center gap-2">
          <i class="pi pi-users text-gray-400"></i>
          <span class="text-gray-700">{{ data.user_count || 0 }} 人</span>
          <div class="flex -space-x-2" v-if="data.sys_users && data.sys_users.length > 0">
            <Avatar
              v-for="(user, index) in data.sys_users.slice(0, 3)"
              :key="user.id"
              :label="user.initials"
              size="small"
              shape="circle"
              :title="user.name"
              class="border-2 border-white"
            />
            <Avatar
              v-if="data.sys_users.length > 3"
              :label="`+${data.sys_users.length - 3}`"
              size="small"
              shape="circle"
              severity="secondary"
              class="border-2 border-white"
            />
          </div>
        </div>
      </template>
    </Column>

    <!-- 创建时间列 -->
    <Column field="created_at" header="创建时间" sortable>
      <template #body="{ data }">
        <div class="text-sm text-gray-600">
          {{ formatDate(data.created_at, 'YYYY-MM-DD HH:mm') }}
        </div>
      </template>
    </Column>

    <!-- 操作列 -->
    <Column header="操作" :style="{ width: '150px' }">
      <template #body="{ data }">
        <div class="flex gap-1">
          <Button
            @click="$emit('edit', data)"
            size="small"
            text
            severity="info"
            v-tooltip.top="'编辑项目'"
          >
            <i class="pi pi-cog"></i>
          </Button>
          <Button
            @click="$emit('delete', data)"
            size="small"
            text
            severity="danger"
            v-tooltip.top="'删除项目'"
          >
            <i class="pi pi-trash"></i>
          </Button>
        </div>
      </template>
    </Column>

    <!-- 空数据模板 -->
    <template #empty>
      <div class="text-center py-8">
        <i class="pi pi-inbox text-gray-400 text-4xl mb-4"></i>
        <div class="text-gray-500 text-lg mb-2">暂无项目数据</div>
        <div class="text-gray-400 text-sm">点击上方"新建项目"按钮来创建第一个项目</div>
      </div>
    </template>
  </DataTable>
</template>

<style scoped>
:deep(.p-datatable .p-datatable-tbody > tr > td) {
  padding: 1rem 0.75rem;
  border-bottom: 1px solid #e5e7eb;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
  color: #374151;
  font-weight: 600;
  padding: 1rem 0.75rem;
}

:deep(.p-datatable .p-datatable-tbody > tr:hover) {
  background: #f9fafb;
}

:deep(.p-paginator) {
  border-top: 1px solid #e5e7eb;
  background: #fafafa;
}

:deep(.p-avatar) {
  font-size: 0.75rem;
  width: 1.5rem;
  height: 1.5rem;
}
</style>
