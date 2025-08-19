# Flow Timer - 流程化任务管理工具

一个基于Rails的工作流程和任务管理系统，支持流程版本控制、任务调度和参数化配置。

## 技术栈
- Rails 7.1.5
- Ruby 3.0.0  
- MySQL数据库
- Puma web server

## 核心概念

### Space (空间)
组织结构的顶层容器，分为两种类型：
- **FLOW**: 流程空间，用于管理工作流程
- **TASK**: 任务空间，用于管理具体任务

### Catalog (目录)
空间下的分类目录，用于组织和分类流程或任务。

### FtFlow (流程)
具体的工作流程定义，包含以下特性：
- 唯一的flow_id标识
- 版本管理支持
- 参数化配置
- 状态管理（draft等）
- 与目录的关联

### FtFlowVersion (流程版本)
流程的版本控制系统：
- 每个流程可有多个版本
- 存储JSON格式的flow_config配置
- 支持版本递增

### FtTask (任务)
流程中的具体执行单元：
- 支持定时执行（cron表达式）
- 任务类型和状态管理
- 优先级和队列支持
- 生效时间控制
- 参数配置

## 数据库结构

```
spaces (空间)
├── catalogs (目录)
    ├── ft_flows (流程)
    │   └── ft_flow_versions (流程版本)
    └── ft_tasks (任务)
```

## 主要功能

1. **流程管理**
   - 创建和管理工作流程
   - 流程版本控制
   - 流程参数配置
   - 流程树形结构展示

2. **任务调度**
   - 支持cron表达式的定时任务
   - 任务优先级管理
   - 任务队列支持
   - 任务状态跟踪

3. **组织结构**
   - 分层的空间-目录-流程/任务结构
   - 灵活的分类管理
   - 默认空间和目录自动创建

4. **参数化配置**
   - 流程支持动态参数
   - JSON格式存储配置
   - 参数提取和验证

## API端点

- `GET /ft_flows` - 获取流程列表
- `POST /ft_flows` - 创建新流程
- `GET /ft_flows/:id/current_version` - 获取流程当前版本
- `GET /ft_flows/get_tree_list` - 获取流程树形结构

## 项目结构

```
app/
├── controllers/
│   ├── ft_flow_controller.rb      # 流程控制器
│   ├── ft_task_controller.rb      # 任务控制器
│   └── space_controller.rb        # 空间控制器
├── models/
│   ├── ft_flow.rb                 # 流程模型
│   ├── ft_flow_version.rb         # 流程版本模型
│   ├── ft_task.rb                 # 任务模型
│   ├── space.rb                   # 空间模型
│   └── catalog.rb                 # 目录模型
```

## 开发环境设置

1. Ruby版本: 3.0.0
2. 数据库: MySQL
3. 安装依赖: `bundle install`
4. 数据库设置: `rails db:create db:migrate`
5. 启动服务器: `rails server`

## 使用场景

适用于需要流程化管理任务的场景：
- 工作流程管理
- 定时任务调度
- 业务流程自动化
- 任务编排和执行
