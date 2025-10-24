# Flow Timer Web 前端项目

## 项目介绍
Flow Timer 是一个基于 Vue 3 + TypeScript 的现代化任务流管理系统，提供任务执行、流程管理、用户权限管理等功能。

## 技术栈
- **前端框架**: Vue 3 + TypeScript + Composition API
- **UI 组件库**: PrimeVue 4
- **状态管理**: Pinia
- **路由管理**: Vue Router 4
- **构建工具**: Vite
- **样式**: Tailwind CSS

## 目录结构规范

### 目录组织
```
src/
├── api/                    # API 接口模块
├── components/             # 全局组件
├── data/                   # 数据相关
│   ├── constants/          # 常量定义
│   ├── types/              # TypeScript 类型定义
│   └── defaults/           # 默认数据对象
├── router/                 # 路由配置
├── stores/                 # Pinia 状态管理
├── styles/                 # 全局样式
├── utils/                  # 工具函数
└── views/                  # 页面组件
    ├── _dialogs/           # 对话框组件
    ├── _form/              # 表单组件
    ├── _tables/            # 表格组件
    ├── admin/              # 管理页面
    ├── layer/              # 布局组件
    └── sub-pages/          # 子页面
```

### 文件命名规范
- **Dialog组件**: 统一放在 `@/views/_dialogs/` 目录下，命名格式 `XxxDialog.vue`
- **Form组件**: 统一放在 `@/views/_form/` 目录下，命名格式 `XxxForm.vue`
- **Table组件**: 统一放在 `@/views/_tables/` 目录下，命名格式 `XxxList.vue`
- **常量文件**: 放在 `@/data/constants/` 目录下
- **类型定义**: 放在 `@/data/types/` 目录下
- **默认数据**: 放在 `@/data/defaults/` 目录下

## 代码规范

### 1. Vue 组件规范
- **组件结构顺序**: `<script setup>` 必须放在 `<template>` 上面，`<style>` 放在最后
  ```vue
  <script setup lang="ts">
  // 组件逻辑
  </script>

  <template>
    <!-- 模板内容 -->
  </template>

  <style scoped>
  /* 样式 */
  </style>
  ```
- 使用 `<script setup lang="ts">` 语法
- 合理使用 Composition API
- 组件导入使用 type-only 导入：`import type { ComponentType } from 'module'`
- **避免重复组件**: 相似功能的组件应该合并为一个可配置的组件，通过props控制不同模式

### 2. PrimeVue 组件规范
- FloatLabel 组件必须添加 `variant="on"` 属性
- 所有支持 `size` 属性的组件优先使用 `size="small"`，根据页面布局紧凑性决定
- Button 组件统一使用 `size="small"` 保持界面一致性
- 
### 3. API 调用规范
- 所有后端 API 接口统一放在 `@/api/` 目录下
- 不在页面组件中直接写 API 调用逻辑
- 推荐使用 Promise 语法而非 async/await：
```typescript
// 推荐写法
ApiList("ft_flow").then(data => {
  flow.value = data
}).catch(err => {
  console.error(err.msg)
})

// 注意：后端接口 code === 200 时直接返回 data，无需二次解构
```

### 4. 权限管理
- 使用 Pinia store 管理用户认证状态
- 基于 RBAC (Role-Based Access Control) 的权限控制
- 支持路由级别和组件级别的权限验证

### 5. 用户体系
- **认证方式**: 支持邮箱登录、GitHub OAuth、微信登录
- **角色系统**: 
  - admin: 系统管理员，拥有所有权限
  - developer: 开发人员，可管理任务和流程
  - operator: 操作员，可执行任务和查看监控
  - viewer: 查看者，只能查看数据
- **权限控制**: JSON 格式存储，支持细粒度权限配置

### 6. 关于弹出框

- 大部分的功能都有创建和编辑的功能. 这两个弹出框需要合并. 因为编辑内容大致是相同的.
- 弹出框的Vue需要单独提出到 /src/views/_dialogs


## 开发指南

### 本地开发
```bash
npm install
npm run dev
```

### 构建部署
```bash
npm run build
```

### 代码检查
```bash
npm run lint
npm run typecheck
```

## 详细文件功能说明

### 核心应用文件
- **App.vue** - 应用根组件，包含全局布局和路由出口
- **main.ts** - 应用入口文件，Vue实例创建和插件注册
- **request.ts** - HTTP 请求封装，统一的axios配置
- **vite-env.d.ts** - Vite 环境类型声明文件

### API 模块 (`/api/`)
- **auth-api.ts** - 用户认证相关API（登录、注册、OAuth）
- **user-api.ts** - 用户管理API（CRUD、角色分配、状态管理）
- **role-api.ts** - 角色管理API（角色CRUD、权限管理）
- **database-api.ts** - 数据库连接管理API（连接CRUD、测试、SQL执行）
- **base-api.ts** - 基础API封装（通用增删改查方法）
- **flow-api.ts** - 流程管理API（流程创建、编辑、执行）
- **task-execution-api.ts** - 任务执行API（任务监控、状态查询）
- **resque-monitor-api.ts** - 队列监控API（任务队列状态监控）

### 数据定义 (`/data/`)
- **type.ts** - 全局TypeScript类型定义
- **default-values.ts** - 默认数据对象和初始值
- **constants/** - 常量定义目录
  - **database-constants.ts** - 数据库相关常量（类型、状态、模板等）
  - **common-node-type-icon.ts** - 节点类型图标映射配置
- **types/** - 类型定义目录
  - **database-types.ts** - 数据库连接和SQL执行相关类型
- **defaults/** - 默认数据目录

### 路由配置 (`/router/`)
- **index.ts** - Vue Router配置，路由定义和导航守卫

### 状态管理 (`/stores/`)
- **auth.ts** - Pinia认证状态管理（用户信息、权限、登录状态）

### 工具函数 (`/utils/`)
- **clipboard.ts** - 剪贴板操作工具函数

### 样式文件 (`/styles/`)
- **index.css** - 全局样式和Tailwind CSS导入
- **layout.scss** - 布局相关样式
- **node.scss** - 流程节点样式
- **node-setting.scss** - 节点设置面板样式
- **icon.scss** - 图标样式

### 组件库 (`/components/`)

#### 管理后台组件 (`/components/admin/`)
- **UserManagementTab.vue** - 用户管理标签页（用户列表、操作）
- **RoleManagementTab.vue** - 角色管理标签页（角色列表、权限配置）
- **SystemStatsTab.vue** - 系统统计标签页
- **AuditLogsTab.vue** - 审计日志标签页

#### 流程编辑器组件
- **flow-edit.vue** - 流程编辑器主组件
- **SpecialNode.vue** - 特殊节点组件
- **SpecialEdge.vue** - 特殊连线组件
- **TaskExecutionStats.vue** - 任务执行统计组件

#### 数据库相关组件
- **SqlEditor.vue** - SQL编辑器组件（格式化、模板、全屏编辑）
- **DatabaseSelector.vue** - 数据库选择器（元数据连接/自定义连接）

#### 节点设置组件 (`/components/node-setting/`)
- **SettingColumn.vue** - 设置列组件
- **UploadCosSetting.vue** - COS上传设置
- **HostConfigSetting.vue** - 主机配置设置

#### 图标组件 (`/components/icon/`)
- **ga-icon.vue** - 通用图标组件
- **ga-icon.ts** - 图标类型定义

### 页面视图 (`/views/`)

#### 布局组件 (`/views/layer/`)
- **layout.vue** - 主布局组件（Header + Sidebar + Content）
- **sider.vue** - 侧边栏导航组件

#### 认证页面 (`/views/auth/`)
- **AuthPage.vue** - 认证页面容器（登录/注册切换）

#### 管理页面 (`/views/admin/`)
- **AdminManagement.vue** - 统一管理界面（用户+角色管理）

#### 用户页面 (`/views/sub-pages/user/`)
- **ProfilePage.vue** - 用户个人资料页面

#### 核心功能页面 (`/views/sub-pages/`)

##### 任务管理
- **task/Task.vue** - 任务列表页面
- **task/Edit.vue** - 任务编辑页面

##### 流程管理  
- **flow/Flow.vue** - 流程列表页面
- **flow/Edit.vue** - 流程编辑器页面

##### 执行监控
- **execution/Execution.vue** - 任务执行列表页面
- **monitoring/Monitoring.vue** - 系统监控面板
- **resque/ResqueMonitor.vue** - 队列监控页面

##### 元数据管理 (`/metadata/`)
- **Metadata.vue** - 元数据管理主页面
- **DatabaseList.vue** - SQL数据库源管理（支持多种数据库类型）
- **HostList.vue** - 主机列表管理
- **MysqlList.vue** - MySQL连接管理
- **HdfsList.vue** - HDFS连接管理
- **TrinoList.vue** - Trino连接管理

##### 其他页面
- **catalog/Catalog.vue** - 目录管理页面
- **setting/Settings.vue** - 系统设置页面

#### 对话框组件 (`/views/_dialogs/`)

##### 用户角色管理对话框
- **CreateUserDialog.vue** - 创建用户对话框
- **EditUserDialog.vue** - 编辑用户对话框
- **UserDetailDialog.vue** - 用户详情对话框
- **AssignRolesDialog.vue** - 分配角色对话框
- **CreateRoleDialog.vue** - 创建角色对话框
- **EditRoleDialog.vue** - 编辑角色对话框
- **RoleDetailDialog.vue** - 角色详情对话框
- **EditPermissionsDialog.vue** - 编辑权限对话框

##### 数据库管理对话框
- **CreateDatabaseDialog.vue** - 创建数据库连接对话框
- **EditDatabaseDialog.vue** - 编辑数据库连接对话框
- **DatabaseDetailDialog.vue** - 数据库连接详情对话框
- **SqlEditorDialog.vue** - SQL编辑器大屏对话框

##### 业务对话框
- **AddTask.vue** - 添加任务对话框
- **AddSpace.vue** - 添加空间对话框
- **AddCatalog.vue** - 添加目录对话框

#### 表单组件 (`/views/_form/`)
- **LoginForm.vue** - 登录表单（邮箱/GitHub/微信登录）
- **RegisterForm.vue** - 注册表单

#### 表格组件 (`/views/_tables/`)
- **TaskList.vue** - 任务列表表格
- **FlowList.vue** - 流程列表表格
- **TaskExecList.vue** - 任务执行列表表格

### 流程节点系统 (`/nodes/`)

#### 节点配置
- **nodes-menu.ts** - 节点菜单配置
- **nodes-setting.ts** - 节点设置配置
- **type.ts** - 节点类型定义
- **useDnD.ts** - 拖拽功能Hook

#### 节点设置文件 (`/nodes/setting/`)

##### 输入节点
- **input-mysql.ts** - MySQL输入节点配置
- **input-hdfs.ts** - HDFS输入节点配置
- **input-kafka.ts** - Kafka输入节点配置
- **input-file.ts** - 文件输入节点配置
- **input-cos.ts** - COS输入节点配置

##### 输出节点
- **output-mysql.ts** - MySQL输出节点配置
- **output-hdfs.ts** - HDFS输出节点配置
- **output-kafka.ts** - Kafka输出节点配置
- **output-file.ts** - 文件输出节点配置

##### 数据处理节点
- **data-filter.ts** - 数据过滤节点配置
- **data-merge.ts** - 数据合并节点配置
- **data-transition.ts** - 数据转换节点配置
- **data-order.ts** - 数据排序节点配置

##### 功能节点
- **ftp-transfer.ts** - FTP传输节点配置
- **upload-cos.ts** - COS上传节点配置
- **send-email.ts** - 邮件发送节点配置
- **flie-compress.ts** - 文件压缩节点配置
- **flow-params.ts** - 流程参数节点配置

##### 数据库操作节点
- **execute-sql.ts** - 执行SQL节点配置（支持多种数据库、连接测试、结果处理）

#### 节点视图组件 (`/nodes/view/`)
- **CommonNode.vue** - 通用节点视图组件
- **NodesMenu.vue** - 节点菜单组件

##### 节点设置界面 (`/nodes/view/setting/`)
- **SettingLayout.vue** - 设置布局组件
- **SettingColumn.vue** - 设置列组件
- **ParamsSetting.vue** - 参数设置组件
- **FlowConfigSetting.vue** - 流程配置设置
- **FtpTransferSetting.vue** - FTP传输设置
- **ExecuteSqlSetting.vue** - 执行SQL节点设置界面

### 静态资源 (`/assets/`)
- **vue.svg** - Vue.js 图标
- **svg/** - 业务图标库（节点图标、功能图标等）

## 待优化项目
- [ ] 集成图表组件 (Chart.js/ECharts) 用于监控页面
- [ ] 完善错误处理和用户反馈机制
- [ ] 添加单元测试覆盖
- [ ] 性能优化和代码分割

## 最近更新记录

### 2025-01-15 - 代码结构优化和规范化
8. ✅ **登录/注册页面丰富动画背景**
   - **多层渐变背景**: 深色基调 + 双层径向渐变叠加，色相轮换动画12s
   - **8个流体几何图形**: 不同尺寸彩色blob形状，独特动画模式：
     - 旋转漂浮、脉冲缩放、弹跳摇摆、自转漂移、轨道运动
     - 自定义border-radius创造有机形状
   - **40个发光粒子**: 白蓝渐变粒子，25s垂直漂浮，带光晕效果
   - **60个闪烁星星**: 随机分布，独立闪烁动画2-6s
   - **3条光束扫描**: 不同角度光线，8-12s垂直移动
   - **3个同心波纹**: 不同位置扩散消失效果，4-6s循环
   - **动态网格背景**: 半透明网格缓慢移动，50s循环
   - **表单入场动画**: 
     - 容器上滑淡入1.2s
     - 内容渐显0.3s延迟
     - Logo浮动+发光脉冲
     - 齿轮图标10s慢速旋转
   - **高对比度控件**: 输入框90%白色背景，蓝色聚焦边框
   - **响应式适配**: 移动端缩放70%，动画优化

9. ✅ **组件重构和代码规范**
   - **合并重复组件**: 将 `CreateDatabaseDialog.vue` 和 `EditDatabaseDialog.vue` 合并为 `DatabaseFormDialog.vue`
   - **统一组件接口**: 通过 `mode` prop 控制创建/编辑模式，减少代码重复
   - **Vue组件结构规范**: 强制 `<script setup>` 在 `<template>` 上面的标准结构
   - **组件复用原则**: 避免功能相似的重复组件，提高代码维护性

### 2025-01-15 - SQL数据库源和执行SQL节点功能
5. ✅ **SQL数据库源管理系统**
   - 支持8种数据库类型：MySQL, Oracle, Hive, PostgreSQL, MariaDB, Trino, ClickHouse, SQL Server
   - 数据库连接配置和管理（CRUD操作）
   - 连接测试和状态监控
   - 统一的数据库连接界面和详情展示

6. ✅ **执行SQL节点功能**
   - 双连接模式：元数据连接 + 自定义连接
   - 动态数据库/Catalog/Schema选择（支持Trino多catalog）
   - 高级SQL编辑器：语法高亮、格式化、模板、全屏编辑
   - SQL执行配置：超时设置、行数限制、结果格式配置
   - 执行结果处理：JSON/CSV/Table格式输出
   - 节点配置验证和预检功能

7. ✅ **相关基础设施**
   - 新增 `/metadata/databases` 路由和页面
   - 节点菜单新增"数据库操作"分类
   - 完整的类型定义和常量配置
   - 可复用的数据库选择器和SQL编辑器组件

### 2025-01-15 - 用户认证和代码标准化
1. ✅ 完成用户认证系统集成 (邮箱/GitHub/微信登录)
2. ✅ 实现基于角色的权限控制系统
3. ✅ 统一管理界面 (用户管理 + 角色管理)
4. ✅ 代码结构标准化
    - Dialog 组件迁移到 `/views/_dialogs/`
    - 删除冗余文件 (UserManagement.vue, RoleManagement.vue, TaskExecList.vue)
    - 统一 Button 组件 size 属性
    - 创建标准化目录结构 (/data/constants/, /data/types/, /data/defaults/)


