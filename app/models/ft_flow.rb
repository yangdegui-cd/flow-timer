class FtFlow < ApplicationRecord
  self.create_fields = [:name, :description, :catalog_id, :version_id, :params]
  self.update_fields = [:name, :description, :catalog_id, :version_id]
  self.show_fields = [:id, :flow_id, :name, :description, :catalog_id, :version_id, :params,:created_at, :status, :ft_flow_version, :updated_at]
  self.search_fields = [:name, :description]

  before_create :set_flow_id
  has_one :catalog
  has_one :ft_flow_version, class_name: 'FtFlowVersion', primary_key: 'version_id', foreign_key: 'id'

  def set_flow_id
    self.flow_id ||= SecureRandom.uuid
  end

  def list_json
    {
      id: id,
      flow_id: flow_id,
      name: name,
      description: description,
      catalog_id: catalog_id,
      version_id: version_id,
      params: params || [],
      created_at: created_at,
      status: status || 'draft',
      ft_flow_version: ft_flow_version&.as_json(only: [:id, :flow_id, :version, :flow_config, :created_at]) || {},
      task_count: get_task_count,
      last_run_at: last_run_at,
      run_count: run_count || 0,
      success_rate: calculate_success_rate
    }
  end

  def get_task_count
    FtTask.where(flow_id: flow_id).count
  end

  def calculate_success_rate
    total_runs = run_count || 0
    return 0 if total_runs == 0

    successful_runs = FtTask.joins(:ft_flow).where(ft_flows: { flow_id: flow_id }, status: 'success').count
    return 0 if successful_runs == 0

    ((successful_runs.to_f / total_runs) * 100).round(1)
  end
end
