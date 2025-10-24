class Project < ApplicationRecord
  has_many :sys_user_projects, dependent: :destroy
  has_many :sys_users, through: :sys_user_projects
  has_many :ads_accounts, dependent: :destroy
  has_many :automation_rules, dependent: :destroy
  has_many :automation_logs, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :active_ads_automate, inclusion: { in: [true, false] }
  validates :status, inclusion: { in: %w[active inactive archived] }

  scope :active, -> { where(active_ads_automate: true) }
  scope :inactive, -> { where(active_ads_automate: false) }
  scope :by_status, ->(status) { where(status: status) }

  enum status: {
    active: 'active',
    inactive: 'inactive',
    archived: 'archived'
  }, _suffix: true

  def active_ads_automate?
    active_ads_automate
  end

  def user_count
    sys_users.count
  end

  def owners
    sys_users.joins(:sys_user_projects).where(sys_user_projects: { role: 'owner' })
  end

  def members
    sys_users.joins(:sys_user_projects).where(sys_user_projects: { role: 'member' })
  end

  def viewers
    sys_users.joins(:sys_user_projects).where(sys_user_projects: { role: 'viewer' })
  end

  def user_role(user)
    sys_user_projects.find_by(sys_user: user)&.role
  end

  def add_user(user, role = 'member')
    sys_user_projects.find_or_create_by(sys_user: user) do |user_project|
      user_project.role = role
      user_project.assigned_at = Time.current
    end
  end

  def remove_user(user)
    sys_user_projects.where(sys_user: user).destroy_all
  end
end