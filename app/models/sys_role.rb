class SysRole < ApplicationRecord
  has_many :sys_user_roles, dependent: :destroy
  has_many :sys_users, through: :user_roles

  validates :name, presence: true, uniqueness: true
  validates :permissions, presence: true

  before_save :ensure_permissions_array

  scope :ordered, -> { order(:name) }

  # 系统预定义角色
  SYSTEM_ROLES = %w[admin developer operator viewer].freeze

  def self.admin
    find_by(name: 'admin')
  end

  def self.developer
    find_by(name: 'developer')
  end

  def self.operator
    find_by(name: 'operator')
  end

  def self.viewer
    find_by(name: 'viewer')
  end

  def display_name
    case name
    when 'admin' then '系统管理员'
    when 'developer' then '开发者'
    when 'operator' then '运维人员'
    when 'viewer' then '查看者'
    else description || name.humanize
    end
  end

  def system_role?
    SYSTEM_ROLES.include?(name)
  end

  def has_permission?(permission)
    permissions.include?(permission.to_s)
  end

  def add_permission(permission)
    return false if has_permission?(permission)

    update(permissions: permissions + [permission.to_s])
  end

  def remove_permission(permission)
    return false unless has_permission?(permission)

    update(permissions: permissions - [permission.to_s])
  end

  def permission_list
    permissions.join(', ')
  end

  # 获取所有可用权限
  def self.available_permissions
    [
      'manage_users',      # 管理用户
      'manage_roles',      # 管理角色
      'manage_tasks',      # 管理任务
      'manage_flows',      # 管理流程
      'manage_executions', # 管理执行
      'view_resque_monitor', # 查看队列监控
      'manage_system',     # 系统管理
      'view_tasks',        # 查看任务
      'create_tasks',      # 创建任务
      'edit_tasks',        # 编辑任务
      'delete_tasks',      # 删除任务
      'view_flows',        # 查看流程
      'create_flows',      # 创建流程
      'edit_flows',        # 编辑流程
      'delete_flows',      # 删除流程
      'view_executions'    # 查看执行记录
    ]
  end

  def self.permission_descriptions
    {
      'manage_users' => '管理用户账户',
      'manage_roles' => '管理角色权限',
      'manage_tasks' => '管理任务配置',
      'manage_flows' => '管理流程定义',
      'manage_executions' => '管理任务执行',
      'view_resque_monitor' => '查看队列监控',
      'manage_system' => '系统配置管理',
      'view_tasks' => '查看任务列表',
      'create_tasks' => '创建新任务',
      'edit_tasks' => '编辑任务配置',
      'delete_tasks' => '删除任务',
      'view_flows' => '查看流程列表',
      'create_flows' => '创建新流程',
      'edit_flows' => '编辑流程定义',
      'delete_flows' => '删除流程',
      'view_executions' => '查看执行记录'
    }
  end

  private

  def ensure_permissions_array
    self.permissions = [] if permissions.nil?
    self.permissions = permissions.compact.uniq if permissions.is_a?(Array)
  end
end
