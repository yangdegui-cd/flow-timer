class RenameMetaDatabaseToMetaDatasource < ActiveRecord::Migration[7.1]
  def change
    rename_table :meta_databases, :meta_datasources
  end
end
