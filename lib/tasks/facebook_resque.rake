namespace :facebook_resque do
  desc "测试Facebook Resque任务"
  task test: :environment do
    puts "=== 测试Facebook Resque任务 ==="

    # 检查Resque连接
    begin
      Resque.redis.ping
      puts "✅ Resque Redis连接正常"
    rescue => e
      puts "❌ Resque Redis连接失败: #{e.message}"
      exit 1
    end

    # 检查调度配置
    puts "\n📋 当前Resque调度配置:"
    Resque.schedule.each do |name, config|
      if name.include?('facebook')
        puts "- #{name}: #{config['description']}"
        puts "  cron: #{config['cron']}"
        puts "  class: #{config['class']}"
        puts "  queue: #{config['queue']}"
      end
    end

    # 手动入队一个Facebook令牌验证任务
    puts "\n🚀 手动入队Facebook令牌验证任务..."
    begin
      Resque.enqueue(FacebookTokenValidationJob, {})
      puts "✅ Facebook令牌验证任务已入队"
    rescue => e
      puts "❌ 任务入队失败: #{e.message}"
    end

    # 显示队列状态
    puts "\n📊 队列状态:"
    ['facebook_sync', 'facebook_cleanup', 'facebook_validation', 'default'].each do |queue|
      size = Resque.size(queue)
      puts "- #{queue}: #{size} 个任务等待处理"
    end

    puts "\n💡 提示:"
    puts "1. 启动worker处理任务: bundle exec rake resque:work QUEUE=*"
    puts "2. 启动scheduler处理定时任务: bundle exec rake resque:scheduler"
    puts "3. 访问Web UI: http://localhost:3000/resque"
  end

  desc "手动执行Facebook数据同步"
  task :sync_now, [:account_id] => :environment do |task, args|
    account_id = args[:account_id]

    if account_id.present?
      puts "手动同步Facebook账户: #{account_id}"
      Resque.enqueue(FacebookSyncJob, {
        'account_id' => account_id,
        'hourly' => true,
        'since' => 3.days.ago.strftime('%Y-%m-%d'),
        'until' => Date.current.strftime('%Y-%m-%d')
      })
    else
      puts "手动同步所有Facebook账户"
      Resque.enqueue(FacebookSyncJob, {
        'sync_all' => true,
        'hourly' => true,
        'since' => 3.days.ago.strftime('%Y-%m-%d'),
        'until' => Date.current.strftime('%Y-%m-%d')
      })
    end

    puts "✅ Facebook同步任务已入队"
    puts "队列状态: facebook_sync 队列有 #{Resque.size('facebook_sync')} 个任务"
  end

  desc "手动执行Facebook数据清理"
  task :cleanup_now, [:days] => :environment do |task, args|
    days = args[:days]&.to_i || 90

    puts "手动清理#{days}天前的Facebook数据"
    Resque.enqueue(FacebookCleanupJob, { 'days' => days })

    puts "✅ Facebook清理任务已入队"
    puts "队列状态: facebook_cleanup 队列有 #{Resque.size('facebook_cleanup')} 个任务"
  end

  desc "手动验证Facebook令牌"
  task validate_tokens_now: :environment do
    puts "手动验证Facebook API令牌"
    Resque.enqueue(FacebookTokenValidationJob, {})

    puts "✅ Facebook令牌验证任务已入队"
    puts "队列状态: facebook_validation 队列有 #{Resque.size('facebook_validation')} 个任务"
  end

  desc "清理所有Facebook相关队列"
  task clear_queues: :environment do
    puts "清理所有Facebook相关队列..."

    ['facebook_sync', 'facebook_cleanup', 'facebook_validation'].each do |queue|
      size = Resque.size(queue)
      if size > 0
        Resque.redis.del("queue:#{queue}")
        puts "✅ 已清理 #{queue} 队列的 #{size} 个任务"
      else
        puts "- #{queue} 队列为空"
      end
    end

    puts "队列清理完成"
  end
end