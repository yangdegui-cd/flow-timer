# frozen_string_literal: true

class FacebookController < ApplicationController
  # 同步 Facebook 广告账户
  # POST /facebook/sync_accounts
  def sync_accounts
    config = Config.first

    # 检查配置
    unless config&.facebook_access_token.present?
      render json: error('Facebook 访问令牌未配置，请先完成 Facebook 授权')
      return
    end

    # 验证令牌是否有效
    unless FacebookTokenService.validate_token
      render json: error('Facebook 访问令牌无效或已过期，请重新授权')
      return
    end

    begin
      # 获取 Facebook 平台
      facebook_platform = AdsPlatform.find_by(slug: 'facebook')
      unless facebook_platform
        render json: error('Facebook 广告平台未初始化')
        return
      end

      # 调用 Facebook Graph API 获取广告账户列表
      # 使用 me/adaccounts 端点获取用户有权限的所有广告账户
      response = HTTParty.get('https://graph.facebook.com/v18.0/me/adaccounts', {
        query: {
          access_token: config.facebook_access_token,
          fields: 'id,name,account_status,currency,timezone_name,business'
        },
        timeout: 30
      })

      unless response.success?
        error_msg = response.parsed_response.dig('error', 'message') || response.body
        Rails.logger.error "获取 Facebook 广告账户失败: #{error_msg}"
        render json: error("获取广告账户失败: #{error_msg}")
        return
      end

      accounts_data = response.parsed_response['data'] || []

      if accounts_data.empty?
        render json: ok({ synced: 0, created: 0, updated: 0 }, '未找到任何广告账户')
        return
      end

      # 同步账户到数据库
      created_count = 0
      updated_count = 0

      accounts_data.each do |account_data|
        # Facebook 账户 ID 格式为 act_123456789，需要去掉 act_ 前缀
        account_id = account_data['id'].to_s.gsub(/^act_/, '')
        account_name = account_data['name']
        account_status = map_facebook_account_status(account_data['account_status'])
        currency = account_data['currency']
        timezone = account_data['timezone_name']

        # 查找或创建广告账户
        ads_account = AdsAccount.find_or_initialize_by(
          account_id: account_id,
          ads_platform_id: facebook_platform.id
        )

        # 判断是新建还是更新
        is_new = ads_account.new_record?

        # 更新账户信息
        ads_account.assign_attributes(
          name: account_name,
          account_status: account_status,
          currency: currency,
          timezone: timezone,
          sys_user_id: current_user.id,
          sync_status: 'success',
          last_sync_at: Time.current,
          config: {
            business: account_data['business'],
            raw_account_status: account_data['account_status']
          }
        )

        if ads_account.save
          if is_new
            created_count += 1
            Rails.logger.info "创建 Facebook 广告账户: #{account_name} (#{account_id})"
          else
            updated_count += 1
            Rails.logger.info "更新 Facebook 广告账户: #{account_name} (#{account_id})"
          end
        else
          Rails.logger.error "保存广告账户失败: #{ads_account.errors.full_messages.join(', ')}"
        end
      end

      render json: ok(
        {
          synced: accounts_data.size,
          created: created_count,
          updated: updated_count
        },
        "成功同步 #{accounts_data.size} 个广告账户 (新增: #{created_count}, 更新: #{updated_count})"
      )

    rescue HTTParty::Error => e
      Rails.logger.error "Facebook API 请求失败: #{e.message}"
      render json: error("网络请求失败: #{e.message}")
    rescue StandardError => e
      Rails.logger.error "同步 Facebook 广告账户异常: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: error("同步失败: #{e.message}")
    end
  end

  private

  # 映射 Facebook 账户状态到系统状态
  def map_facebook_account_status(fb_status)
    case fb_status&.to_i
    when 1
      'active'      # 正常
    when 2
      'suspended'   # 禁用
    when 3
      'closed'      # 关闭
    when 7
      'suspended'   # 待定
    when 9
      'suspended'   # 待付款确认
    when 100
      'suspended'   # 待定风险
    when 101
      'suspended'   # 待定审核
    else
      'active'      # 默认为正常
    end
  end
end
