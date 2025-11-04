class AdsFetchAdStateService
  attr_reader :ads_account, :errors

  def initialize(ads_account)
    @ads_account = ads_account
    @errors = []
  end

  # 工厂方法：根据平台返回对应的 Service 实例
  def self.for(ads_account)
    platform = ads_account.ads_platform.slug

    case platform
    when 'facebook'
      AdsFetchAdStateService::Facebook.new(ads_account)
    when 'google'
      AdsFetchAdStateService::Google.new(ads_account)
    when 'tiktok'
      AdsFetchAdStateService::TikTok.new(ads_account)
    else
      raise "不支持的平台: #{platform}"
    end
  end

  # 子类必须实现的方法
  def sync_all
    raise NotImplementedError, "#{self.class} must implement #sync_all"
  end

  protected

  # 通用的验证方法
  def validate_account
    unless @ads_account.present?
      @errors << '广告账户不存在'
      return false
    end

    true
  end

  # 通用的错误处理
  def handle_sync_error(error)
    error_message = "广告状态同步失败: #{error.message}"
    @errors << error_message

    Rails.logger.error "#{platform_name} 广告状态同步失败: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end

  # 平台名称（子类可覆盖）
  def platform_name
    @ads_account.ads_platform.name
  end

  # 解析时间（通用）
  def parse_time(time_str)
    return nil if time_str.blank?
    Time.parse(time_str)
  rescue StandardError
    nil
  end
end
