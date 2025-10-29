class AdsMergeDatum < ApplicationRecord
  # 视图是只读的
  self.table_name = 'ads_merge_data'
  self.primary_key = 'id'

  # 关联关系
  belongs_to :ads_account
  belongs_to :project

  # 视图不能被插入、更新或删除
  def readonly?
    true
  end

  # 作用域 - 方便查询
  scope :by_date_range, ->(start_date, end_date) {
    where(date: start_date..end_date)
  }

  scope :by_project, ->(project_id) {
    where(project_id: project_id)
  }

  scope :by_platform, ->(platform) {
    where(platform: platform)
  }

  scope :with_adjust_data, -> {
    where.not(adjust_install: nil)
  }

  scope :recent, ->(days = 7) {
    where('date >= ?', days.days.ago.to_date)
  }

  # 实例方法
  def has_adjust_data?
    adjust_install.present?
  end

  def total_revenue_d7
    [
      all_revenue_total_d0,
      all_revenue_total_d1,
      all_revenue_total_d2,
      all_revenue_total_d3,
      all_revenue_total_d4,
      all_revenue_total_d5,
      all_revenue_total_d6
    ].compact.sum
  end

  def retention_rate_d1
    return 0 if adjust_install.to_i.zero?
    (retained_users_d1.to_f / adjust_install.to_f * 100).round(2)
  end

  def paying_rate_d0
    return 0 if adjust_install.to_i.zero?
    (paying_users_d0.to_f / adjust_install.to_f * 100).round(2)
  end

  def roas_d7
    return 0 if spend.to_f.zero?
    (total_revenue_d7 / spend.to_f).round(2)
  end

  # 类方法
  def self.summary_by_campaign(project_id, start_date, end_date)
    by_project(project_id)
      .by_date_range(start_date, end_date)
      .group(:campaign_name)
      .select(
        'campaign_name',
        'SUM(impressions) as total_impressions',
        'SUM(clicks) as total_clicks',
        'SUM(spend) as total_spend',
        'SUM(adjust_install) as total_installs',
        'SUM(all_revenue_total_d0 + all_revenue_total_d1 + all_revenue_total_d2 + all_revenue_total_d3 + all_revenue_total_d4 + all_revenue_total_d5 + all_revenue_total_d6) as total_revenue'
      )
  end
end
