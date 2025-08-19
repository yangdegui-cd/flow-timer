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

# Auto-load job classes
Dir[Rails.root.join('app', 'jobs', '*.rb')].each { |file| require file }