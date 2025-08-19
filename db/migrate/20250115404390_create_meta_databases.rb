class CreateMetaDatabases < ActiveRecord::Migration[7.0]
  def change
    create_table :meta_databases do |t|
      # 基本信息
      t.string :name, null: false, comment: '连接名称'
      t.string :type, null: false, comment: '数据库类型：mysql, oracle, hive, postgresql, mariadb, trino, clickhouse, sqlserver'
      t.string :host, null: false, comment: '主机地址'
      t.integer :port, null: false, comment: '端口号'
      t.string :username, null: false, comment: '用户名'
      t.string :password, null: false, comment: '密码'
      t.text :description, comment: '描述信息'
      
      # 状态相关
      t.string :status, default: 'inactive', comment: '连接状态：active, inactive, error, testing'
      t.json :extra_config, comment: '额外配置参数（JSON格式）'
      t.datetime :last_test_at, comment: '最后测试时间'
      t.text :test_result, comment: '测试结果信息'
      
      # 审计字段
      t.bigint :created_by, comment: '创建者ID'
      t.bigint :updated_by, comment: '更新者ID'
      
      t.timestamps
    end

    # 添加索引
    add_index :meta_databases, :name, unique: true, comment: '连接名称唯一索引'
    add_index :meta_databases, :type, comment: '数据库类型索引'
    add_index :meta_databases, :status, comment: '状态索引'
    add_index :meta_databases, :created_by, comment: '创建者索引'
    add_index :meta_databases, [:host, :port], comment: '主机端口组合索引'
    
    # 添加外键约束（当 users 表存在时可取消注释）
    # add_foreign_key :meta_databases, :users, column: :created_by, on_delete: :nullify
    # add_foreign_key :meta_databases, :users, column: :updated_by, on_delete: :nullify
  end
end