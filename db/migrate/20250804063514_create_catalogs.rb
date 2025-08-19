class CreateCatalogs < ActiveRecord::Migration[7.1]
  def change
    create_table :catalogs do |t|
      t.string :name, null: false
      t.bigint :space_id, null: false
      t.integer :sort, null: false, default: 0

      t.timestamps
    end
    add_foreign_key :catalogs, :spaces, column: :space_id, primary_key: "id", on_delete: :cascade
  end
end
