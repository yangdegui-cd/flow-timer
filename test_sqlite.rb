puts 'Testing SQLite connection with Sequel adapter...'

# 创建测试 SQLite 数据库记录
db = MetaDatasource.create!(
  name: 'test_sqlite',
  db_type: 'sqlite',
  host: 'localhost',  # SQLite 不需要，但字段是必需的
  port: 3306,         # SQLite 不需要，但字段是必需的
  username: 'test',   # SQLite 不需要，但字段是必需的
  password: 'test',   # SQLite 不需要，但字段是必需的
  description: 'Test SQLite connection',
  extra_config: { 'database_path' => '/tmp/test.db' }
)

puts "Created database: #{db.name}"
puts "Database type: #{db.db_type}"

# 测试连接
puts 'Testing SQLite connection...'
begin
  result = db.test_connection
  puts "Connection test result: #{result}"
  puts "Database status: #{db.status}"
  puts "Test result: #{db.test_result}"

  if result
    puts "Discovered databases: #{db.extra_config&.dig('discovered_databases')}"
  end
rescue => e
  puts "Connection test error: #{e.message}"
  puts "Error class: #{e.class.name}"
  puts "Backtrace:"
  puts e.backtrace.first(5)
end

# 清理测试数据
db.destroy
puts 'Test database record destroyed'

# 清理测试文件
File.delete('/tmp/test.db') if File.exist?('/tmp/test.db')
puts 'Test SQLite file removed'
