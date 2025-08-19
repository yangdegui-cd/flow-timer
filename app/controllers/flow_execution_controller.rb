# frozen_string_literal: true

class FlowExecutionController < ApplicationController

  # POST /flows/:flow_id/execute
  def execute
    begin
      input_params = params[:params] || {}

      scheduler = FlowSchedulerService.new
      result = scheduler.execute_flow(@flow.flow_id, input_params)

      if result[:success]
        render json: ok({
          flow_id: @flow.flow_id,
          execution_result: result[:result],
          logs: result[:logs],
          duration: result[:result][:end_time] ?
            (Time.parse(result[:result][:end_time].to_s) - Time.parse(result[:result][:start_time].to_s)).round(3) : nil
        })
      else
        render json: error("流程执行失败: #{result[:error]}", result)
      end

    rescue => e
      Rails.logger.error("流程执行API错误: #{e.message}")
      render json: error("流程执行失败: #{e.message}")
    end
  end

  # POST /flows/:flow_id/execute_async
  def execute_async
    begin
      input_params = params[:params] || {}

      scheduler = FlowSchedulerService.new
      job_id = scheduler.execute_flow_async(@flow.flow_id, input_params)

      render json: ok({
        flow_id: @flow.flow_id,
        job_id: job_id,
        message: "流程已加入异步执行队列"
      })

    rescue => e
      Rails.logger.error("异步流程执行API错误: #{e.message}")
      render json: error("异步流程执行失败: #{e.message}")
    end
  end

  # GET /flows/:flow_id/status
  def status
    begin
      scheduler = FlowSchedulerService.new
      status = scheduler.get_flow_status(@flow.flow_id)

      if status
        render json: ok(status)
      else
        render json: error("未找到流程执行记录")
      end

    rescue => e
      Rails.logger.error("获取流程状态API错误: #{e.message}")
      render json: error("获取流程状态失败: #{e.message}")
    end
  end

  # POST /flows/execute_batch
  def execute_batch
    begin
      flow_configs = params[:flows] || []

      if flow_configs.empty?
        return render json: error("请提供要执行的流程配置")
      end

      scheduler = FlowSchedulerService.new
      results = scheduler.execute_flows(flow_configs)

      render json: ok({
        batch_results: results,
        total_flows: flow_configs.length,
        successful_flows: results.count { |_, result| result[:success] },
        failed_flows: results.count { |_, result| !result[:success] }
      })

    rescue => e
      Rails.logger.error("批量流程执行API错误: #{e.message}")
      render json: error("批量流程执行失败: #{e.message}")
    end
  end

  # GET /flows/execution_history
  def execution_history
    begin
      limit = (params[:limit] || 50).to_i

      scheduler = FlowSchedulerService.new
      history = scheduler.get_execution_history(limit)

      render json: ok({
        executions: history,
        count: history.length
      })

    rescue => e
      Rails.logger.error("获取执行历史API错误: #{e.message}")
      render json: error("获取执行历史失败: #{e.message}")
    end
  end

  # POST /flows/:flow_id/stop
  def stop
    begin
      scheduler = FlowSchedulerService.new
      result = scheduler.stop_flow_execution(@flow.flow_id)

      render json: ok(result)

    rescue => e
      Rails.logger.error("停止流程执行API错误: #{e.message}")
      render json: error("停止流程执行失败: #{e.message}")
    end
  end

  # GET /flows/by_condition
  def execute_by_condition
    begin
      condition = {
        status: params[:status],
        catalog_id: params[:catalog_id],
        name_contains: params[:name_contains],
        limit: (params[:limit] || 10).to_i
      }.compact

      scheduler = FlowSchedulerService.new
      results = scheduler.execute_flows_by_condition(condition)

      render json: ok({
        condition: condition,
        results: results,
        executed_flows: results.keys.length
      })

    rescue => e
      Rails.logger.error("条件流程执行API错误: #{e.message}")
      render json: error("条件流程执行失败: #{e.message}")
    end
  end

  private

  def find_flow
    flow_id = params[:flow_id] || params[:id]
    @flow = FtFlow.find_by(flow_id: flow_id)

    unless @flow
      render json: error("Flow with id #{flow_id} not found")
      return
    end
  end
end
