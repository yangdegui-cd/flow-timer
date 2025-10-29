class RemoveOsNameFromAdsDataTables < ActiveRecord::Migration[7.1]
  def up
    # 删除 ads_data 表的 os_name 列和索引
    if column_exists?(:ads_data, :os_name)
      remove_index :ads_data, :os_name if index_exists?(:ads_data, :os_name)
      remove_column :ads_data, :os_name
    end

    # 删除 ads_adjust_data 表的 os_name 列和索引
    if column_exists?(:ads_adjust_data, :os_name)
      remove_index :ads_adjust_data, :os_name if index_exists?(:ads_adjust_data, :os_name)
      remove_column :ads_adjust_data, :os_name
    end
  end

  def down
    # 回滚操作
    add_column :ads_data, :os_name, :string unless column_exists?(:ads_data, :os_name)
    add_index :ads_data, :os_name unless index_exists?(:ads_data, :os_name)

    add_column :ads_adjust_data, :os_name, :string unless column_exists?(:ads_adjust_data, :os_name)
    add_index :ads_adjust_data, :os_name unless index_exists?(:ads_adjust_data, :os_name)
  end
end
