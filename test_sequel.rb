puts 'Testing MetaDatabase with Sequel adapter...'

# 创建测试数据库记录
db = MetaDatasource.create!(
  name: 'test_mysql',
  db_type: 'mysql',
  host: 'localhost',
  port: 3306,
  username: 'root',
  password: 'password',
  description: 'Test MySQL connection'
)

puts "Created database: #{db.name}"
puts "Database type: #{db.db_type}"

# 测试连接
puts 'Testing connection...'
begin
  result = db.test_connection
  puts "Connection test result: #{result}"
  puts "Database status: #{db.status}"
  puts "Test result: #{db.test_result}"
rescue => e
  puts "Connection test error: #{e.message}"
  puts "Error class: #{e.class.name}"
end

# 清理测试数据
db.destroy
puts 'Test database record destroyed'
