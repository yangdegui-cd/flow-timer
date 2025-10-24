# 用户操作日志系统

## 概述
Flow Timer系统集成了完整的用户操作日志记录功能，自动跟踪所有用户的API请求操作，记录详细的访问信息和响应数据。

## 功能特性

### 自动日志记录
- **请求信息**: Controller、Action、HTTP方法、URL、参数
- **时间追踪**: 请求开始时间、响应结束时间、请求耗时（毫秒）
- **用户信息**: 操作用户、IP地址、User Agent
- **响应信息**: HTTP状态码、错误信息（如果有）
- **参数记录**: URL参数和请求体参数（JSON格式存储）

### 日志管理功能
- **权限控制**: 管理员可查看所有日志，普通用户只能查看自己的日志
- **多维度筛选**: 用户、控制器、动作、请求方法、状态码、时间范围
- **统计分析**: 请求统计、错误统计、慢请求统计、用户活跃度
- **日志清理**: 支持按时间清理旧日志记录

## 数据库结构

### sys_logs 表
```sql
CREATE TABLE sys_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL COMMENT '用户ID',
  controller_name VARCHAR(100) NOT NULL COMMENT '控制器名称',
  action_name VARCHAR(50) NOT NULL COMMENT '动作名称',
  request_method VARCHAR(10) NOT NULL COMMENT '请求方法',
  request_url VARCHAR(500) NOT NULL COMMENT '请求URL',
  url_params TEXT COMMENT 'URL参数 JSON格式',
  body_params TEXT COMMENT '请求体参数 JSON格式',
  request_time DATETIME NOT NULL COMMENT '请求开始时间',
  response_time DATETIME COMMENT '响应结束时间',
  duration INT COMMENT '请求耗时(毫秒)',
  status_code INT COMMENT 'HTTP状态码',
  ip_address VARCHAR(45) COMMENT '客户端IP地址',
  user_agent VARCHAR(500) COMMENT '用户代理',
  error_message TEXT COMMENT '错误信息',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
```

### 索引优化
- `user_id`: 用户查询索引
- `[controller_name, action_name]`: 控制器动作复合索引
- `request_time`: 时间范围查询索引
- `request_method`: 请求方法索引
- `status_code`: 状态码索引
- `ip_address`: IP地址索引

## API 接口

### 获取日志列表（管理员）
```
GET /sys_log
```

查询参数：
- `user_id`: 用户ID筛选
- `controller_name`: 控制器筛选
- `action_name`: 动作筛选
- `request_method`: 请求方法筛选
- `status_code`: 状态码筛选
- `start_date`: 开始时间
- `end_date`: 结束时间
- `errors_only`: 只显示错误请求
- `slow_requests`: 只显示慢请求
- `slow_threshold`: 慢请求阈值（毫秒）
- `page`: 页码
- `per_page`: 每页数量

### 获取当前用户日志
```
GET /sys_log/my_logs
```

### 获取单个日志详情
```
GET /sys_log/:id
```

### 获取日志统计
```
GET /sys_log/stats
```

返回数据包括：
- 总请求数、今日请求数、本周请求数
- 错误请求数、慢请求数
- 按控制器、状态码、用户的统计
- 按小时的请求分布（今日）

### 清理旧日志
```
POST /sys_log/cleanup
```
参数：
- `days`: 保留天数（默认30天）

## 模型功能

### SysLog模型
位置：`app/models/sys_log.rb`

#### 关联关系
```ruby
belongs_to :user, class_name: 'SysUser'
```

#### 作用域查询
```ruby
# 最近日志
SysLog.recent

# 按用户筛选
SysLog.by_user(user_id)

# 按控制器筛选
SysLog.by_controller('sys_user')

# 按动作筛选
SysLog.by_action('create')

# 按请求方法筛选
SysLog.by_method('POST')

# 按状态码筛选
SysLog.by_status(200)

# 错误请求
SysLog.errors

# 慢请求
SysLog.slow_requests(1000)  # 超过1000ms

# 时间范围
SysLog.today
SysLog.this_week
```

#### 实用方法
```ruby
# JSON参数处理
log.url_params_hash    # 解析URL参数
log.body_params_hash   # 解析请求体参数

# 格式化显示
log.formatted_duration # "500ms" 或 "1.2s"
log.action_description # "POST sys_user#create"

# 状态判断
log.error?             # 是否错误请求
log.slow?(1000)        # 是否慢请求
```

## 自动记录机制

### ApplicationController集成
位置：`app/controllers/application_controller.rb`

使用before_action和after_action自动记录所有API请求：

```ruby
before_action :record_action
after_action :record_action_end
```

### 记录逻辑
1. **请求开始**（`record_action`）:
   - 记录开始时间
   - 创建SysLog实例
   - 保存请求基本信息

2. **请求结束**（`record_action_end`）:
   - 计算请求耗时
   - 记录响应状态码
   - 保存错误信息（如果有）
   - 持久化日志记录

### 排除规则
不记录日志的控制器：
- `application`: 应用基础控制器
- `health_check`: 健康检查
- `sys_logs`: 日志查询本身
- `auth`: 认证相关（可配置）

不记录日志的动作：
- 可在 `skip_logging_actions` 方法中配置

### 异常处理
- 使用`rescue_from StandardError`统一处理异常
- 异常信息记录到`error_message`字段
- 日志记录失败不影响正常请求处理

## 配置选项

### 跳过日志记录
在ApplicationController中修改：

```ruby
def skip_logging_controllers
  %w[application health_check sys_logs auth]
end

def skip_logging_actions
  %w[show index]  # 可添加不需要记录的动作
end
```

### 性能考虑
- 日志记录异步化处理，不阻塞正常请求
- 使用数据库索引优化查询性能
- 支持定期清理历史日志
- 错误处理确保日志记录失败不影响业务

## 使用示例

### 查询用户操作历史
```ruby
# 获取特定用户今天的所有操作
logs = SysLog.by_user(user.id).today

# 获取创建用户的操作记录
create_logs = SysLog.by_controller('sys_user').by_action('create')

# 获取所有错误请求
error_logs = SysLog.errors.recent.limit(50)
```

### 统计分析
```ruby
# 今日请求统计
today_stats = {
  total: SysLog.today.count,
  errors: SysLog.today.errors.count,
  slow: SysLog.today.slow_requests.count
}

# 用户活跃度
active_users = SysLog.today
                    .joins(:user)
                    .group('sys_users.name')
                    .count
```

## 权限说明

### sys_log 权限
- `sys_log:read` - 查看日志
- `sys_log:write` - 管理日志（清理等）

### 访问控制
- **管理员**：可查看所有日志、获取统计、清理日志
- **普通用户**：只能查看自己的操作日志（`my_logs`）

## 注意事项

1. **敏感信息过滤**：系统会记录所有请求参数，请注意不要在URL或请求体中传递敏感信息
2. **存储空间**：日志记录会持续增长，建议定期清理或归档
3. **性能影响**：大量日志查询可能影响性能，建议使用合适的筛选条件
4. **权限控制**：确保只有授权用户能访问日志信息

## 扩展功能

未来可考虑的扩展：
- 日志数据可视化
- 实时监控告警
- 日志导出功能
- 操作审计报告
- 异常行为检测