class SysUser < ApplicationRecord
  has_secure_password validations: false

  has_many :sys_user_roles, dependent: :destroy
  has_many :sys_roles, through: :sys_user_roles
  has_many :sys_oauth_providers, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :status, inclusion: { in: %w[active inactive suspended] }

  # 如果有密码则验证密码
  validates :password, length: { minimum: 6 }, if: :password_digest_changed?

  before_save :downcase_email

  scope :active, -> { where(status: 'active') }

  enum status: {
    active: 'active',
    inactive: 'inactive',
    suspended: 'suspended'
  }, _suffix: true

  def full_name
    name
  end

  def initials
    name.split.map(&:first).join.upcase
  end

  def admin?
    has_role?('admin')
  end

  def has_role?(role_name)
    sys_roles.exists?(name: role_name)
  end

  def has_permission?(permission)
    sys_roles.where("JSON_CONTAINS(permissions, ?)", "\"#{permission}\"").exists?
  end

  def permissions
    sys_roles.pluck(:permissions).flatten.uniq
  end

  def add_role(role_name)
    role = SysRole.find_by(name: role_name)
    return false unless role

    sys_user_roles.find_or_create_by(sys_role: role)
    true
  end

  def remove_role(role_name)
    role = SysRole.find_by(name: role_name)
    return false unless role

    sys_user_roles.where(sys_role: role).destroy_all
    true
  end

  def update_last_login!
    update!(last_login_at: Time.current)
  end

  def oauth_connected?(provider)
    sys_oauth_providers.exists?(provider: provider)
  end

  def oauth_provider_data(provider)
    sys_oauth_providers.find_by(provider: provider)
  end

  def create_or_update_oauth_provider!(provider, uid, auth_data)
    oauth_provider = sys_oauth_providers.find_or_initialize_by(provider: provider)
    oauth_provider.assign_attributes(
      uid: uid,
      access_token: auth_data[:credentials]&.[](:token),
      refresh_token: auth_data[:credentials]&.[](:refresh_token),
      expires_at: auth_data[:credentials]&.[](:expires_at)&.then { |ts| Time.at(ts) },
      extra_data: auth_data[:extra] || {}
    )
    oauth_provider.save!
    oauth_provider
  end

  # 查找或创建OAuth用户
  def self.find_or_create_by_oauth(auth_data)
    provider = auth_data[:provider]
    uid = auth_data[:uid]

    # 先通过OAuth提供商查找
    oauth_provider = SysOauthProvider.find_by(provider: provider, uid: uid)
    if oauth_provider
      user = oauth_provider.sys_user
      user.create_or_update_oauth_provider!(provider, uid, auth_data)
      return user
    end

    # 通过邮箱查找已存在用户
    email = auth_data.dig(:info, :email)
    user = SysUser.find_by(email: email) if email.present?

    if user
      # 关联OAuth账号到现有用户
      user.create_or_update_oauth_provider!(provider, uid, auth_data)
    else
      # 创建新用户
      user = SysUser.create!(
        email: email || "#{provider}_#{uid}@flow-timer.local",
        name: auth_data.dig(:info, :name) || auth_data.dig(:info, :login) || "用户#{uid}",
        avatar_url: auth_data.dig(:info, :image) || auth_data.dig(:info, :avatar_url)
      )

      # 添加默认角色
      user.add_role('viewer')

      # 创建OAuth关联
      user.create_or_update_oauth_provider!(provider, uid, auth_data)
    end

    user
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
