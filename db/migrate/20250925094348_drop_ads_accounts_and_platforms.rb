class DropAdsAccountsAndPlatforms < ActiveRecord::Migration[7.1]
  def up
    drop_table :ads_accounts if table_exists?(:ads_accounts)
    drop_table :ads_platforms if table_exists?(:ads_platforms)
  end

  def down
    # 如果需要回滚，可以在这里重新创建表
    raise ActiveRecord::IrreversibleMigration
  end
end
