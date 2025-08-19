class SysUserRole < ApplicationRecord
  belongs_to :sys_user
  belongs_to :sys_role

  validates :sys_user_id, uniqueness: { scope: :sys_role_id }

  scope :with_role, ->(role_name) { joins(:sys_role).where(roles: { name: role_name }) }
  scope :active_users, -> { joins(:sys_user).where(users: { status: 'active' }) }

  after_create :log_role_assignment
  after_destroy :log_role_removal

  private

  def log_role_assignment
    Rails.logger.info "User #{sys_user.email} assigned role #{sys_role.name}"
  end

  def log_role_removal
    Rails.logger.info "User #{sys_user.email} removed from role #{sys_role.name}"
  end
end
