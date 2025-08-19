class CreateFtTaskExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :ft_task_executions do |t|
      t.integer :task_id, null: false
      t.string :execution_id, null: false
      t.string :status, default: 'pending', null: false # pending, running, completed, failed, cancelled
      t.json :result
      t.text :error_message
      t.json :data_quality
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :duration_seconds
      t.string :execution_type, default: 'system', comment: 'system, manual'
      t.string :queue
      t.string :data_time, null: false, comment: '数据时间'
      t.json :system_params, null: false
      t.json :custom_params, null: false
      t.string :resque_job_id
      t.timestamps
    end

    add_index :ft_task_executions, :task_id
    add_index :ft_task_executions, :execution_id, unique: true
    add_index :ft_task_executions, :status
    add_index :ft_task_executions, :created_at
    add_index :ft_task_executions, :resque_job_id
  end
end
