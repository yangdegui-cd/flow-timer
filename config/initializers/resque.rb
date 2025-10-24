require 'resque'
require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'

# Configure Resque Web UI
Resque::Server.use Rack::Auth::Basic do |username, password|
  # Simple auth for resque web interface
  # In production, use proper authentication
  username == 'admin' && password == 'admin'
end

# Redis configuration
redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
Resque.redis = Redis.new(url: redis_url)
Resque.redis.namespace = 'flow_timer'

# Enable verbose logging for debugging
Resque.logger = Rails.logger
Resque.logger.level = Logger::INFO

# Resque Scheduler configuration
Resque::Scheduler.configure do |c|
  c.quiet = false
  c.verbose = true
  c.logfile = Rails.root.join('log', 'resque_scheduler.log')
  c.logformat = 'text'
  c.poll_sleep_amount = 5.0
end

# Set the schedule
Resque.schedule = {} unless Resque.schedule

# Facebook广告数据同步调度配置
Resque.schedule['facebook_sync_all'] = {
  'cron' => '0 */4 * * *',  # 每4小时同步一次
  'class' => 'FacebookSyncJob',
  'args' => { 'sync_all' => true, 'hourly' => true },
  'description' => '每4小时同步所有Facebook广告账户数据',
  'queue' => 'facebook_sync'
}

# Facebook广告数据清理调度
Resque.schedule['facebook_cleanup'] = {
  'cron' => '0 3 * * 0',  # 每周日凌晨3点
  'class' => 'FacebookCleanupJob',
  'args' => { 'days' => 90 },
  'description' => '每周清理90天前的Facebook广告数据',
  'queue' => 'facebook_cleanup'
}

# Facebook令牌验证调度
Resque.schedule['facebook_token_validation'] = {
  'cron' => '0 5 * * *',  # 每天早上5点
  'class' => 'FacebookTokenValidationJob',
  'args' => {},
  'description' => '每天验证Facebook API访问令牌',
  'queue' => 'facebook_validation'
}

# Auto-load job classes
Dir[Rails.root.join('app', 'jobs', '*.rb')].each { |file| require file }