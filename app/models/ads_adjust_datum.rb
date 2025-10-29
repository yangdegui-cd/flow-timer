# frozen_string_literal: true

class AdsAdjustDatum < ApplicationRecord
  # 关联
  belongs_to :project

  # 验证
  validates :date, presence: true
  validates :unique_key, presence: true

  # 作用域
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :active, -> { where(data_status: 'active') }
  scope :recent, -> { order(date: :desc, hour: :desc) }

  # 回调：保存前生成唯一键和计算指标
  before_validation :generate_unique_key
  before_save :set_time_dimensions

  # 生成唯一键
  def generate_unique_key
    return if unique_key.present?
    key_parts = [
      project_id,
      date,
      hour,
      campaign_network,
      adgroup_network,
      creative_network,
    ].compact

    self.unique_key = Digest::MD5.hexdigest(key_parts.join('_'))
  end

  # 设置时间维度字段
  def set_time_dimensions
    return unless date.present?

    date_obj = date.is_a?(Date) ? date : Date.parse(date.to_s)

    if hour.present?
      hour_int = hour.to_i
      self.datetime = date_obj.to_time + hour_int.hours
    end
  end

  # 类方法：删除指定日期范围的旧数据
  def self.delete_for_date_range(project_id, start_date, end_date)
    where(project_id: project_id, date: start_date..end_date).delete_all
  end
end
