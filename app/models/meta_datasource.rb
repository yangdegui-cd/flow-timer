class MetaDatasource < ApplicationRecord
  # 关联关系
  belongs_to :catalog, optional: true
  belongs_to :created_by_user, class_name: 'SysUser', foreign_key: 'created_by', optional: true
  belongs_to :updated_by_user, class_name: 'SysUser', foreign_key: 'updated_by', optional: true

  # 验证规则
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :db_type, presence: true, inclusion: {
    in: %w[mysql oracle hive postgresql mariadb trino clickhouse sqlserver sqlite],
    message: "%{value} 不是支持的数据库类型"
  }
  validates :host, presence: true, length: { maximum: 255 }
  validates :port, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 65535 }
  validates :username, presence: true, length: { maximum: 100 }
  validates :password, presence: true
  validates :status, inclusion: {
    in: %w[active inactive error testing],
    message: "%{value} 不是有效的状态"
  }

  # 回调
  before_validation :set_default_status, on: :create
  before_validation :set_default_catalog, on: :create
  before_save :encrypt_password, if: :password_changed?
  before_create :set_created_by
  before_update :set_updated_by

  # 作用域
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(db_type) { where(db_type: db_type) if db_type.present? }
  scope :search_by_name, ->(name) { where('name ILIKE ?', "%#{name}%") if name.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # 类方法
  def self.supported_types
    %w[mysql oracle hive postgresql mariadb trino clickhouse sqlserver sqlite]
  end

  def self.valid_statuses
    %w[active inactive error testing]
  end

  # 实例方法
  def display_name
    "#{name} (#{db_type.upcase})"
  end

  def connection_string
    "#{db_type}://#{username}@#{host}:#{port}"
  end

  def status_color
    case status
    when 'active'
      'green'
    when 'inactive'
      'yellow'
    when 'error'
      'red'
    when 'testing'
      'blue'
    else
      'gray'
    end
  end

  def can_connect?
    status == 'active'
  end

  def test_connection
    begin
      client = get_db_client
      result = client.test_connection

      if result[:success]
        update_test_result(
          true,
          result[:message],
          result[:databases],
          result[:catalogs]
        )
        true
      else
        update_test_result(false, result[:message])
        false
      end
    rescue => e
      Rails.logger.error "数据库连接测试失败: #{e.message}"
      update_test_result(false, "连接失败: #{e.message}")
      false
    end
  end

  def update_test_result(success, message = nil, databases = nil, catalogs = nil)
    self.status = success ? 'active' : 'error'
    self.test_result = message
    self.last_test_at = Time.current

    # 如果测试成功，可以保存发现的数据库列表到extra_config
    if success && (databases.present? || catalogs.present?)
      self.extra_config ||= {}
      self.extra_config['discovered_databases'] = databases if databases.present?
      self.extra_config['discovered_catalogs'] = catalogs if catalogs.present?
    end

    save!
  end

  # JSON序列化
  def as_json(options = {})
    super(options.merge(
      except: [:password],
      methods: [:display_name, :connection_string, :status_color],
      include: {
        created_by_user: { only: [:id, :name] },
        updated_by_user: { only: [:id, :name] }
      }
    ))
  end

  # 导出配置（不包含敏感信息）
  def export_config
    {
      name: name,
      db_type: db_type,
      host: host,
      port: port,
      username: username,
      description: description,
      extra_config: extra_config
    }
  end

  # 使用 db_client 架构获取数据库列表
  def get_databases(catalog = nil)
    begin
      client = get_db_client
      client.get_databases(catalog)
    rescue => e
      Rails.logger.error "获取数据库列表失败: #{e.message}"
      []
    ensure
      client&.close
    end
  end

  # 获取 Schema 列表
  def get_schemas(database_name, catalog = nil)
    begin
      client = get_db_client
      client.get_schemas(database_name, catalog)
    rescue => e
      Rails.logger.error "获取Schema列表失败: #{e.message}"
      []
    ensure
      client&.close
    end
  end

  # 获取 Catalog 列表（主要用于 Trino）
  def get_catalogs
    begin
      client = get_db_client
      client.get_catalogs
    rescue => e
      Rails.logger.error "获取Catalog列表失败: #{e.message}"
      []
    ensure
      client&.close
    end
  end

  # 获取表列表
  def get_tables(database_name, schema_name = nil, catalog = nil)
    begin
      client = get_db_client
      client.get_tables(database_name, schema_name, catalog)
    rescue => e
      Rails.logger.error "获取表列表失败: #{e.message}"
      []
    ensure
      client&.close
    end
  end

  # 获取表结构
  def describe_table(table_name, database_name = nil, schema_name = nil, catalog = nil)
    begin
      client = get_db_client
      client.describe_table(table_name, database_name, schema_name, catalog)
    rescue => e
      Rails.logger.error "获取表结构失败: #{e.message}"
      []
    ensure
      client&.close
    end
  end

  # 执行 SQL 语句（非查询）
  def execute_sql(sql, options = {})
    begin
      client = get_db_client

      # 根据 SQL 类型决定使用 execute 还是 query
      if sql.strip.upcase.start_with?('SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN')
        client.query(sql, options)
      else
        client.execute(sql, options)
      end
    rescue => e
      Rails.logger.error "SQL执行失败: #{e.message}"
      {
        success: false,
        message: "SQL执行失败: #{e.message}",
        error: e.class.name,
        test_time: Time.current.iso8601
      }
    ensure
      client&.close
    end
  end

  # 获取数据库客户端
  def get_db_client
    DatasourceClient.build(self)
  end

  def get_trino_default_catalog
    if self.db_type == 'trino' && self.extra_config.blank?
      self.extra_config = {}
      self.extra_config['catalog'] ||= get_catalogs.first&.name
    else
      nil
    end
  end

  private

  def set_default_status
    self.status ||= 'inactive'
  end

  def encrypt_password
    # 这里应该使用合适的加密方式
    # 示例使用简单的Base64编码（实际应用中应该使用更安全的加密方式）
    self.password = Base64.encode64(password) unless password.blank?
  end

  def decrypt_password
    # 解密密码用于连接测试
    Base64.decode64(password) rescue password
  end

  def set_created_by
    self.created_by ||= Current.user&.id if defined?(Current.user)
  end

  def set_updated_by
    self.updated_by = Current.user&.id if defined?(Current.user)
  end

  def set_default_catalog
    self.catalog_id ||= Catalog.default_catalog_id("META_DATASOURCE") if catalog_id.blank?
  end
end
