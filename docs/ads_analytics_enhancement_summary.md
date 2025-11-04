# 广告分析页面完善总结

## 完成的工作

### 1. 数据库迁移

#### 添加 display_config JSON 列

创建了迁移文件用于为 `ads_metrics` 和 `ads_dimensions` 表添加 `display_config` 列：

**迁移文件**: `db/migrate/20251030053331_add_display_config_to_ads_metrics_and_dimensions.rb`

**字段说明**:
- `ads_metrics.display_config`: 存储指标的前端展示配置（对齐方式、格式化类型、小数位数等）
- `ads_dimensions.display_config`: 存储维度的前端展示配置（宽度、对齐方式、是否可排序、是否冻结、是否省略等）

#### 默认配置

**维度配置**:
- **时间维度** (quarter, month, week, date, hour):
  - width: 120-150px
  - align: center
  - sortable: true
  - frozen: true (冻结列)

- **项目维度**:
  - width: 150px
  - align: left
  - sortable: true

- **平台维度**:
  - width: 100px
  - align: center
  - sortable: true

- **账号维度**:
  - width: 180px
  - align: left
  - sortable: true

- **广告系列/广告组/广告维度**:
  - width: 200px
  - align: left
  - sortable: true
  - ellipsis: true (长文本省略)

**指标配置**:
- **货币类指标** (unit: $, ¥, 元, USD, CNY):
  - align: right
  - format: currency
  - decimals: 2

- **百分比指标** (unit: %):
  - align: right
  - format: percent
  - decimals: 2

- **数量类指标** (unit: 次, 个, 人 或 null):
  - align: right
  - format: number
  - decimals: 0

#### 更新原始迁移文件

更新了以下迁移文件的 `insert_all` 部分，在创建记录时就包含 display_config:
- `db/migrate/20251030022228_create_ads_dimensions.rb`
- `db/migrate/20251029041154_create_ads_metrics.rb`

### 2. 前端工具函数

创建了格式化辅助函数：`web/src/utils/format-helpers.ts`

**提供的功能**:
- `formatValue()`: 根据配置格式化数值
- `formatCurrency()`: 格式化货币（支持多种货币符号）
- `formatPercent()`: 格式化百分比
- `formatNumber()`: 格式化数字（添加千分位分隔符）
- `ellipsis()`: 截断长文本并添加省略号

**示例**:
```typescript
formatValue(1234.56, { format: 'currency', decimals: 2 }, '$')
// 输出: $1,234.56

formatValue(0.1234, { format: 'percent', decimals: 2 })
// 输出: 0.12%

formatNumber(1234567, 0)
// 输出: 1,234,567
```

### 3. 前端页面完善

更新了 `web/src/views/sub-pages/analytics/AdsAnalytics.vue`

#### 新增功能

1. **集成 stores**:
   - 使用 `useMetricsStore()` 获取指标信息和配置
   - 使用 `useDimensionsStore()` 获取维度信息和配置

2. **格式化函数**:
   - `formatMetricValue()`: 根据指标配置格式化指标值
   - `formatDimensionValue()`: 格式化维度值（支持省略号）
   - `getDimensionConfig()`: 获取维度的显示配置
   - `getMetricConfig()`: 获取指标的显示配置

3. **表格列配置**:
   - 动态从 `display_config` 读取列宽度
   - 应用对齐方式（left, center, right）
   - 支持冻结列（frozen）
   - 支持排序配置

4. **表格样式增强**:
   - 文本对齐样式（text-left, text-center, text-right）
   - 单元格省略号支持（ellipsis）
   - 悬停显示完整内容
   - 数字等宽字体（tabular-nums）

## 使用方式

### 在后端配置展示属性

展示配置存储在数据库中，不提供前端更新接口。如需修改配置，直接在数据库中更新：

```ruby
# 更新维度配置
dimension = AdsDimension.find_by(name: 'campaign_name')
dimension.update(display_config: {
  width: 250,
  align: 'left',
  sortable: true,
  ellipsis: true
})

# 更新指标配置
metric = AdsMetric.find_by(key: 'cpm')
metric.update(display_config: {
  align: 'right',
  format: 'currency',
  decimals: 2
})
```

### 前端自动应用配置

前端会自动从 API 获取 display_config 并应用到表格：

1. **维度列**: 自动应用宽度、对齐方式、排序、冻结等配置
2. **指标列**: 自动根据 format 和 decimals 格式化数值
3. **长文本**: 自动截断并添加省略号，悬停显示完整内容

## 配置参数说明

### 维度 display_config

```json
{
  "width": 200,          // 列宽度（px）
  "align": "left",       // 对齐方式: left|center|right
  "sortable": true,      // 是否可排序
  "frozen": true,        // 是否冻结列
  "ellipsis": true       // 长文本是否显示省略号
}
```

### 指标 display_config

```json
{
  "align": "right",      // 对齐方式: left|center|right
  "format": "currency",  // 格式化类型: currency|percent|number
  "decimals": 2          // 小数位数
}
```

## 优点

1. **可配置性**: 展示属性存储在数据库中，可灵活调整
2. **一致性**: 所有使用该指标/维度的地方展示格式一致
3. **可维护性**: 集中管理展示配置，不散落在代码中
4. **扩展性**: 可轻松添加新的展示属性（如颜色、图标等）
5. **性能**: 配置在数据库中，不需要额外请求
6. **用户体验**: 专业的数值格式化、合理的列宽和对齐

## 后续优化建议

1. 添加后台管理界面来配置 display_config（如果需要）
2. 支持更多格式化类型（日期、时间、文件大小等）
3. 支持自定义格式化函数
4. 添加列宽拖拽调整功能
5. 支持列的显示/隐藏配置
6. 添加导出功能（保持格式化）
