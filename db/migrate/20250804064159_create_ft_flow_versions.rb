class CreateFtFlowVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :ft_flow_versions do |t|
      t.string :flow_id, null: false
      t.integer :version, null: false, default: 1
      t.json :flow_config, null: false
      t.timestamps
    end
  end
end
