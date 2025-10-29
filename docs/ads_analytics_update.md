# 广告数据分析页面更新说明

## 更新概述

将 `/analytics/ads` 页面从传统的图表展示改为基于维度和指标的灵活分析系统。

## 主要变更

### 1. 新增 Metrics Store

**文件**: `web/src/stores/metrics.ts`

提供指标管理的全局状态和方法：

```typescript
export const useMetricsStore = defineStore('metrics', () => {
  // 状态
  const metrics = ref<Metric[]>([])
  const categorizedMetrics = ref<MetricCategory[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 方法
  const fetchMetrics = async (params?) => { ... }
  const fetchCategorizedMetrics = async () => { ... }
  const calculateMetrics = async (params: CalculateParams) => { ... }
  const getMetricsByIds = (ids: number[]) => { ... }
  ...
})
```

**主要接口**:
- `Metric`: 指标定义
- `MetricResult`: 指标计算结果
- `GroupedResult`: 分组后的结果
- `CalculateParams`: 计算参数

### 2. 重写 AdsAnalytics.vue 页面

**文件**: `web/src/views/sub-pages/analytics/AdsAnalytics.vue`

#### 核心功能

1. **筛选条件面板**
   - 项目筛选
   - 平台筛选
   - 账号筛选
   - 日期范围选择

2. **维度和指标配置面板**
   - 时间维度选择（单选）：季度、月、周、日期、小时
   - 属性维度选择（多选）：项目、平台、账号、广告系列、广告组、广告
   - 指标选择（多选）：60+ 个预定义指标，支持搜索

3. **结果展示**
   - 无分组时：显示卡片式汇总数据
   - 有分组时：显示数据表格，支持分页、排序

#### 主要代码结构

```vue
<script setup lang="ts">
import { useMetricsStore } from '@/stores/metrics'

const metricsStore = useMetricsStore()

// 筛选器状态
const filters = reactive({
  project_id: null,
  platform: '',
  ads_account_id: null,
  start_date: '',
  end_date: '',
  time_dimension: '',  // 时间维度（互斥）
  dimensions: [],      // 属性维度（可多选）
  metric_ids: []       // 指标IDs（可多选）
})

// 查询数据
const queryData = async () => {
  const response = await metricsStore.calculateMetrics(filters)
  results.value = response.results
}
</script>
```

### 3. 后端 API 支持

使用现有的 `POST /api/metrics/calculate` API：

**请求示例**:
```json
{
  "metric_ids": [1, 6, 7],
  "start_date": "2025-09-01",
  "end_date": "2025-09-30",
  "project_id": 1,
  "platform": "facebook",
  "time_dimension": "date",
  "dimensions": ["platform", "campaign_name"]
}
```

**响应示例（有分组）**:
```json
{
  "results": [
    {
      "time_value": "2025-09-04",
      "platform": "facebook",
      "campaign_name": "Campaign A",
      "metrics": [
        {
          "metric_id": 1,
          "name_cn": "展示(平台)",
          "value": 176821,
          "formatted_value": "176821",
          "unit": "次",
          "color": "#3B82F6"
        }
      ]
    }
  ],
  "total_rows": 10
}
```

## 使用说明

### 1. 基本查询（无分组）

**步骤**:
1. 选择日期范围
2. 选择要查看的指标（如：展示、点击、花费）
3. 点击"查询数据"

**结果**: 显示选中指标的汇总数据卡片

### 2. 按时间维度分组

**步骤**:
1. 选择日期范围
2. 选择时间维度（如：日期）
3. 选择指标
4. 点击"查询数据"

**结果**: 按日期分组的数据表格

### 3. 多维度分组

**步骤**:
1. 选择日期范围
2. 选择时间维度（如：周）
3. 选择属性维度（如：平台、广告系列）
4. 选择指标
5. 点击"查询数据"

**结果**: 按周+平台+广告系列的多维度数据表格

### 4. 筛选 + 分组

可以组合使用筛选条件和分组维度：
- 筛选条件：缩小数据范围（如：只看某个项目的数据）
- 分组维度：对筛选后的数据进行分组展示

## 界面特性

### 1. 指标选择器

- 支持搜索：可按中文名、英文名、描述搜索
- 颜色标识：每个指标有独特的颜色
- 分类标签：显示指标所属分类
- 最多显示 5 个选中标签，超出显示数量

### 2. 数据表格

- 维度列冻结：滚动时维度列固定显示
- 可排序：所有列都支持排序
- 分页：支持 10/25/50/100 条/页
- 条纹行：提高可读性

### 3. 汇总卡片

- 颜色边框：使用指标定义的颜色
- 大字体值：突出显示数值
- 单位显示：自动格式化（金额、百分比等）

## 技术细节

### 指标格式化

在 `Metric` 模型中实现：

```ruby
def format_value(value)
  case unit
  when '$', '¥'
    "#{unit}#{value.to_f.round(2)}"
  when '%'
    "#{value.to_f.round(2)}%"
  when '次', '人'
    value.to_i.to_s
  else
    value.to_f.round(4).to_s
  end
end
```

### 维度分组 SQL

- 季度：`CONCAT(YEAR(date), '-Q', QUARTER(date))`
- 月：`DATE_FORMAT(date, '%Y-%m')`
- 周：`CONCAT(YEAR(date), '-W', LPAD(WEEK(date, 1), 2, '0'))`
- 日期：`date`
- 小时：`datetime`

## 性能优化

1. **按需加载指标**：只在页面加载时获取一次指标列表
2. **分页**：大数据集自动分页显示
3. **冻结列**：只冻结维度列，提高表格渲染性能
4. **筛选条件**：先筛选再分组，减少计算量

## 兼容性说明

- 保持原有的路由地址 `/analytics/ads`
- 页面标题改为"广告数据分析"
- 移除了原有的图表功能，专注于数据表格展示
- 所有数据查询都使用新的 metrics API

## 后续优化建议

1. **图表可视化**：为分组数据添加图表展示选项
2. **数据导出**：支持导出为 CSV/Excel
3. **保存查询**：保存常用的维度和指标配置
4. **对比分析**：支持时间对比、环比同比
5. **自定义指标**：允许用户创建自定义计算指标
