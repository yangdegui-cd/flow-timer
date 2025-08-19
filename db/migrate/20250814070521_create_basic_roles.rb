class CreateBasicRoles < ActiveRecord::Migration[7.1]
  def up
    # 创建基础角色
    SysRole.create!([
      {
        name: 'admin',
        description: '系统管理员',
        permissions: [
          'manage_users',
          'manage_roles',
          'manage_tasks',
          'manage_flows',
          'manage_executions',
          'view_resque_monitor',
          'manage_system'
        ]
      },
      {
        name: 'developer',
        description: '开发者',
        permissions: [
          'view_tasks',
          'create_tasks',
          'edit_tasks',
          'delete_tasks',
          'view_flows',
          'create_flows',
          'edit_flows',
          'delete_flows',
          'view_executions',
          'manage_executions',
          'view_resque_monitor'
        ]
      },
      {
        name: 'operator',
        description: '运维人员',
        permissions: [
          'view_tasks',
          'view_flows',
          'view_executions',
          'manage_executions',
          'view_resque_monitor'
        ]
      },
      {
        name: 'viewer',
        description: '查看者',
        permissions: [
          'view_tasks',
          'view_flows',
          'view_executions'
        ]
      }
    ])
  end

  def down
    SysRole.delete_all
  end
end
