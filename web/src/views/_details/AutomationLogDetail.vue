<script setup lang="ts">

import { getActionLabel, getActionSeverity } from "@/data/options/automation-actions";
import Tag from "primevue/tag";
import { format } from "date-fns";
import CopyText from "@/components/CopyText.vue";

const props = defineProps<{
  log: any | null
}>()

// 获取操作类型严重程度
const getActionTypeSeverity = (actionType: string) => {
  const severityMap: Record<string, any> = {
    项目编辑: 'info',
    规则触发: 'success',
    定时任务: 'warning',
    调整广告投放: 'danger'
  }
  return severityMap[actionType] || 'info'
}

// 格式化日期时间
const formatDateTime = (dateStr: string) => {
  return format(new Date(dateStr), 'yyyy-MM-dd HH:mm:ss')
}

// 格式化JSON
const formatJson = (obj: any) => {
  return JSON.stringify(obj, null, 2)
}

</script>

<template>
  <div class="log-detail">
    <!-- 第一行：触发规则、耗时、状态 -->
    <div class="detail-row">
      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-tag text-sm mr-2"></i>
          操作类型
        </div>
        <div class="card-content">
          <Tag :value="log.action_type" :severity="getActionTypeSeverity(log.action_type)"
               size="small"/>
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-check-circle text-sm mr-2"></i>
          状态
        </div>
        <div class="card-content">
          <Tag
              :value="log.display_status"
              :severity="log.status === 'success' ? 'success' : 'danger'"
              size="small"
          />
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-bolt text-sm mr-2"></i>
          触发规则
        </div>
        <div class="card-content">
          <Tag
              :value="getActionLabel(log.remark.action)"
              :severity="getActionSeverity(log.remark.action)"
              size="small"
          />
        </div>
      </div>
    </div>

    <!-- 第二行：操作类型、操作人、创建时间 -->
    <div class="detail-row">
      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-clock text-sm mr-2"></i>
          耗时
        </div>
        <div class="card-content">
              <span class="font-semibold">{{
                  log.duration_in_seconds ? `${log.duration_in_seconds}秒` : '-'
                }}</span>
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-user text-sm mr-2"></i>
          操作人
        </div>
        <div class="card-content">
          <span class="font-semibold">{{ log.sys_user?.name || '系统' }}</span>
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-calendar text-sm mr-2"></i>
          创建时间
        </div>
        <div class="card-content">
          <span class="font-semibold">{{ formatDateTime(log.created_at) }}</span>
        </div>
      </div>
    </div>

    <!-- 操作描述 -->
    <div class="detail-card">
      <div class="card-header">
        <i class="pi pi-file-edit text-sm mr-2"></i>
        操作描述
      </div>
      <div class="card-content">
        <span class="font-semibold">{{ log.display_name }}</span>
      </div>
    </div>

    <!-- 广告信息 -->
    <div class="detail-card" v-if="log.action_type === '规则触发' && log.status === 'success'">
      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-box text-sm mr-2"></i>
          广告系列
        </div>
        <div class="card-content">
          <CopyText :text="log.remark.campaign_name">
            <Tag :value="log.remark.campaign_name"></Tag>
          </CopyText>
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-circle text-sm mr-2"></i>
          广告组
        </div>
        <div class="card-content">
          <CopyText :text="log.remark.adset_name">
            <Tag :value="log.remark.adset_name"/>
          </CopyText>
        </div>
      </div>

      <div class="detail-card">
        <div class="card-header">
          <i class="pi pi-circle-fill text-sm mr-2"></i>
          广告
        </div>
        <div class="card-content">
          <CopyText :text="log.remark.ad_name">
            <Tag :value="log.remark.ad_name"></Tag>
          </CopyText>
        </div>
      </div>
      <div class="detail-card" v-if="log.remark.thumbnail_url">
        <div class="card-header">
          <i class="pi pi-calendar text-sm mr-2"></i>
          缩略图
        </div>
        <div class="card-content">
          <img :src="log.remark.thumbnail_url" alt="Ad Thumbnail" style="max-width: 100px; max-height: 100px;"/>
        </div>
      </div>
    </div>


    <!-- 详细信息 -->
    <div class="detail-card">
      <div class="card-header">
        <i class="pi pi-info-circle text-sm mr-2"></i>
        详细信息
      </div>
      <div class="json-content">
        <pre class="json-code">{{ formatJson(log.remark) }}</pre>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.automation-logs-tab {
  padding: 0;
}

// 紧凑表格样式
:deep(.compact-table) {
  // 减少表格单元格padding
  .p-datatable-tbody > tr > td {
    padding: 0.5rem 0.75rem;
  }

  .p-datatable-thead > tr > th {
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
    font-weight: 600;
  }

  // 减少分页器padding
  .p-paginator {
    padding: 0.5rem;
  }

  // 优化Tag组件间距
  .p-tag {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
  }

  // 优化按钮大小
  .p-button {
    width: 2rem;
    height: 2rem;
  }
}

.logs-card {
  .user-info-compact {
    display: flex;
    align-items: center;
    white-space: nowrap;
  }

  .text-muted {
    color: var(--text-color-secondary);
    font-style: italic;
  }

  .action-desc {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    line-height: 1.5;
    cursor: help;
  }

  .rule-name {
    display: inline-block;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    cursor: help;
  }

  .empty-state {
    text-align: center;
    padding: 2rem;

    p {
      margin-top: 0.5rem;
      color: var(--text-color-secondary);
      font-size: 0.875rem;
    }
  }
}

// 文本尺寸工具类
.text-xs {
  font-size: 0.75rem;
}

.text-sm {
  font-size: 0.875rem;
}

// 文本换行控制
.whitespace-nowrap {
  white-space: nowrap;
}

.log-detail {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;

  // 行容器
  .detail-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;

    // 如果只有2个项目，使用2列
    &:has(.detail-card:nth-child(2):last-child) {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  // 统一的详情卡片样式
  .detail-card {
    background: var(--surface-0);
    border: 1px solid var(--surface-200);
    border-radius: 6px;
    overflow: hidden;

    .card-header {
      display: flex;
      align-items: center;
      padding: 0.5rem 0.75rem;
      background: var(--surface-100);
      font-size: 0.8rem;
      font-weight: 600;
      color: var(--text-color-secondary);
      border-bottom: 1px solid var(--surface-200);
    }

    .card-content {
      padding: 0.75rem;
      font-size: 0.875rem;
      color: var(--text-color);
      line-height: 1.5;
    }

    // JSON内容区域
    .json-content {
      background: #282c34;
      padding: 0;

      .json-code {
        padding: 1rem;
        margin: 0;
        font-size: 0.75rem;
        line-height: 1.5;
        overflow-x: auto;
        max-height: 400px;
        font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', 'source-code-pro', monospace;

        // JSON语法高亮颜色
        color: #ffffff;

        // 关键字颜色
        ::selection {
          background: rgba(255, 255, 255, 0.1);
        }
      }
    }
  }
}

// 紧凑对话框样式
:deep(.compact-dialog) {
  .p-dialog-content {
    padding: 1rem;
  }

  .p-dialog-header {
    padding: 1rem;
  }
}

// Tailwind工具类
.font-semibold {
  font-weight: 600;
}

.mb-2 {
  margin-bottom: 0.5rem;
}

.mb-3 {
  margin-bottom: 0.75rem;
}

.mr-1 {
  margin-right: 0.25rem;
}

.mr-2 {
  margin-right: 0.5rem;
}
</style>
