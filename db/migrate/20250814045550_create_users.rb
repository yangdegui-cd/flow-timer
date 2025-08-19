class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :sys_users do |t|
      t.string :email, null: false
      t.string :password_digest
      t.string :name, null: false
      t.string :avatar_url
      t.string :status, default: 'active', null: false
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :sys_users, :email, unique: true
    add_index :sys_users, :status
  end
end
