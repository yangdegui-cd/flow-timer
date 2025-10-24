class FacebookTokenValidationJob < BaseResqueJob
  @queue = :facebook_validation

  def self.perform(options = {})
    new.perform(options)
  end

  def perform(options = {})
    log_info "开始验证Facebook API访问令牌"

    facebook_accounts = AdsAccount.joins(:ads_platform)
                                 .where(ads_platforms: { slug: 'facebook' })
                                 .where.not(access_token: [nil, ''])

    if facebook_accounts.empty?
      log_info "未找到配置了访问令牌的Facebook广告账户"
      return
    end

    valid_count = 0
    invalid_count = 0
    error_count = 0

    facebook_accounts.each do |account|
      begin
        log_info "验证账户 #{account.name} (#{account.account_id}) 的访问令牌"

        token_service = FacebookTokenService.new(account)
        if token_service.validate_token
          log_info "账户 #{account.name} 的访问令牌有效"
          valid_count += 1

          # 更新账户状态
          account.update!(
            account_status: 'active',
            last_token_validation_at: Time.current,
            token_validation_error: nil
          )
        else
          log_error "账户 #{account.name} 的访问令牌无效"
          invalid_count += 1

          # 更新账户状态
          account.update!(
            account_status: 'inactive',
            last_token_validation_at: Time.current,
            token_validation_error: 'Token validation failed'
          )
        end

      rescue => e
        log_error "验证账户 #{account.name} 令牌时发生异常: #{e.message}", e
        error_count += 1

        # 更新账户状态
        account.update!(
          account_status: 'error',
          last_token_validation_at: Time.current,
          token_validation_error: e.message
        )
      end
    end

    log_info "令牌验证完成: 有效 #{valid_count}, 无效 #{invalid_count}, 异常 #{error_count}"

    # 如果有无效或异常的令牌，可以发送通知
    if invalid_count > 0 || error_count > 0
      log_error "发现 #{invalid_count + error_count} 个问题令牌，需要人工处理"
      # 这里可以添加邮件或其他通知逻辑
    end

    log_info "Facebook令牌验证任务完成"
  rescue => e
    log_error "Facebook令牌验证任务失败: #{e.message}", e
    raise
  end
end