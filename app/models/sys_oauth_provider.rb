class SysOauthProvider < ApplicationRecord
  belongs_to :sys_user

  validates :provider, presence: true, inclusion: { in: %w[github wechat] }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

  scope :github, -> { where(provider: 'github') }
  scope :wechat, -> { where(provider: 'wechat') }

  def provider_name
    case provider
    when 'github' then 'GitHub'
    when 'wechat' then '微信'
    else provider.humanize
    end
  end

  def expired?
    return false unless expires_at
    expires_at < Time.current
  end

  def valid_token?
    access_token.present? && !expired?
  end

  def profile_data
    extra_data || {}
  end

  def refresh_token_if_needed!
    return unless expired? && refresh_token.present?

    case provider
    when 'github'
      refresh_github_token!
    when 'wechat'
      refresh_wechat_token!
    end
  end

  def display_info
    case provider
    when 'github'
      {
        username: profile_data['login'] || uid,
        avatar: profile_data['avatar_url'],
        profile_url: profile_data['html_url']
      }
    when 'wechat'
      {
        nickname: profile_data['nickname'],
        avatar: profile_data['headimgurl'],
        openid: uid
      }
    else
      { uid: uid }
    end
  end

  private

  def refresh_github_token!
    # GitHub tokens 通常不过期，暂不实现刷新逻辑
    Rails.logger.warn "GitHub token refresh not implemented"
  end

  def refresh_wechat_token!
    # 微信token刷新逻辑
    return unless refresh_token.present?

    begin
      # 实际项目中需要调用微信API刷新token
      Rails.logger.info "Refreshing WeChat token for user #{sys_user.id}"
      # TODO: 实现微信token刷新
    rescue => e
      Rails.logger.error "Failed to refresh WeChat token: #{e.message}"
    end
  end
end
