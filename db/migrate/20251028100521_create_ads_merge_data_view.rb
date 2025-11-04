class CreateAdsMergeDataView < ActiveRecord::Migration[7.1]
  def up
    # 创建广告数据合并视图
    execute <<-SQL
      CREATE OR REPLACE VIEW ads_merge_data AS
      SELECT
        a.*,
        b.installs AS adjust_installs,
        b.cost AS adjust_spend,
        b.cohort_all_revenue,
        b.all_revenue_total_d0,
        b.all_revenue_total_d1,
        b.all_revenue_total_d2,
        b.all_revenue_total_d3,
        b.all_revenue_total_d4,
        b.all_revenue_total_d5,
        b.all_revenue_total_d6,
        b.retained_users_d0,
        b.retained_users_d1,
        b.retained_users_d2,
        b.retained_users_d3,
        b.retained_users_d4,
        b.retained_users_d5,
        b.retained_users_d6,
        b.paying_users_d0,
        b.paying_users_d1,
        b.paying_users_d2,
        b.paying_users_d3,
        b.paying_users_d4,
        b.paying_users_d5,
        b.paying_users_d6
      FROM ads_data a
      LEFT JOIN ads_adjust_data b
        ON a.date = b.date
        AND a.hour = b.hour
        AND a.project_id = b.project_id
        AND a.campaign_name = b.campaign_network
        AND a.adset_name = b.adgroup_network
        AND a.ad_name = b.creative_network
    SQL
  end

  def down
    # 删除视图
    execute "DROP VIEW IF EXISTS ads_merge_data"
  end
end
