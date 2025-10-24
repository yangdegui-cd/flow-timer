# Flow Timer - 流程化任务管理工具

一个基于Rails的工作流程和任务管理系统，支持流程版本控制、任务调度和参数化配置。

## 技术栈
- Rails 7.1.5
- Ruby 3.0.0  
- MySQL数据库
- Puma web server

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
