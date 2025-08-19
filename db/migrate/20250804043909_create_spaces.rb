class CreateSpaces < ActiveRecord::Migration[7.1]
  def change
    create_table :spaces do |t|
      t.string :name
      t.string :space_type
      t.integer :sort

      t.timestamps
    end
    add_index :spaces, :space_type
  end
end
