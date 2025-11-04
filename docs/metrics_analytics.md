# 指标维度分析功能使用说明

## 功能概述

指标维度分析功能允许用户根据多个维度对广告数据进行分组，并计算各种指标。

## 访问地址

- 前端页面：`/analytics/metrics`
- 路由名称：`metrics-analytics`

## 功能特性

### 1. 时间维度（互斥，单选）

用户可以选择以下时间维度之一进行分组：

- **季度**：按季度汇总数据（例如：2025-Q3）
- **月**：按月汇总数据（例如：2025-09）
- **周**：按周汇总数据（例如：2025-W36）
- **日期**：按日期汇总数据（例如：2025-09-04）
- **小时**：按小时汇总数据（使用datetime字段）

### 2. 属性维度（可多选）

用户可以同时选择多个属性维度进行分组：

- **项目**：按项目分组
- **平台**：按广告平台分组（Facebook、Google、TikTok等）
- **账号**：按广告账号分组
- **广告系列**：按campaign_name分组
- **广告组**：按adset_name分组
- **广告**：按ad_name分组

### 3. 指标选择（多选）

系统提供60+个预定义指标，分为6大类：

- **数量指标**：展示、点击、安装、转化等
- **成本指标**：花费、CPM、CPC、CPI等
- **率指标**：CTR、CVR等
- **收入指标**：同期群收入、ROAS、D0-D6收入等
- **LTV指标**：D0-D6用户生命周期价值
- **留存指标**：D0-D6留存率、付费人数等

## 使用示例

### 示例1：按日期查看展示和花费

**配置：**
- 时间维度：日期
- 指标：展示(平台)、花费(平台)
- 日期范围：2025-09-01 ~ 2025-09-30

**结果：**
```
日期         展示(平台)    花费(平台)
2025-09-04   176,821      $901.20
2025-09-05   58,628       $429.20
...
```

### 示例2：按月和平台查看多个指标

**配置：**
- 时间维度：月
- 属性维度：平台
- 指标：展示(平台)、点击(平台)、花费(平台)、CPM(平台)、CTR(平台)

**结果：**
```
月份      平台      展示       点击     花费       CPM      CTR
2025-09  facebook  747,612   12,345   $4,766.82  $6.38    1.65%
```

### 示例3：按广告系列查看ROAS

**配置：**
- 属性维度：广告系列
- 指标：花费(Adjust)、同期群收入(Adjust)、ROAS(Adjust)
- 日期范围：2025-09-01 ~ 2025-09-30

**结果：**
```
广告系列                    花费        收入        ROAS
MH01-L11-Global-MAIA-3S划线  $1,234.56  $2,468.00  2.00
...
```

### 示例4：多维度组合分析

**配置：**
- 时间维度：周
- 属性维度：平台、广告系列
- 指标：展示(平台)、花费(平台)、CPI(Adjust)、ROAS D7(Adjust)

**结果：**
```
周        平台      广告系列              展示      花费      CPI        ROAS D7
2025-W36  facebook  Campaign A          50,000    $300.00   $2.50      1.85
2025-W36  facebook  Campaign B          45,000    $280.00   $3.10      1.62
2025-W37  facebook  Campaign A          52,000    $310.00   $2.45      1.92
...
```

## API 接口

### 请求

```http
POST /api/metrics/calculate
Content-Type: application/json

{
  "metric_ids": [1, 6, 7],           // 必选：指标ID数组
  "start_date": "2025-09-01",        // 可选：开始日期
  "end_date": "2025-09-30",          // 可选：结束日期
  "project_id": 1,                   // 可选：项目ID筛选
  "platform": "facebook",            // 可选：平台筛选
  "ads_account_id": 123,             // 可选：账号ID筛选
  "time_dimension": "date",          // 可选：时间维度（quarter/month/week/date/hour）
  "dimensions": ["platform", "campaign_name"]  // 可选：属性维度数组
}
```

### 响应（无分组）

```json
{
  "results": [
    {
      "metric_id": 1,
      "display_name": "展示(平台)",
      "key": "impressions_p",
      "value": 747612,
      "formatted_value": "747612",
      "unit": "次",
      "color": "#3B82F6"
    },
    {
      "metric_id": 6,
      "display_name": "花费(平台)",
      "key": "spend_p",
      "value": "4766.82",
      "formatted_value": "$4766.82",
      "unit": "$",
      "color": "#F59E0B"
    }
  ],
  "query_params": { ... }
}
```

### 响应（有分组）

```json
{
  "results": [
    {
      "time_dimension": "date",
      "time_value": "2025-09-04",
      "platform": "facebook",
      "metrics": [
        {
          "metric_id": 1,
          "display_name": "展示(平台)",
          "value": 176821,
          "formatted_value": "176821",
          "unit": "次",
          "color": "#3B82F6"
        },
        {
          "metric_id": 6,
          "display_name": "花费(平台)",
          "value": "901.2",
          "formatted_value": "$901.2",
          "unit": "$",
          "color": "#F59E0B"
        }
      ]
    }
  ],
  "query_params": { ... },
  "total_rows": 10
}
```

## 技术实现

### 后端

- **Controller**: `Api::MetricsController#calculate`
- **Model**: `Metric`
- **数据源**: `AdsMergeDatum` (ads_merge_data视图)

### 时间维度SQL实现

- 季度：`CONCAT(YEAR(date), '-Q', QUARTER(date))`
- 月：`DATE_FORMAT(date, '%Y-%m')`
- 周：`CONCAT(YEAR(date), '-W', LPAD(WEEK(date, 1), 2, '0'))`
- 日期：`date`
- 小时：`datetime`

### 前端

- **组件**: `MetricsAnalytics.vue`
- **路由**: `/analytics/metrics`
- **UI组件**: PrimeVue (Select, MultiSelect, DataTable等)

## 注意事项

1. **必须选择至少一个指标**，否则查询会失败
2. **时间维度是互斥的**，只能选择一个或不选
3. **属性维度可以多选**，支持任意组合
4. **如果不选择任何维度**，系统会返回汇总数据
5. **分组查询会自动JOIN相关表**（如选择项目维度会JOIN projects表）
6. **所有SQL表达式都使用Arel.sql包装**，确保安全性

## 性能优化建议

1. 避免选择过多维度，会导致结果行数过多
2. 合理设置日期范围，避免查询过大数据集
3. 优先使用筛选条件（项目、平台、账号）缩小数据范围
4. 按小时维度分组时数据量较大，建议缩小日期范围

## 后续扩展

可以考虑添加以下功能：

1. 数据导出（CSV、Excel）
2. 图表可视化（折线图、柱状图）
3. 对比分析（环比、同比）
4. 自定义指标（用户自定义SQL表达式）
5. 保存查询配置（常用查询模板）
