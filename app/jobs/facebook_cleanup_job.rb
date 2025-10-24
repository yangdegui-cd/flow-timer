class FacebookCleanupJob < BaseResqueJob
  @queue = :facebook_cleanup

  def self.perform(options = {})
    new.perform(options)
  end

  def perform(options = {})
    days = options['days']&.to_i || 90

    log_info "开始清理#{days}天前的Facebook广告数据"

    cutoff_date = days.days.ago
    old_data = AdsData.joins(ads_account: :ads_platform)
                     .where(ads_platforms: { slug: 'facebook' })
                     .where('ads_data.date < ?', cutoff_date)

    count = old_data.count

    if count > 0
      old_data.delete_all
      log_info "已清理 #{count} 条过期的Facebook广告数据"
    else
      log_info "没有找到需要清理的过期Facebook广告数据"
    end

    log_info "Facebook广告数据清理任务完成"
  rescue => e
    log_error "Facebook数据清理任务失败: #{e.message}", e
    raise
  end
end