class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :sys_roles do |t|
      t.string :name, null: false
      t.string :description
      t.json :permissions

      t.timestamps
    end

    add_index :sys_roles, :name, unique: true
  end
end
