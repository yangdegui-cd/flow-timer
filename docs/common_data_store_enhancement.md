# 通用数据 Store 优化总结

## 问题背景

在广告分析页面中，`project_id`、`ads_account_id`、`platform` 等维度列显示的是原始 ID 或代码，用户体验不佳。同时，每次需要这些数据时都要重复请求 API，效率低下。

## 解决方案

创建了 `common-data` store 来集中管理项目和广告账号数据，实现数据缓存和统一访问。

## 实现内容

### 1. 创建 Common Data Store

**文件**: `web/src/stores/common-data.ts`

**功能**:
- 缓存项目列表 (projects)
- 缓存广告账号列表 (adsAccounts)
- 提供 ID 到名称的转换方法
- 美化平台名称显示

**核心方法**:

```typescript
// 获取项目名称
getProjectName(projectId: number): string
// 例: 1 -> "测试项目"

// 获取账号名称
getAdsAccountName(accountId: number): string
// 例: 123 -> "Facebook 主账号"

// 获取平台名称（美化）
getPlatformName(platform: string): string
// 例: "facebook" -> "Facebook"
```

**平台映射**:
```typescript
const platformMap = {
  facebook: 'Facebook',
  google: 'Google',
  tiktok: 'TikTok',
  twitter: 'Twitter',
  instagram: 'Instagram',
  linkedin: 'LinkedIn'
}
```

### 2. 优化 AdsAnalytics.vue

#### 移除重复代码

**之前**:
```typescript
const projects = ref<any[]>([])
const accounts = ref<any[]>([])

const loadProjects = async () => {
  projects.value = await projectApi.list()
}

const loadAccounts = async () => {
  accounts.value = await adsDataApi.getAccounts(params)
}
```

**之后**:
```typescript
const commonDataStore = useCommonDataStore()

// 直接使用 store 中的数据
// commonDataStore.projects
// commonDataStore.adsAccounts
```

#### 美化维度值显示

更新了 `formatDimensionValue` 函数，针对特殊维度进行美化处理：

```typescript
const formatDimensionValue = (value: any, dimensionName: string) => {
  let displayValue: string

  switch (dimensionName) {
    case 'project_id':
      // 1 -> "测试项目"
      displayValue = commonDataStore.getProjectName(Number(value))
      break
    case 'ads_account_id':
      // 123 -> "Facebook 主账号"
      displayValue = commonDataStore.getAdsAccountName(Number(value))
      break
    case 'platform':
      // "facebook" -> "Facebook"
      displayValue = commonDataStore.getPlatformName(String(value))
      break
    default:
      displayValue = String(value)
  }

  return displayValue
}
```

#### 更新模板引用

**之前**:
```vue
<Select
  v-model="filters.project_id"
  :options="projects"
  optionLabel="name"
  optionValue="id"
/>
```

**之后**:
```vue
<Select
  v-model="filters.project_id"
  :options="commonDataStore.projects"
  optionLabel="name"
  optionValue="id"
/>
```

## 展示效果对比

### 优化前

| project_id | platform | ads_account_id | campaign_name | impressions |
|------------|----------|----------------|---------------|-------------|
| 1          | facebook | 123            | Summer Sale   | 10,000      |
| 2          | google   | 456            | Winter Sale   | 15,000      |

### 优化后

| 项目       | 平台     | 账号          | 广告系列     | 曝光量      |
|------------|----------|---------------|--------------|-------------|
| 测试项目   | Facebook | Facebook 主账号| Summer Sale  | 10,000      |
| 正式项目   | Google   | Google Ads 1  | Winter Sale  | 15,000      |

## 优点

### 1. 用户体验提升
- **可读性**: 显示友好的名称而不是 ID
- **一致性**: 平台名称统一大写格式
- **专业性**: 数据展示更加专业和规范

### 2. 性能优化
- **减少请求**: 数据缓存在 store 中，避免重复请求
- **按需加载**: 只在需要时加载账号数据
- **智能合并**: 账号数据支持增量加载和去重

### 3. 代码优化
- **集中管理**: 数据集中在 store 中管理
- **复用性**: 多个组件可共享同一份数据
- **可维护性**: 修改数据逻辑只需修改 store

### 4. 扩展性
- **易于扩展**: 可轻松添加新的数据类型（如广告系列等）
- **统一接口**: 所有数据访问都通过 store 的统一方法

## 使用示例

### 在其他页面中使用

```vue
<script setup lang="ts">
import { useCommonDataStore } from '@/stores/common-data'

const commonDataStore = useCommonDataStore()

// 获取项目名称
const projectName = commonDataStore.getProjectName(projectId)

// 获取账号名称
const accountName = commonDataStore.getAdsAccountName(accountId)

// 获取美化后的平台名称
const platformName = commonDataStore.getPlatformName('facebook')

// 访问原始数据
const allProjects = commonDataStore.projects
const allAccounts = commonDataStore.adsAccounts
</script>
```

### 加载特定条件的账号

```typescript
// 加载特定项目和平台的账号
await commonDataStore.loadAdsAccounts({
  project_id: 1,
  platform: 'facebook'
})
```

## 数据流程

```
1. 页面初始化
   ↓
2. Store onMounted 自动加载
   ↓
3. 加载 projects (一次性)
   ↓
4. 加载 adsAccounts (可按条件)
   ↓
5. 数据缓存在 store 中
   ↓
6. 多个组件共享同一份数据
   ↓
7. 通过 getter 方法获取美化后的显示值
```

## 注意事项

1. **数据更新**: Store 中的数据在页面刷新前会一直存在，如需强制刷新，可手动调用 load 方法
2. **账号去重**: `loadAdsAccounts` 会自动合并和去重账号数据
3. **默认值**: 如果找不到对应的名称，会显示 `"项目#1"` 或 `"账号#123"` 这样的兜底值

## 后续优化建议

1. **添加更多数据类型**: 如广告系列、广告组等的缓存
2. **数据过期机制**: 添加 TTL，自动刷新过期数据
3. **本地存储**: 考虑使用 localStorage 持久化常用数据
4. **懒加载**: 实现真正的按需加载，减少初始加载时间
5. **搜索功能**: 在 store 中添加搜索和过滤方法
6. **Loading 状态**: 更细粒度的 loading 状态管理
