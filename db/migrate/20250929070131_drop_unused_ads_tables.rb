class DropUnusedAdsTables < ActiveRecord::Migration[7.1]
  def up
    # 删除不再使用的标准化表，保留ads_accounts表因为它仍在使用
    # 需要按依赖关系的逆序删除表
    drop_table :ads_insights if table_exists?(:ads_insights)
    drop_table :ads_ads if table_exists?(:ads_ads)
    drop_table :ads_ad_sets if table_exists?(:ads_ad_sets)
    drop_table :ads_campaigns if table_exists?(:ads_campaigns)
  end

  def down
    # 如果需要回滚，重新创建基础表结构
    create_table :ads_campaigns do |t|
      t.references :ads_account, null: false, foreign_key: true
      t.string :campaign_id, null: false
      t.string :name, null: false
      t.string :status
      t.string :objective
      t.timestamps
    end

    create_table :ads_ad_sets do |t|
      t.references :ads_account, null: false, foreign_key: true
      t.references :ads_campaign, null: false, foreign_key: true
      t.string :adset_id, null: false
      t.string :name, null: false
      t.string :status
      t.timestamps
    end

    create_table :ads_ads do |t|
      t.references :ads_account, null: false, foreign_key: true
      t.references :ads_ad_set, null: false, foreign_key: true
      t.string :ad_id, null: false
      t.string :name, null: false
      t.string :status
      t.timestamps
    end

    create_table :ads_insights do |t|
      t.references :ads_account, null: false, foreign_key: true
      t.date :date
      t.integer :impressions
      t.integer :clicks
      t.decimal :spend, precision: 10, scale: 2
      t.timestamps
    end
  end
end
