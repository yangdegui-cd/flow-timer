class CreateUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :sys_user_roles do |t|
      t.references :sys_user, null: false, foreign_key: true
      t.references :sys_role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sys_user_roles, [:sys_user_id, :sys_role_id], unique: true
  end
end
