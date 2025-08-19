# frozen_string_literal: true

class FtFlowController < ApplicationController

  def create
    flow_config = params[:flow_config]
    begin
      ApplicationRecord.transaction do
        @ft_flow = FtFlow.new(params.permit(FtFlow.create_fields))
        Rails.logger.info "Creating FtFlow with params: #{params.permit(FtFlow.create_fields)}"
        @ft_flow.set_flow_id
        @ft_flow.params = get_params_in_flow(flow_config) || {}
        @ft_flow_version = FtFlowVersion.create!({ flow_id: @ft_flow.flow_id, version: 1, flow_config: flow_config })
        @ft_flow.version_id = @ft_flow_version.id
        @ft_flow.save!
        render json: ok(@ft_flow.as_json(only: FtFlow.show_fields))
      end
    rescue => e
      e.backtrace.each { |line| Rails.logger.error line }
      Rails.logger.error "JSON parsing error: #{e.message}"
      render json: error("Failed to create FtFlow: #{e.message}")
    end
  end

  def current_version
    @ft_flow = FtFlow.where(id: params[:id]).includes(:ft_flow_version).first
    if @ft_flow.present?
      render json: ok(@ft_flow.ft_flow_version.as_json(only: [:id, :flow_id, :version, :flow_config, :created_at]))
    else
      render json: error("FtFlow with id #{params[:id]} not found")
    end
  end

  def get_tree_list
    ft_flows = FtFlow.select("flow_id, name, catalog_id").all.to_a.group_by(&:catalog_id)
    spaces = Space.includes(:catalogs).where(space_type: "FLOW").all.to_a
    res = []
    spaces.each do |space|
      space.catalogs.each do |catalog|
        res << {
          label: "#{space.name} / #{catalog.name}",
          children: (ft_flows[catalog.id] || []).map { |flow|
            {
              label: flow.name,
              key: flow.flow_id,
            }
          }
        }
      end
    end
    render json: ok(res)
  end

  # 批量更新状态
  def batch_update_status
    flow_ids = params[:flow_ids] || []
    status = params[:status]

    if flow_ids.empty? || status.blank?
      render json: error("Missing flow_ids or status parameter")
      return
    end

    begin
      updated_count = FtFlow.where(id: flow_ids).update_all(status: status, updated_at: Time.current)
      render json: ok({ updated_count: updated_count, message: "Successfully updated #{updated_count} flows" })
    rescue => e
      render json: error("Failed to update flows: #{e.message}")
    end
  end

  # 批量删除
  def batch_delete
    flow_ids = params[:flow_ids] || []

    if flow_ids.empty?
      render json: error("Missing flow_ids parameter")
      return
    end

    begin
      ApplicationRecord.transaction do
        # 先删除相关的任务
        FtTask.where(flow_id: FtFlow.where(id: flow_ids).pluck(:flow_id)).delete_all
        # 删除流程版本
        FtFlowVersion.where(flow_id: FtFlow.where(id: flow_ids).pluck(:flow_id)).delete_all
        # 删除流程
        deleted_count = FtFlow.where(id: flow_ids).delete_all

        render json: ok({ deleted_count: deleted_count, message: "Successfully deleted #{deleted_count} flows" })
      end
    rescue => e
      render json: error("Failed to delete flows: #{e.message}")
    end
  end

  # 获取流程统计信息
  def statistics
    catalog_ids = Array(params[:catalog_ids] || [])

    flows_query = FtFlow.all
    flows_query = flows_query.where(catalog_id: catalog_ids) if catalog_ids.present?

    stats = {
      total_flows: flows_query.count,
      active_flows: flows_query.where(status: 'active').count,
      inactive_flows: flows_query.where(status: 'inactive').count,
      draft_flows: flows_query.where(status: 'draft').count,
      error_flows: flows_query.where(status: 'error').count,
      total_tasks: FtTask.joins(:ft_flow).where(ft_flows: { catalog_id: catalog_ids.present? ? catalog_ids : FtFlow.distinct.pluck(:catalog_id) }).count
    }

    render json: ok(stats)
  end

  private

  def get_params_in_flow(flow_config)
    flow_config = flow_config.as_json.deep_symbolize_keys
    Rails.logger.info "Extracting flow parameters from config: #{flow_config}"
    nodes = flow_config[:nodes] || []

    params_config = nodes.select { |node| node[:data][:node_type] == 'flow_params' }.first
    if params_config.present?
      params_config[:data][:config][:params] || []
    else
      Array.new
    end
  end
end

