class FtFlowVersion < ApplicationRecord
  validates :version, presence: true
  validates :flow_config, presence: true

  def self.get_all_versions(flow_id)
    where(flow_id: flow_id).order(version: :desc)
  end
end
