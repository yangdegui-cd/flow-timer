class CreateBasicUser < ActiveRecord::Migration[7.1]
  def up
    # 创建基础角色
    SysUser.create!([
      {
        name: 'admin',
        email: 'admin@ft.com',
        password: '123456',
      }
    ])
    SysUserRole.create!([
      {
        sys_user_id: SysUser.where(name: 'admin').first.id,
        sys_role_id: SysRole.where(name: 'admin').first.id,
      }
    ])
  end

  def down
    SysRole.delete_all
    SysUserRole.delete_all
  end
end
