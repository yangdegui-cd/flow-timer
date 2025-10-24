class CreateSysLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :sys_logs, comment: '系统操作日志表' do |t|
      t.references :user, null: false, foreign_key: { to_table: :sys_users }, comment: '用户ID'
      t.string :controller_name, null: false, limit: 100, comment: '控制器名称'
      t.string :action_name, null: false, limit: 50, comment: '动作名称'
      t.string :request_method, null: false, limit: 10, comment: '请求方法 GET/POST/PUT/DELETE'
      t.string :request_url, null: false, limit: 500, comment: '请求URL'
      t.text :url_params, comment: 'URL参数 JSON格式'
      t.text :body_params, comment: '请求体参数 JSON格式'
      t.datetime :request_time, null: false, comment: '请求开始时间'
      t.datetime :response_time, comment: '响应结束时间'
      t.integer :duration, comment: '请求耗时(毫秒)'
      t.integer :status_code, comment: 'HTTP状态码'
      t.string :ip_address, limit: 45, comment: '客户端IP地址'
      t.string :user_agent, limit: 500, comment: '用户代理'
      t.text :error_message, comment: '错误信息(如果有)'

      t.timestamps
    end

    # 添加索引（user_id已由references自动创建，无需重复添加）
    add_index :sys_logs, [:controller_name, :action_name], comment: '控制器动作索引'
    add_index :sys_logs, :request_time, comment: '请求时间索引'
    add_index :sys_logs, :request_method, comment: '请求方法索引'
    add_index :sys_logs, :status_code, comment: '状态码索引'
    add_index :sys_logs, :ip_address, comment: 'IP地址索引'
  end
end
