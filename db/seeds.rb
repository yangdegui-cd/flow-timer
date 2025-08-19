# 创建默认管理员账号
admin_email = 'admin@flow-timer.com'
admin_password = '123456'

# 检查是否已存在admin账号
admin_user = SysUser.find_by(email: admin_email)

if admin_user.nil?
  # 创建admin角色（如果不存在）
  admin_role = SysRole.find_or_create_by(name: 'admin') do |role|
    role.display_name = '系统管理员'
    role.description = '拥有系统所有权限的超级管理员'
    role.permissions = [
      'manage_users', 'manage_roles', 'manage_tasks', 'manage_flows',
      'manage_executions', 'view_resque_monitor', 'manage_system',
      'view_tasks', 'create_tasks', 'edit_tasks', 'delete_tasks',
      'view_flows', 'create_flows', 'edit_flows', 'delete_flows',
      'view_executions'
    ]
    role.system_role = true
  end

  # 创建admin用户
  admin_user = SysUser.create!(
    email: admin_email,
    password: admin_password,
    password_confirmation: admin_password,
    name: '系统管理员',
    status: 'active'
  )

  # 给admin用户分配admin角色
  admin_user.roles << admin_role unless admin_user.roles.include?(admin_role)

  puts "创建默认管理员账号成功："
  puts "邮箱: #{admin_email}"
  puts "密码: #{admin_password}"
else
  # 重置admin用户的密码为默认密码
  admin_user.update!(
    password: admin_password,
    password_confirmation: admin_password
  )

  puts "重置管理员账号密码成功："
  puts "邮箱: #{admin_email}"
  puts "密码: #{admin_password}"
end

puts "管理员账号信息："
puts "- 邮箱: #{admin_user.email}"
puts "- 姓名: #{admin_user.name}"
puts "- 状态: #{admin_user.status}"
puts "- 角色: #{admin_user.roles.map(&:display_name).join(', ')}"
