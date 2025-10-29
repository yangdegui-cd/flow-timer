# 组件提取总结

## 概述

将 ProjectDetailPage.vue 中的自动化规则编辑功能提取为独立的可复用组件。

## 创建的组件

### 1. ConditionGroupDisplay.vue

**路径**: `web/src/views/_dialogs/ConditionGroupDisplay.vue`

**功能**: 递归渲染条件组和条件，支持多层嵌套

**实现方式**: 使用 Vue Template 语法（支持递归组件调用）

**Props**:
- `group`: TriggerCondition - 要显示的条件组
- `level`: number - 当前嵌套层级（默认0）
- `numericMetricOptions`: Array - 数值指标选项
- `stringMetricOptions`: Array - 字符串指标选项
- `numericOperatorOptions`: Array - 数值操作符选项
- `stringOperatorOptions`: Array - 字符串操作符选项

**Emits**:
- `remove`: 删除条件或条件组
- `addCondition`: 添加条件到组
- `addGroup`: 添加条件组
- `edit`: 编辑条件
- `toggleLogic`: 切换逻辑运算符（AND/OR）

**接口导出**:
```typescript
export interface TriggerCondition {
  id: number
  type: 'condition' | 'group'
  metricType?: 'numeric' | 'string'
  metric?: string
  operator?: string
  value?: number | string
  logic?: 'AND' | 'OR'
  children?: TriggerCondition[]
}
```

### 2. ConditionEditDialog.vue

**路径**: `web/src/views/_dialogs/ConditionEditDialog.vue`

**功能**: 编辑或添加单个条件

**Props**:
- `visible`: boolean - 对话框是否可见
- `condition`: TriggerCondition | null - 要编辑的条件
- `isEdit`: boolean - 是否为编辑模式
- `targetGroup`: TriggerCondition | null - 目标条件组
- `numericMetricOptions`: Array - 数值指标选项
- `stringMetricOptions`: Array - 字符串指标选项
- `numericOperatorOptions`: Array - 数值操作符选项
- `stringOperatorOptions`: Array - 字符串操作符选项
- `availableAccountNames`: string[] - 可用账号名称
- `availableCampaignNames`: string[] - 可用广告系列名称
- `availableAdsetNames`: string[] - 可用广告组名称
- `availableAdNames`: string[] - 可用广告名称

**Emits**:
- `update:visible`: 更新可见状态
- `save`: 保存条件

**特性**:
- 支持数值和字符串两种类型指标
- 数值类型：显示 InputNumber 和单位
- 字符串类型：根据操作符显示 Dropdown 或 InputText
- 等于/不等于操作符使用下拉选择
- 包含/不包含操作符使用文本输入
- 自动验证输入值范围

### 3. AutomationRuleDialog.vue

**路径**: `web/src/views/_dialogs/AutomationRuleDialog.vue`

**功能**: 创建或编辑自动化规则

**Props**:
- `visible`: boolean - 对话框是否可见
- `rule`: AutomationRule | null - 要编辑的规则
- `projectId`: number - 项目ID
- `numericMetricOptions`: Array - 数值指标选项
- `stringMetricOptions`: Array - 字符串指标选项
- `numericOperatorOptions`: Array - 数值操作符选项
- `stringOperatorOptions`: Array - 字符串操作符选项
- `availableAccountNames`: string[] - 可用账号名称
- `availableCampaignNames`: string[] - 可用广告系列名称
- `availableAdsetNames`: string[] - 可用广告组名称
- `availableAdNames`: string[] - 可用广告名称

**Emits**:
- `update:visible`: 更新可见状态
- `saved`: 保存规则（返回规则数据）

**包含内容**:
- 规则名称输入
- 时间参数配置（粒度、范围）
- 触发条件配置（使用 ConditionGroupDisplay）
- 触发动作配置
- 规则启用状态切换
- 内部集成 ConditionEditDialog

## 修改的文件

### ProjectDetailPage.vue

**删除的内容**:
1. `ConditionGroupDisplay` defineComponent（约160行）
2. 规则对话框模板（约150行）
3. 条件编辑对话框模板（约120行）
4. 相关的状态和方法：
   - `newRule`, `currentCondition` 状态
   - `targetGroup`, `editingCondition`, `isConditionEditMode` 状态
   - `TriggerCondition` 接口定义
   - `onMetricTypeChange`, `onMetricChange` 方法
   - `addConditionToRoot`, `addGroupToRoot` 方法
   - `openConditionDialog`, `addConditionToGroup`, `editCondition` 方法
   - `confirmAddCondition`, `removeFromGroup`, `removeConditionOrGroup` 方法
   - `toggleGroupLogic` 方法
   - `resetRuleForm`, `addAutomationRule` 方法
   - 相关的计算属性

**新增的内容**:
1. 导入 `AutomationRuleDialog` 组件
2. `handleRuleSaved` 方法 - 处理规则保存

**简化的内容**:
1. `openRuleDialog` - 只设置状态
2. `openEditRuleDialog` - 只设置编辑规则
3. 保留 `formatConditionText` 和 `formatConditionGroupText` 用于规则列表显示

**移除的导入**:
- `defineComponent`, `h` from vue
- `InputNumber`, `Divider` from primevue（如果其他地方不使用）

## 代码统计

**删除代码行数**: 约 430 行
**新增代码行数**: 约 10 行（在 ProjectDetailPage.vue）
**新增组件代码**: 约 600 行（3个新文件）

**净效果**:
- ProjectDetailPage.vue 从 1956 行减少到约 1540 行
- 代码更模块化，可复用性更高
- 职责更清晰，易于维护

## 使用方式

### 在 ProjectDetailPage.vue 中使用

```vue
<script setup lang="ts">
import AutomationRuleDialog from '@/views/_dialogs/AutomationRuleDialog.vue'

const showRuleDialog = ref(false)
const editingRule = ref<AutomationRule | null>(null)

const openRuleDialog = () => {
  editingRule.value = null
  showRuleDialog.value = true
}

const openEditRuleDialog = (rule: AutomationRule) => {
  editingRule.value = rule
  showRuleDialog.value = true
}

const handleRuleSaved = async (ruleData: AutomationRuleFormData) => {
  // 保存逻辑
}
</script>

<template>
  <AutomationRuleDialog
    v-model:visible="showRuleDialog"
    :rule="editingRule"
    :projectId="parseInt(projectId)"
    :numericMetricOptions="numericMetricOptions"
    :stringMetricOptions="stringMetricOptions"
    :numericOperatorOptions="numericOperatorOptions"
    :stringOperatorOptions="stringOperatorOptions"
    :availableAccountNames="availableAccountNames"
    :availableCampaignNames="availableCampaignNames"
    :availableAdsetNames="availableAdsetNames"
    :availableAdNames="availableAdNames"
    @saved="handleRuleSaved"
  />
</template>
```

## 优点

1. **可复用性**: 组件可在其他页面使用
2. **可维护性**: 每个组件职责单一，易于理解和修改
3. **可测试性**: 组件可独立测试
4. **代码组织**: 主页面代码更简洁，专注于业务逻辑
5. **类型安全**: 导出的接口可在其他地方使用

## 技术实现说明

### ConditionGroupDisplay 使用 Template 语法

原本使用 Vue 的 `h` 函数和 `defineComponent` 来实现递归渲染，但可读性较差。现已改为使用 Template 语法：

**优点**:
- 更直观，易于阅读和维护
- 支持递归组件（组件在模板中调用自身）
- 更符合 Vue 3 的最佳实践
- 代码结构更清晰

**实现方式**:
```vue
<template>
  <div>
    <!-- 渲染条件 -->
    <div v-if="child.type === 'condition'">...</div>

    <!-- 递归渲染子条件组 -->
    <ConditionGroupDisplay
      v-else
      :group="child"
      :level="level + 1"
      ...
    />
  </div>
</template>
```

## 注意事项

1. `TriggerCondition` 接口现在从 `ConditionGroupDisplay.vue` 导出
2. 所有指标选项需要从父组件传递
3. 规则保存逻辑仍在父组件中处理
4. 对话框使用 `v-model:visible` 进行双向绑定
5. 所有组件都位于 `web/src/views/_dialogs/` 目录下

## 后续优化建议

1. 将指标选项配置提取为单独的文件
2. 考虑使用 provide/inject 减少 props 传递
3. 添加组件单元测试
4. 添加组件文档和使用示例
