class AutomationRule < ApplicationRecord
  belongs_to :project

  validates :name, presence: true
  validates :time_type, presence: true, inclusion: { in: %w[recent range], message: "时间类型必须是 recent 或 range" }
  validates :time_granularity, presence: true, inclusion: { in: %w[hour day] }
  validates :time_range, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }
  validates :condition_group, presence: true
  validates :action, presence: true, inclusion: {
    in: %w[pause_ad add_ad increase_bid decrease_bid increase_budget decrease_budget],
    message: "动作类型无效"
  }

  # 验证需要action_value的动作
  validate :validate_action_value
  # 验证时间范围配置
  validate :validate_time_range_config

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }

  # JSON序列化配置
  def as_json(options = {})
    super(options.merge(
      except: [:created_at, :updated_at],
      methods: []
    ))
  end

  private

  def validate_action_value
    actions_need_value = %w[increase_bid decrease_bid increase_budget decrease_budget]

    if actions_need_value.include?(action)
      # 需要action_value的动作
      if action_value.nil? || action_value <= 0
        errors.add(:action_value, "必须大于0")
      elsif action_value > 100
        errors.add(:action_value, "不能大于100")
      end
    else
      # 不需要action_value的动作，确保action_value为nil或0
      # 这样可以避免在不需要时验证action_value
    end
  end

  def validate_time_range_config
    if time_type == 'range'
      if time_range_config.blank?
        errors.add(:time_range_config, "当时间类型为范围时，必须配置时间范围")
      else
        # 验证time_range_config的结构
        unless time_range_config.is_a?(Hash)
          errors.add(:time_range_config, "时间范围配置格式错误")
          return
        end

        start_date = time_range_config['start_date']
        end_date = time_range_config['end_date']

        if start_date.blank? || end_date.blank?
          errors.add(:time_range_config, "开始日期和结束日期不能为空")
          return
        end

        # 验证开始日期
        unless validate_date_config(start_date)
          errors.add(:time_range_config, "开始日期配置格式错误")
        end

        # 验证结束日期
        unless validate_date_config(end_date)
          errors.add(:time_range_config, "结束日期配置格式错误")
        end
      end
    end
  end

  def validate_date_config(date_config)
    return false unless date_config.is_a?(Hash)
    return false unless %w[absolute relative].include?(date_config['type'])
    return false if date_config['date'].blank?

    if date_config['type'] == 'absolute'
      # 验证是否为有效日期字符串
      begin
        Date.parse(date_config['date'].to_s)
      rescue ArgumentError
        return false
      end
    elsif date_config['type'] == 'relative'
      # 验证是否为整数
      return false unless date_config['date'].is_a?(Integer)
    end

    true
  end
end
