class SysPermission < ApplicationRecord

  # 验证
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9_:]+\z/ }
  validates :name, presence: true, length: { maximum: 100 }
  validates :module, presence: true, length: { maximum: 50 }
  validates :action, presence: true, length: { maximum: 20 }
  validates :resource, length: { maximum: 200 }, allow_blank: true
  validates :sort_order, numericality: { greater_than_or_equal_to: 0 }

  # 关联关系
  has_many :sys_role_permissions, dependent: :destroy
  has_many :sys_roles, through: :sys_role_permissions

  # 回调
  before_validation :normalize_code
  before_save :set_defaults

  # 作用域
  scope :active, -> { where(is_active: true) }
  scope :system, -> { where(is_system: true) }
  scope :custom, -> { where(is_system: false) }
  scope :by_module, ->(module_name) { where(module: module_name) }
  scope :by_action, ->(action) { where(action: action) }
  scope :ordered, -> { order(:sort_order, :id) }

  # 类方法
  def self.modules
    distinct.pluck(:module).compact.sort
  end

  def self.actions
    distinct.pluck(:action).compact.sort
  end

  def self.by_module_grouped
    active.ordered.group_by(&:module)
  end

  def self.search(query)
    return all if query.blank?

    where("code LIKE ? OR name LIKE ? OR description LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  end

  # 实例方法
  def full_name
    "#{self.module}:#{action}"
  end

  def display_name
    "#{name} (#{code})"
  end

  def can_delete?
    sys_role_permissions.empty?
  end

  # 权限检查
  def self.user_has_permission?(user_id, permission_code)
    return false unless user_id && permission_code

    # 通过直接角色权限检查
    direct_permission = joins(sys_roles: { sys_user_roles: :sys_user })
                       .where(sys_users: { id: user_id })
                       .where(code: permission_code)
                       .exists?

    return true if direct_permission
  end

  # 批量创建系统权限
  def self.sync_system_permissions(permissions_config)
    return 0 if permissions_config.blank?
    
    created_count = 0
    updated_count = 0
    
    transaction do
      permissions_config.each do |perm_config|
        permission = find_or_initialize_by(code: perm_config[:code])
        is_new = permission.new_record?
        
        permission.assign_attributes(
          name: perm_config[:name],
          description: perm_config[:description],
          module: perm_config[:module],
          action: perm_config[:action],
          resource: perm_config[:resource],
          is_active: perm_config.fetch(:is_active, true),
          is_system: perm_config.fetch(:is_system, false),
          sort_order: perm_config.fetch(:sort_order, 0)
        )
        
        if permission.save
          is_new ? created_count += 1 : updated_count += 1
        end
      end
    end
    
    Rails.logger.info "权限同步完成: 新增 #{created_count}, 更新 #{updated_count}"
    created_count + updated_count
  end

  # 获取模块统计信息
  def self.module_stats
    active.group(:module).group(:action).count.each_with_object({}) do |((mod, action), count), hash|
      hash[mod] ||= { total: 0, actions: {} }
      hash[mod][:total] += count
      hash[mod][:actions][action] = count
    end
  end

  private

  def normalize_code
    self.code = code.strip.downcase if code.present?
  end

  def set_defaults
    self.is_active = true if is_active.nil?
    self.is_system = false if is_system.nil?
    self.sort_order = 0 if sort_order.nil?
  end
end
