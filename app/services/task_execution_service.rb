# frozen_string_literal: true

class TaskExecutionService < ApplicationService
  # 任务执行服务，处理任务的执行逻辑
  # 支持一次性任务、周期性任务和依赖任务
  # 使用FlowExecutionService来执行关联的流程

  # @param task_id [String] 任务ID
  # @raise [RuntimeError] 如果任务不存在
  attr_reader :task, :execution_log

  def initialize(params)
    super()
    params.deep_symbolize_keys!
    @task = FtTask.find_by(task_id: params[:task_id])
    @execution_type = params[:execution_type]
    @data_time = params[:data_time] || default_date_time
    @run_dependencies = params[:run_dependencies]
    raise "Task with id #{task_id} not found" unless @task
  end

  def execute
    log_info("开始执行任务: #{@task.name} (#{@task.task_id})")
    log_info("任务类型: #{@task.task_type}")

    begin
      @task_execution = create_task_execution

      log_info("创建任务执行记录: #{@task_execution.execution_id}")

      # 标记执行记录为运行中
      @task_execution.running!

      # 获取关联的flow
      flow = FtFlow.find_by(flow_id: @task.flow_id)

      raise "Flow with id #{@task.flow_id} not found" unless flow
      log_info("开始执行关联的流程: #{flow.name} (#{flow.flow_id})")

      # 准备执行参数
      execution_params = prepare_execution_params

      flow_execution_service = FlowExecutionService.new(flow.flow_id, @task_execution.execution_id)
      flow_execution_service.execute(execution_params)

      execute_dependencies
    rescue => e
      @task_execution&.mark_as_failed!(e.message)
      log_error("任务执行异常: #{e.message}")
      log_error("错误堆栈: #{e.backtrace.first(3).join('\n')}")

      {
        success: false,
        task_id: @task.task_id,
        flow_id: @task.flow_id,
        execution_id: @task_execution&.execution_id,
        error: e.message,
        logs: @logs
      }
    end
  end

  def execute_dependencies
    return unless @run_dependencies
    if @task.next_dependents.present?
      @task.next_dependents.each do |dependency|
        if dependency.can_run_with_dependencies?(@data_time)
          dependency.enqueue_with_dependencies(@data_time, @execution_type)
        end
      end
    end
  end

  private

  # 创建任务执行记录
  def create_task_execution
    @task.ft_task_executions.create!(
      execution_type: @execution_type,
      data_time: @data_time,
      task_id: @task.task_id,
      system_params: @task.system_params(@data_time) || {},
      custom_params: @task.params || {},
      queue: @task.queue || 'default',
      status: 'pending'
    )
  end

  def prepare_execution_params
    @task_execution.custom_params.merge(@task_execution.system_params)
  end

  def default_date_time
    Time.now.strftime(@task.period_type == "hour" ? "%Y-%m-%d %H" : "%Y-%m-%d")
  end

end
