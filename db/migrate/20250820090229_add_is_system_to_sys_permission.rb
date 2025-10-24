class AddIsSystemToSysPermission < ActiveRecord::Migration[7.1]
  def change
    add_column :sys_permissions, :is_system, :boolean, null: false, default: false, comment: '是否系统权限'
    add_index :sys_permissions, :is_system
  end
end
