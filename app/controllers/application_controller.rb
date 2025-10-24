class ApplicationController < ActionController::API
  include Result
  include DefaultCrud

  before_action :authenticate_user!
  before_action :record_action
  before_action :validate_permission!
  after_action :record_action_end
  attr_reader :current_user

  # 异常处理
  rescue_from StandardError, with: :handle_exception

  private

  # 记录请求开始
  def record_action
    return unless should_log_action?

    @request_start_time = Time.current
    @current_log = SysLog.create_from_request(current_user, request, @request_start_time)
  end

  # 记录请求结束
  def record_action_end
    return unless @current_log.present?

    begin
      @current_log.response_time = Time.current
      @current_log.duration = ((@current_log.response_time - @current_log.request_time) * 1000).to_i
      @current_log.status_code = response.status

      # 如果有异常信息，记录到error_message
      if @current_exception
        @current_log.error_message = @current_exception.message
      end

      @current_log.save!
    rescue StandardError => e
      # 日志记录失败不应该影响正常请求，但可以记录到Rails日志
      Rails.logger.error "Failed to save action log: #{e.message}"
    end
  end

  # 判断是否需要记录日志
  def should_log_action?
    current_user.present?
  end

  def authenticate_user!
    return render json: not_login unless auth_token.present?

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

  def permission_code
    controller_name = params[:controller]
    action_name = params[:action]
    "#{controller_name}:#{action_name}"
  end

  def validate_permission!
    # 获取当前请求的controller和action
    controller_name = params[:controller]
    action_name = params[:action]
    method = request.method
    return if PermissionSyncService::EXCLUDED_CONTROLLERS.include?(controller_name)
    return if PermissionSyncService::EXCLUDED_ACTIONS.include?(action_name)
    unless current_user_can?(permission_code) || validate_permission_by_method(controller_name, method)
      require_permission!
    end
  end

  def validate_permission_by_method(controller_name, method)
    if method.upcase == 'GET'
      current_user_can?("#{controller_name}:read") || current_user_can?("#{controller_name}:write")
    else
      current_user_can?("#{controller_name}:write")
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

  def require_permission!
    render json: error("缺少权限: #{permission_code}")
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

  # 统一异常处理
  def handle_exception(exception)
    @current_exception = exception

    # 根据异常类型返回不同的响应
    case exception
    when ActiveRecord::RecordNotFound
      render json: error('记录不存在'), status: :not_found
    when ActiveRecord::RecordInvalid
      render json: error(exception.record.errors.full_messages.join(', ')), status: :unprocessable_entity
    when JWT::DecodeError, JWT::ExpiredSignature
      render json: error('认证失败'), status: :unauthorized
    else
      Rails.logger.error "Unhandled exception: #{exception.class} - #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?
      render json: error('服务器内部错误'), status: :internal_server_error
    end
  end

  # 处理权限错误
  # rescue_from CanCan::AccessDenied do |exception|
  #   render json: error('权限不足'), status: :forbidden
  # end
end
