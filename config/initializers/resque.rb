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


Resque::Scheduler.dynamic = true

# The schedule doesn't need to be stored in a YAML, it just needs to
# be a hash.  YAML is usually the easiest.
Resque.schedule = YAML.load_file("#{Rails.root}/config/schedule.yml")

# Auto-load job classes
Dir[Rails.root.join('app', 'jobs', '*.rb')].each { |file| require file }
