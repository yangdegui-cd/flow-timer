class AutomationRule < ApplicationRecord
  belongs_to :project

  validates :name, presence: true
  validates :time_granularity, presence: true, inclusion: { in: %w[hour day] }
  validates :time_range, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }
  validates :condition_group, presence: true
  validates :action, presence: true, inclusion: {
    in: %w[pause_ad add_ad increase_bid decrease_bid increase_budget decrease_budget],
    message: "动作类型无效"
  }

  # 验证需要action_value的动作
  validate :validate_action_value

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
end
