class CreateFtFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :ft_flows do |t|
      t.string :name, null: false
      t.string :flow_id, null: false
      t.text :description
      t.json :params, null: false
      t.bigint :version_id, null: false, default: 1
      t.bigint :catalog_id, null: false
      t.string :status, null: false, default: 'draft'

      t.timestamps
    end
    add_index :ft_flows, :flow_id, unique: true
    add_index :ft_flows, :status
    add_index :ft_flows, :catalog_id
    add_foreign_key :ft_flows, :catalogs, column: :catalog_id, primary_key: "id", on_delete: :cascade
    add_foreign_key :ft_flows, :ft_flow_versions, column: :version_id, primary_key: "id", on_delete: :cascade
  end
end
