class AutomationLog < ApplicationRecord
  # 关联关系
  belongs_to :project
  belongs_to :sys_user, optional: true

  # 验证
  validates :action_type, presence: true, inclusion: {
    in: %w[项目编辑 规则触发 定时任务 调整广告投放],
    message: '必须是: 项目编辑, 规则触发, 定时任务, 调整广告投放 之一'
  }
  validates :status, presence: true, inclusion: {
    in: %w[success failed],
    message: '必须是: success 或 failed'
  }

  # 枚举
  enum status: {
    success: 'success',
    failed: 'failed'
  }, _prefix: true

  # 作用域
  scope :recent, -> { order(created_at: :desc) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_action_type, ->(action_type) { where(action_type: action_type) }
  scope :success_only, -> { where(status: 'success') }
  scope :failed_only, -> { where(status: 'failed') }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # 类方法 - 创建日志
  def self.log_action(project:, action_type:, action:, user: nil, duration: nil, status: 'success', remark: nil)
    create!(
      project: project,
      sys_user: user,
      action_type: action_type,
      action: action,
      duration: duration,
      status: status,
      remark: remark
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create automation log: #{e.message}"
    nil
  end

  # 实例方法
  def duration_in_seconds
    return nil unless duration
    (duration / 1000.0).round(2)
  end

  def success?
    status == 'success'
  end

  def failed?
    status == 'failed'
  end

  def display_action_type
    action_type
  end

  def display_status
    case status
    when 'success'
      '成功'
    when 'failed'
      '失败'
    else
      status
    end
  end

  def display_name
    case action_type
    when '项目编辑'
      action
    when '规则触发'
      "广告: \"#{remark["ad_name"]}\" 触发自动化投放规则: \"#{remark["rule"]["name"]}\""
    when '定时任务'
      action
    when '调整广告投放'
      action
    else
      action
    end
  end

  # JSON序列化
  def as_json(options = {})
    super(options.merge(
      include: {
        project: { only: [:id, :name] },
        sys_user: { only: [:id, :name, :email] }
      },
      methods: [:duration_in_seconds, :display_status, :display_name]
    ))
  end
end
