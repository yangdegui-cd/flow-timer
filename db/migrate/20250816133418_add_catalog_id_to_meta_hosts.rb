class AddCatalogIdToMetaHosts < ActiveRecord::Migration[7.1]
  def change
    add_column :meta_hosts, :catalog_id, :bigint
    add_index :meta_hosts, :catalog_id
    add_foreign_key :meta_hosts, :catalogs, column: :catalog_id

    # 设置默认值为默认catalog
    reversible do |dir|
      dir.up do
        default_catalog_id = Catalog.default_catalog_id("META_HOST")
        execute "UPDATE meta_hosts SET catalog_id = #{default_catalog_id} WHERE catalog_id IS NULL"
      end
    end
  end
end
