class CreateSysUserProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :sys_user_projects do |t|
      t.references :sys_user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :role, default: 'member', null: false
      t.datetime :assigned_at

      t.timestamps
    end

    add_index :sys_user_projects, [:sys_user_id, :project_id], unique: true
    add_index :sys_user_projects, :role
  end
end
