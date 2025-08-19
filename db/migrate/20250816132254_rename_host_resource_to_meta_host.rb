class RenameHostResourceToMetaHost < ActiveRecord::Migration[7.1]
  def change
    rename_table :host_resources, :meta_hosts
  end
end
