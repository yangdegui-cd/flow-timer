# Facebook广告数据同步调度配置说明
#
# 本项目使用 Resque + Resque-Scheduler 来管理定时任务
# 调度配置已在 config/initializers/resque.rb 中定义

# ========================================
# Resque 调度任务说明
# ========================================

# 已配置的定时任务:
#
# 1. facebook_sync_all - 每4小时同步所有Facebook广告账户数据
#    cron: '0 */4 * * *'
#    class: FacebookSyncJob
#    args: { 'sync_all' => true, 'hourly' => true }
#
# 2. facebook_cleanup - 每周日凌晨3点清理90天前的数据
#    cron: '0 3 * * 0'
#    class: FacebookCleanupJob
#    args: { 'days' => 90 }
#
# 3. facebook_token_validation - 每天早上5点验证API令牌
#    cron: '0 5 * * *'
#    class: FacebookTokenValidationJob
#    args: {}

# ========================================
# 手动执行任务
# ========================================

# 在 Rails console 中手动执行任务:
#
# # 同步所有账户
# Resque.enqueue(FacebookSyncJob, { 'sync_all' => true, 'hourly' => true })
#
# # 同步指定账户
# Resque.enqueue(FacebookSyncJob, { 'account_id' => '1732112470254152', 'hourly' => true })
#
# # 清理过期数据
# Resque.enqueue(FacebookCleanupJob, { 'days' => 90 })
#
# # 验证令牌
# Resque.enqueue(FacebookTokenValidationJob, {})

# ========================================
# 启动 Resque 相关服务
# ========================================

# 启动 Resque worker (处理任务队列):
# QUEUE=* bundle exec rake resque:work
#
# 启动 Resque scheduler (处理定时任务):
# bundle exec rake resque:scheduler
#
# 后台运行:
# nohup bundle exec rake resque:work QUEUE=* > log/resque_worker.log 2>&1 &
# nohup bundle exec rake resque:scheduler > log/resque_scheduler.log 2>&1 &

# ========================================
# 监控 Resque 任务
# ========================================

# 访问 Resque Web UI:
# http://localhost:3000/resque
# 用户名: admin, 密码: admin (在生产环境请修改)

# ========================================
# 自定义调度配置
# ========================================

# 如果需要修改调度配置，可以在 config/initializers/resque.rb 中调整:
#
# Resque.schedule['facebook_sync_all'] = {
#   'cron' => '0 */2 * * *',  # 改为每2小时同步一次
#   'class' => 'FacebookSyncJob',
#   'args' => { 'sync_all' => true, 'hourly' => true },
#   'description' => '每2小时同步所有Facebook广告账户数据',
#   'queue' => 'facebook_sync'
# }

# ========================================
# 任务参数配置
# ========================================

# Facebook同步任务支持的参数:
# - sync_all: true/false (是否同步所有账户)
# - account_id: '账户ID' (同步指定账户)
# - since: '2024-01-01' (开始日期)
# - until: '2024-01-31' (结束日期)
# - level: 'campaign'/'adset'/'ad' (数据级别)
# - hourly: true/false (是否小时级别)
# - breakdowns: ['age', 'gender'] (维度分解)

# ========================================
# 生产环境部署
# ========================================

# 生产环境启动命令:
# RAILS_ENV=production bundle exec rake resque:work QUEUE=* > log/resque_worker.log 2>&1 &
# RAILS_ENV=production bundle exec rake resque:scheduler > log/resque_scheduler.log 2>&1 &

# 使用systemd服务管理 (推荐):
# 创建 /etc/systemd/system/ads-automate-worker.service
# 创建 /etc/systemd/system/ads-automate-scheduler.service

# ========================================
# 监控和日志
# ========================================

# 设置日志轮转 /etc/logrotate.d/ads-automate:
# /path/to/project/log/resque*.log {
#   daily
#   missingok
#   rotate 7
#   compress
#   notifempty
#   sharedscripts
# }

puts "Facebook广告数据同步已配置为Resque任务"
puts "请启动Resque worker和scheduler来处理任务"