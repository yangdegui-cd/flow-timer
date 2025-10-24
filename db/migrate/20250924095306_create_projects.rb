class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.boolean :active_ads_automate, default: true, null: false
      t.text :description
      t.integer :time_zone, default: 0
      t.string :status, default: 'active', null: false

      t.timestamps
    end

    add_index :projects, :name, unique: true
    add_index :projects, :status
    add_index :projects, :active_ads_automate
  end
end
