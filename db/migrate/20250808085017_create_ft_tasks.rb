class CreateFtTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :ft_tasks do |t|
      t.string :name, null: false
      t.string :description
      t.string :task_id, null: false
      t.string :flow_id, null: false
      t.bigint :catalog_id, null: false
      t.string :status, null: false
      t.string :task_type, null: false
      t.string :period_type
      t.string :cron_expression
      t.timestamp :effective_time, null: false
      t.timestamp :lose_efficacy_time
      t.json :params
      t.string :queue, null: false, default: "default"
      t.integer :priority, null: false, default: 0
      t.timestamps
    end
    add_foreign_key :ft_tasks, :catalogs, column: :catalog_id, on_delete: :cascade
    add_foreign_key :ft_tasks, :ft_flows, column: :flow_id, primary_key: :flow_id, on_delete: :cascade
    add_index :ft_tasks, :task_id, unique: true
    add_index :ft_tasks, :flow_id
    add_index :ft_tasks, :catalog_id
    add_index :ft_tasks, :period_type
    add_index :ft_tasks, :status
    add_index :ft_tasks, :priority
  end
end
