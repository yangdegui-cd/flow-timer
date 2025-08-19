class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :oauth_callback, :register]
  def login
    if request.post?
      user = SysUser.find_by(email: params[:email]&.downcase)

      if user&.authenticate(params[:password])
        if user.active_status?
          generate_token_and_respond(user)
        else
          render json: error('账户已被禁用'), status: :forbidden
        end
      else
        render json: error('邮箱或密码错误'), status: :unauthorized
      end
    else
      render json: error('Method not allowed'), status: :method_not_allowed
    end
  end

  def register
    return render json: error('Method not allowed'), status: :method_not_allowed unless request.post?

    user = SysUser.new(register_params)

    if user.save
      # 新用户默认分配 viewer 角色
      user.add_role('viewer')
      generate_token_and_respond(user)
    else
      render json: error(user.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def logout
    # 由于使用JWT无状态token，前端删除token即可
    render json: ok({ message: '退出登录成功' })
  end

  def me
    render json: ok({
                      sys_user: user_with_permissions(current_user)
    })
  end

  # OAuth回调处理
  def oauth_callback
    auth_data = request.env['omniauth.auth']

    return render json: error('OAuth认证失败'), status: :bad_request unless auth_data

    begin
      user = SysUser.find_or_create_by_oauth(auth_data.to_h.with_indifferent_access)

      if user.active_status?
        user.update_last_login!
        
        # 生成token
        payload = {
          user_id: user.id,
          email: user.email,
          exp: 24.hours.from_now.to_i
        }
        token = JWT.encode(payload, Rails.application.secret_key_base)
        
        # 重定向到前端并携带token
        frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:5174'
        redirect_to "#{frontend_url}/auth/oauth-success?token=#{token}&provider=#{auth_data[:provider]}"
      else
        frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:5174'
        redirect_to "#{frontend_url}/auth/oauth-error?error=account_disabled"
      end
    rescue => e
      Rails.logger.error "OAuth callback error: #{e.message}"
      frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:5174'
      redirect_to "#{frontend_url}/auth/oauth-error?error=authentication_failed"
    end
  end

  # OAuth失败处理
  def oauth_failure
    error_msg = params[:message] || 'OAuth认证失败'
    render json: error(error_msg), status: :bad_request
  end

  def change_password
    return render json: error('Method not allowed'), status: :method_not_allowed unless request.put?

    unless current_user.authenticate(params[:current_password])
      return render json: error('当前密码错误'), status: :unauthorized
    end

    if current_user.update(password: params[:new_password])
      render json: ok({ message: '密码修改成功' })
    else
      render json: error(current_user.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def update_profile
    return render json: error('Method not allowed'), status: :method_not_allowed unless request.put?

    if current_user.update(profile_params)
      render json: ok({
                        sys_user: user_with_permissions(current_user),
                        message: '个人信息更新成功'
      })
    else
      render json: error(current_user.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  # 绑定OAuth账号
  def bind_oauth
    return render json: error('Method not allowed'), status: :method_not_allowed unless request.post?

    auth_data = session[:pending_oauth_data]
    return render json: error('无有效的OAuth数据'), status: :bad_request unless auth_data

    begin
      current_user.create_or_update_oauth_provider!(
        auth_data[:provider],
        auth_data[:uid],
        auth_data
      )

      session.delete(:pending_oauth_data)
      render json: ok({ message: "#{auth_data[:provider].humanize}账号绑定成功" })
    rescue => e
      Rails.logger.error "OAuth binding error: #{e.message}"
      render json: error('账号绑定失败'), status: :internal_server_error
    end
  end

  # 解绑OAuth账号
  def unbind_oauth
    return render json: error('Method not allowed'), status: :method_not_allowed unless request.delete?

    provider = params[:provider]
    oauth_provider = current_user.sys_oauth_providers.find_by(provider: provider)

    return render json: error('未找到绑定的账号'), status: :not_found unless oauth_provider

    if oauth_provider.destroy
      render json: ok({ message: "#{provider.humanize}账号解绑成功" })
    else
      render json: error('解绑失败'), status: :internal_server_error
    end
  end

  private

  def register_params
    params.permit(:email, :password, :name)
  end

  def profile_params
    params.permit(:name, :avatar_url)
  end

  def generate_token_and_respond(user)
    user.update_last_login!

    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i # 24小时过期
    }

    token = JWT.encode(payload, Rails.application.secret_key_base)

    render json: ok({
                      token: token,
                      sys_user: user_with_permissions(user),
                      message: '登录成功'
    })
  end

  def user_with_permissions(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar_url: user.avatar_url,
      status: user.status,
      last_login_at: user.last_login_at,
      roles: user.sys_roles.map { |role| { name: role.name, display_name: role.display_name } },
      permissions: user.permissions,
      oauth_providers: user.sys_oauth_providers.map do |oauth|
        {
          provider: oauth.provider,
          provider_name: oauth.provider_name,
          display_info: oauth.display_info,
          connected_at: oauth.created_at
        }
      end
    }
  end
end
