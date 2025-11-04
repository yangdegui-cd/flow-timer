# 广告数据分析 - 维度指标系统完成总结

## ✅ 完成的工作

### 1. 后端实现

#### Metrics Store (Pinia)
**文件**: `web/src/stores/metrics.ts`

- 简化的 metrics store，只保留核心功能
- 使用现有的 `metricsApi` 替代直接axios调用
- 提供3个核心方法：
  - `fetchMetrics()` - 获取指标列表
  - `calculateMetrics(params)` - 计算指标数据
  - `getMetricsByIds(ids)` - 根据ID获取指标

**接口定义**:
```typescript
interface Metric {
  id: number
  display_name: string
  key: string
  description: string
  sql_expression: string
  unit: string
  color: string
  category: string
  data_source: string
  sort_order: number
}

interface MetricResult {
  metric_id: number
  display_name: string
  key: string
  value: any
  formatted_value: string
  unit: string
  color: string
  error?: string
}

interface GroupedResult {
  time_dimension?: string
  time_value?: string
  project_id?: number
  project_name?: string
  platform?: string
  ...
  metrics: MetricResult[]
}
```

#### API Controller
**文件**: `app/controllers/api/metrics_controller.rb`

- 支持维度分组的指标计算
- 时间维度：季度、月、周、日期、小时
- 属性维度：项目、平台、账号、广告系列、广告组、广告
- 所有SQL使用Arel.sql包装，确保安全性

### 2. 前端实现

#### 更新的页面
**文件**: `web/src/views/sub-pages/analytics/AdsAnalytics.vue`

**新增功能**:

1. **筛选条件面板**
   - 项目、平台、账号筛选
   - 日期范围选择（默认2025-09-01 ~ 2025-09-30）

2. **维度和指标配置面板**
   - 时间维度选择器（单选）
   - 属性维度选择器（多选，支持chip显示）
   - 指标选择器（多选，支持搜索，最多显示5个标签）

3. **结果展示**
   - 无分组：卡片式展示（带颜色边框）
   - 有分组：数据表格展示（维度列冻结，支持排序和分页）

**移除的功能**:
- 原有的图表功能
- 原有的统计卡片
- 原有的设备、广告系列等固定图表

### 3. 指标系统

#### 已配置的60个指标

分为6大类：
- **数量指标** (5个): 展示、点击、安装、转化
- **成本指标** (9个): 花费、CPM、CPC、CPI
- **率指标** (2个): CTR、CVR
- **收入指标** (16个): 同期群收入、D0-D6收入、ROAS
- **LTV指标** (7个): D0-D6 LTV
- **留存指标** (21个): D0-D6留存率、付费人数

#### 数据源标识

- 平台数据：后缀 `_p`，如 `impressions_p`
- Adjust数据：后缀 `_a`，如 `installs_a`
- 计算指标：使用SQL表达式计算

## 🎯 核心特性

### 1. 灵活的维度组合

**示例组合**:
- 按日期查看数据
- 按周+平台分组
- 按月+广告系列+广告组分组
- 任意维度组合

### 2. 指标搜索和筛选

- 支持按中文名、英文名、描述搜索
- 颜色标识区分不同指标
- 分类标签显示

### 3. 数据展示模式

**无分组模式**:
```
┌──────────────┐ ┌──────────────┐
│ 展示(平台)    │ │ 花费(平台)    │
│   176,821    │ │  $901.20     │
└──────────────┘ └──────────────┘
```

**分组模式**:
```
| 日期       | 平台      | 展示      | 花费     |
|-----------|----------|----------|---------|
| 2025-09-04| facebook | 176,821  | $901.20 |
| 2025-09-05| facebook | 58,628   | $429.20 |
```

## 📊 使用示例

### 示例1: 查看每日花费和ROAS

```
筛选条件:
- 日期: 2025-09-01 ~ 2025-09-30
- 项目: MH01

维度配置:
- 时间维度: 日期
- 指标: 花费(Adjust)、ROAS(Adjust)

结果: 按日期展示的数据表格
```

### 示例2: 对比不同广告系列的效果

```
筛选条件:
- 日期: 2025-09-01 ~ 2025-09-30

维度配置:
- 属性维度: 广告系列
- 指标: 展示(平台)、点击(平台)、花费(平台)、CTR(平台)、CPI(Adjust)

结果: 按广告系列分组的对比数据
```

### 示例3: 周度趋势分析

```
筛选条件:
- 日期: 2025-09-01 ~ 2025-09-30

维度配置:
- 时间维度: 周
- 指标: 花费(平台)、ROAS D7(Adjust)、留存率D7(Adjust)

结果: 按周展示的趋势数据
```

## 🔧 技术细节

### API请求格式

```typescript
const params = {
  metric_ids: [1, 6, 7],          // 指标IDs
  start_date: '2025-09-01',
  end_date: '2025-09-30',
  project_id: 1,                  // 可选筛选条件
  platform: 'facebook',           // 可选筛选条件
  time_dimension: 'date',         // 可选时间维度
  dimensions: ['campaign_name']   // 可选属性维度
}

const response = await metricsStore.calculateMetrics(params)
```

### 指标格式化

- 金额: `$123.45`
- 百分比: `12.34%`
- 数量: `123,456`
- 其他: `1.2345` (保留4位小数)

### SQL示例

**时间维度**:
- 季度: `CONCAT(YEAR(date), '-Q', QUARTER(date))`
- 月: `DATE_FORMAT(date, '%Y-%m')`
- 周: `CONCAT(YEAR(date), '-W', LPAD(WEEK(date, 1), 2, '0'))`

**指标计算**:
- CPM: `(SUM(spend) / NULLIF(SUM(impressions), 0)) * 1000`
- CTR: `(SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100`
- ROAS: `SUM(cohort_all_revenue) / NULLIF(SUM(adjust_spend), 0)`

## 📝 文件清单

### 新增文件
- `web/src/stores/metrics.ts` - Metrics Store
- `docs/metrics_analytics.md` - 详细使用文档
- `docs/ads_analytics_update.md` - 更新说明
- `docs/SUMMARY.md` - 本总结文档

### 修改文件
- `app/controllers/api/metrics_controller.rb` - 添加维度分组功能
- `app/models/metric.rb` - 修复$单位格式化
- `web/src/views/sub-pages/analytics/AdsAnalytics.vue` - 完全重写
- `web/src/router/index.ts` - 保持原有路由

### 数据库
- `db/seeds/metrics_seed.rb` - 60个预定义指标

## 🚀 访问方式

- **URL**: `http://localhost:5174/analytics/ads`
- **路由名**: `ads-analytics`
- **菜单标题**: "广告数据分析"

## ✨ 后续优化建议

1. **数据导出**: 添加导出为CSV/Excel功能
2. **图表可视化**: 为分组数据添加折线图、柱状图
3. **保存配置**: 保存常用的维度和指标组合
4. **对比分析**: 支持时间对比（环比、同比）
5. **自定义指标**: 允许用户自定义SQL计算指标
6. **数据缓存**: 对常用查询结果进行缓存
7. **实时更新**: 支持定时自动刷新数据
