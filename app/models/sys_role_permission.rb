class SysRolePermission < ApplicationRecord
  # 关联关系
  belongs_to :sys_role
  belongs_to :sys_permission

  # 验证
  validates :sys_role_id, presence: true
  validates :sys_permission_id, presence: true
  validates :sys_role_id, uniqueness: { scope: :sys_permission_id }

  # 作用域
  scope :by_role, ->(role_id) { where(sys_role_id: role_id) }
  scope :by_permission, ->(permission_id) { where(sys_permission_id: permission_id) }
end