class CreateAutomationRules < ActiveRecord::Migration[7.1]
  def change
    create_table :automation_rules do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :time_granularity, null: false, default: 'hour'
      t.integer :time_range, null: false, default: 1
      t.json :condition_group, null: false
      t.string :action, null: false
      t.decimal :action_value, precision: 10, scale: 2
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :automation_rules, :enabled
    add_index :automation_rules, [:project_id, :enabled]
  end
end
