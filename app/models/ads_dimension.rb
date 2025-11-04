class AdsDimension < ApplicationRecord
  validates :display_name, presence: true
  validates :name, presence: true, uniqueness: true
  validates :column, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :asc) }
end
