class SysUserProject < ApplicationRecord
  belongs_to :sys_user
  belongs_to :project

  validates :sys_user_id, uniqueness: { scope: :project_id }
  validates :role, inclusion: { in: %w[owner member viewer] }

  scope :owners, -> { where(role: 'owner') }
  scope :members, -> { where(role: 'member') }
  scope :viewers, -> { where(role: 'viewer') }
  scope :with_role, ->(role_name) { where(role: role_name) }
  scope :for_user, ->(user) { where(sys_user: user) }
  scope :for_project, ->(project) { where(project: project) }

  after_create :log_assignment
  after_destroy :log_removal
  after_update :log_role_change

  enum role: {
    owner: 'owner',
    member: 'member',
    viewer: 'viewer'
  }, _suffix: true

  def role_name
    case role
    when 'owner'
      '所有者'
    when 'member'
      '成员'
    when 'viewer'
      '查看者'
    else
      role
    end
  end

  def can_edit_project?
    owner? || member?
  end

  def can_manage_users?
    owner?
  end

  private

  def log_assignment
    Rails.logger.info "User #{sys_user.email} assigned to project #{project.name} as #{role}"
  end

  def log_removal
    Rails.logger.info "User #{sys_user.email} removed from project #{project.name}"
  end

  def log_role_change
    if saved_change_to_role?
      old_role, new_role = saved_change_to_role
      Rails.logger.info "User #{sys_user.email} role in project #{project.name} changed from #{old_role} to #{new_role}"
    end
  end
end