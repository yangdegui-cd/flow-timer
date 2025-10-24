class CreateSysPermissionsSystem < ActiveRecord::Migration[7.1]
  def change
    # 创建权限表
    create_table :sys_permissions do |t|
      t.string :code, null: false, limit: 100, comment: '权限标识'
      t.string :name, null: false, limit: 100, comment: '权限名称'
      t.text :description, comment: '权限描述'
      t.string :module, null: false, limit: 50, comment: '所属模块'
      t.string :action, null: false, limit: 20, comment: '操作类型'
      t.string :resource, limit: 200, comment: '资源标识'
      t.boolean :is_active, null: false, default: true, comment: '是否启用'
      t.integer :sort_order, null: false, default: 0, comment: '排序'

      t.timestamps
    end

    add_index :sys_permissions, :code, unique: true
    add_index :sys_permissions, :module
    add_index :sys_permissions, :is_active

    # 为现有 sys_roles 表添加新字段
    add_column :sys_roles, :code, :string, limit: 100, after: :id
    add_column :sys_roles, :is_system, :boolean, null: false, default: false, comment: '是否系统角色'
    add_column :sys_roles, :is_active, :boolean, null: false, default: true, comment: '是否启用'
    add_column :sys_roles, :sort_order, :integer, null: false, default: 0, comment: '排序'
    remove_column :sys_roles, :permissions

    add_index :sys_roles, :code, unique: true
    add_index :sys_roles, :is_system
    add_index :sys_roles, :is_active

    # 创建角色权限关联表（直接权限）
    create_table :sys_role_permissions do |t|
      t.references :sys_role, null: false, foreign_key: true
      t.references :sys_permission, null: false, foreign_key: true
      t.timestamps
    end

    add_index :sys_role_permissions, [:sys_role_id, :sys_permission_id], unique: true, name: 'idx_unique_role_permission'
  end

  def down
    drop_table :sys_role_permissions
    drop_table :sys_permissions

    remove_column :sys_roles, :code
    remove_column :sys_roles, :is_system
    remove_column :sys_roles, :is_active
    remove_column :sys_roles, :sort_order
  end
end
