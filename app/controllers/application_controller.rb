class ApplicationController < ActionController::API
  include Result
  include DefaultCrud

  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    return render json: error('未提供认证token'), status: :unauthorized unless auth_token.present?

    begin
      decoded_token = JWT.decode(auth_token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
      user_id = decoded_token[0]['user_id']

      @current_user = SysUser.active.find(user_id)

      # 检查token是否过期
      exp = decoded_token[0]['exp']
      if exp && Time.current.to_i > exp
        return render json: error('登录已过期，请重新登录'), status: :unauthorized
      end

    rescue JWT::DecodeError, JWT::ExpiredSignature
      render json: error('无效的认证token'), status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: error('用户不存在或已被禁用'), status: :unauthorized
    end
  end

  def auth_token
    return @auth_token if defined?(@auth_token)

    @auth_token = if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    elsif params[:token].present?
      params[:token]
    end
  end

  def require_permission!(permission)
    render json: error('权限不足'), status: :forbidden unless current_user.has_permission?(permission)
  end

  def require_role!(role_name)
    render json: error('权限不足'), status: :forbidden unless current_user.has_role?(role_name)
  end

  def require_admin!
    require_role!('admin')
  end

  def user_signed_in?
    current_user.present?
  end

  def current_user_can?(permission)
    current_user.has_permission?(permission)
  end

  def current_user_is?(role_name)
    current_user.has_role?(role_name)
  end

  # 处理权限错误
  rescue_from CanCan::AccessDenied do |exception|
    render json: error('权限不足'), status: :forbidden
  end
end
