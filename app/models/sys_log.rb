class SysLog < ApplicationRecord
  belongs_to :user, class_name: 'SysUser'

  # 验证
  validates :controller_name, presence: true, length: { maximum: 100 }
  validates :action_name, presence: true, length: { maximum: 50 }
  validates :request_method, presence: true, inclusion: { in: %w[GET POST PUT DELETE PATCH HEAD OPTIONS] }
  validates :request_url, presence: true, length: { maximum: 500 }
  validates :request_time, presence: true

  # 作用域
  scope :recent, -> { order(request_time: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_controller, ->(controller_name) { where(controller_name: controller_name) }
  scope :by_action, ->(action_name) { where(action_name: action_name) }
  scope :by_method, ->(method) { where(request_method: method.upcase) }
  scope :by_status, ->(status) { where(status_code: status) }
  scope :errors, -> { where('status_code >= 400') }
  scope :slow_requests, ->(threshold_ms = 1000) { where('duration > ?', threshold_ms) }
  scope :today, -> { where(request_time: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(request_time: 1.week.ago..Time.current) }

  # JSON序列化和反序列化
  def url_params_hash
    return {} if url_params.blank?
    JSON.parse(url_params) rescue {}
  end

  def url_params_hash=(hash)
    self.url_params = hash.to_json
  end

  def body_params_hash
    return {} if body_params.blank?
    JSON.parse(body_params) rescue {}
  end

  def body_params_hash=(hash)
    self.body_params = hash.to_json
  end

  # 格式化duration显示
  def formatted_duration
    return 'N/A' if duration.blank?
    if duration < 1000
      "#{duration}ms"
    else
      "#{(duration / 1000.0).round(2)}s"
    end
  end

  # 判断是否为错误请求
  def error?
    status_code.present? && status_code >= 400
  end

  # 判断是否为慢请求
  def slow?(threshold_ms = 1000)
    duration.present? && duration > threshold_ms
  end

  # 获取完整的操作描述
  def action_description
    "#{request_method} #{controller_name}##{action_name}"
  end

  # 创建日志记录的便捷方法
  def self.create_from_request(user, request, start_time)
    log = new
    log.user = user
    log.controller_name = request.params[:controller]
    log.action_name = request.params[:action]
    log.request_method = request.method
    log.request_url = request.fullpath
    log.url_params = request.params.except(:controller, :action, :format).to_json
    log.body_params = request.request_parameters.to_json
    log.request_time = start_time
    log.ip_address = request.remote_ip
    log.user_agent = request.user_agent
    log
  end
end
