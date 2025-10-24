class CreateAutomationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :automation_logs do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :sys_user, null: true, foreign_key: true, index: true
      t.string :action_type, null: false, comment: '操作类型: 项目编辑, 规则触发, 定时任务, 调整广告投放'
      t.text :action, comment: '具体操作内容'
      t.integer :duration, comment: '执行时长(毫秒)'
      t.string :status, null: false, default: 'success', comment: '状态: success, failed'
      t.json :remark, comment: '备注信息'

      t.timestamps
    end

    add_index :automation_logs, :action_type
    add_index :automation_logs, :status
    add_index :automation_logs, :created_at
  end
end
