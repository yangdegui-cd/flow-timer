class FacebookTokenService
  def initialize(ads_account)
    @ads_account = ads_account
    @platform = ads_account.ads_platform
  end

  # 将短期令牌交换为长期令牌
  def exchange_for_long_lived_token
    return false unless @ads_account.access_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/oauth/access_token', {
        query: {
          grant_type: 'fb_exchange_token',
          client_id: ENV['FACEBOOK_APP_ID'],
          client_secret: ENV['FACEBOOK_APP_SECRET'],
          fb_exchange_token: @ads_account.access_token
        }
      })

      if response.success?
        token_data = response.parsed_response

        # 更新账户的令牌信息
        @ads_account.update!(
          access_token: token_data['access_token'],
          token_expires_at: token_data['expires_in']&.seconds&.from_now
        )

        Rails.logger.info "Facebook长期令牌获取成功: #{@ads_account.account_id}"
        true
      else
        Rails.logger.error "Facebook长期令牌获取失败: #{response.body}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "Facebook长期令牌交换异常: #{e.message}"
      false
    end
  end

  # 刷新令牌
  def refresh_token
    exchange_for_long_lived_token
  end

  # 验证令牌是否有效
  def validate_token
    return false unless @ads_account.access_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/me', {
        query: {
          access_token: @ads_account.access_token
        }
      })

      response.success?
    rescue StandardError => e
      Rails.logger.error "Facebook令牌验证失败: #{e.message}"
      false
    end
  end

  # 获取令牌信息
  def token_info
    return nil unless @ads_account.access_token.present?

    begin
      response = HTTParty.get('https://graph.facebook.com/oauth/access_token_info', {
        query: {
          access_token: @ads_account.access_token
        }
      })

      if response.success?
        response.parsed_response
      else
        Rails.logger.error "获取令牌信息失败: #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "获取令牌信息异常: #{e.message}"
      nil
    end
  end

  # 检查令牌是否需要刷新
  def needs_refresh?
    return true if @ads_account.token_expires_at.blank?
    @ads_account.token_expires_at < 7.days.from_now
  end

  # 自动维护令牌
  def maintain_token
    if needs_refresh?
      exchange_for_long_lived_token
    elsif !validate_token
      Rails.logger.warn "令牌已失效，需要重新授权: #{@ads_account.account_id}"
      @ads_account.update!(sync_status: 'error', last_error: '令牌已失效，需要重新授权')
      false
    else
      true
    end
  end
end