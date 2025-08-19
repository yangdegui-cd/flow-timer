class MetaHost < ApplicationRecord
  # 关联关系
  belongs_to :catalog, optional: true

  self.create_fields = %w[name description hostname port username password ssh_key auth_type environment tags notes sort created_by catalog_id]
  self.update_fields = %w[name description hostname port username password ssh_key auth_type status environment tags notes sort updated_by catalog_id]
  self.show_fields = %w[id name description hostname port username auth_type status environment tags notes last_tested_at last_test_result sort created_by updated_by created_at updated_at catalog_id]
  self.search_fields = %w[name description hostname notes]

  enum status: {
    active: 'active',
    inactive: 'inactive',
    error: 'error'
  }

  validates :name, presence: true, uniqueness: true
  validates :hostname, presence: true
  validates :username, presence: true
  validates :port, presence: true, numericality: { greater_than: 0, less_than: 65536 }

  # 回调
  before_validation :set_default_catalog, on: :create

  scope :by_environment, ->(env) { where(environment: env) }
  scope :active_resources, -> { where(status: 'active') }
  scope :ordered, -> { order(:sort, :name) }

  # 测试SSH连接
  def test_connection!
    require 'net/ssh'

    options = {
      port: port,
      timeout: 10,
      verify_host_key: :never  # 在测试环境中跳过主机密钥验证
    }

    if ssh_key.present?
      # 使用SSH密钥连接
      begin
        key_data = [ssh_key]
        options[:key_data] = key_data
      rescue => e
        raise "SSH key format error: #{e.message}"
      end
    else
      if password.blank?
        raise "Either password or SSH key must be provided"
      end
      options[:password] = password
    end

    Net::SSH.start(hostname, username, options) do |ssh|
      result = ssh.exec!('echo "Connection test successful"')
      Rails.logger.info("Host connection test result: #{result&.strip}")
    end

    update_test_result('success', nil)
  rescue => e
    error_msg = "Connection failed: #{e.message}"
    Rails.logger.error("Host connection test failed: #{error_msg}")
    update_test_result('failed', error_msg)
    raise e
  end

  # 检查是否需要测试
  def needs_testing?
    last_tested_at.nil? || last_tested_at < 1.hour.ago || status == 'error'
  end

  # 格式化显示配置（隐藏敏感信息）
  def display_config
    {
      hostname: hostname,
      port: port,
      username: username,
      password: password.present? ? '******' : nil,
      ssh_key: ssh_key.present? ? '******' : nil
    }
  end

  def html_json
    as_json(only: self.class.show_fields).merge({
      display_config: display_config,
      needs_testing: needs_testing?,
      connection_string: "ssh #{username}@#{hostname}:#{port}"
    })
  end

  private

  # 更新测试结果
  def update_test_result(result, error_message)
    update_columns(
      last_tested_at: Time.current,
      last_test_result: result,
      last_test_error: error_message,
      status: result == 'success' ? 'active' : 'error'
    )
  end

  def set_default_catalog
    self.catalog_id ||= Catalog.default_catalog_id("META_HOST") if catalog_id.blank?
  end
end
