class CreateAdsPlatformsAndAccounts < ActiveRecord::Migration[7.1]
  def change
    # 创建广告平台表
    create_table :ads_platforms do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :api_version
      t.string :base_url
      t.string :oauth_url
      t.text :scopes # JSON格式存储所需权限范围
      t.string :auth_method, default: 'oauth2' # 认证方式
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :ads_platforms, :slug, unique: true
    add_index :ads_platforms, :active

    # 创建广告账户表
    create_table :ads_accounts do |t|
      # 基本信息
      t.string :name, null: false
      t.string :account_id, null: false # 平台账户ID
      t.references :ads_platform, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :sys_user, null: false, foreign_key: true # 创建者


      # 账户状态和配置
      t.string :account_status, default: 'active'
      t.string :currency
      t.string :timezone
      t.decimal :account_balance, precision: 15, scale: 2
      t.decimal :daily_budget, precision: 15, scale: 2

      # 同步相关
      t.boolean :active, default: true
      t.datetime :last_sync_at
      t.integer :sync_frequency, default: 60 # 分钟
      t.string :sync_status, default: 'pending'
      t.text :last_error

      # 其他配置
      t.text :config # JSON格式存储平台特定配置

      t.timestamps
    end

    add_index :ads_accounts, [:ads_platform_id, :account_id], unique: true, name: 'index_ads_accounts_on_platform_and_account_id'
    add_index :ads_accounts, :active
    add_index :ads_accounts, :account_status
    add_index :ads_accounts, :sync_status
  end
end
