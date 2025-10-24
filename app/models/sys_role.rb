class SysRole < ApplicationRecord
  has_many :sys_user_roles, dependent: :destroy
  has_many :sys_users, through: :sys_user_roles

  # 新的权限关联
  has_many :sys_role_permissions, dependent: :destroy
  has_many :sys_permissions, through: :sys_role_permissions

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9_]+\z/ }, if: :code_present?
  validates :sort_order, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_code_from_name, if: :new_record?
  before_save :set_defaults

  scope :ordered, -> { order(:sort_order, :name) }
  scope :active, -> { where(is_active: true) }
  scope :system, -> { where(is_system: true) }
  scope :custom, -> { where(is_system: false) }


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

  def has_permission?(permission_code)
    sys_permissions.active.where(code: permission_code).exists?
  end

  # 分配权限
  def assign_permissions(permission_ids: [])
    transaction do
      # 清空现有权限关联
      sys_role_permissions.destroy_all

      # 添加直接权限
      if permission_ids.present?
        valid_permission_ids = SysPermission.where(id: permission_ids).pluck(:id)
        valid_permission_ids.each do |permission_id|
          sys_role_permissions.create!(sys_permission_id: permission_id)
        end
      end
    end
    true
  rescue StandardError => e
    Rails.logger.error "分配权限失败: #{e.message}"
    false
  end

  # 权限统计信息
  def permission_stats
    {
      direct_permissions_count: sys_permissions.active.count
    }
  end

  def can_delete?
    !is_system? && sys_users.empty?
  end

  def can_edit?
    !is_system?
  end

  def users_count
    sys_users.count
  end

  private

  def set_defaults
    self.is_active = true if is_active.nil?
    self.sort_order = 0 if sort_order.nil?
  end

  def code_present?
    code.present?
  end

  def set_code_from_name
    self.code = name.parameterize.underscore if name.present? && code.blank?
  end
end
