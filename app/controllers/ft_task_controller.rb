# frozen_string_literal: true

class FtTaskController < ApplicationController
  include DefaultCrud

  private

  # 重写set_resource方法以支持通过task_id或id查找
  def set_resource
    identifier = params[:task_id] || params[:id]

    begin
      # 首先尝试通过task_id查找
      @resource = resource_class.find_by(task_id: identifier)

      # 如果通过task_id没找到，尝试通过id查找
      if @resource.nil?
        @resource = resource_class.find(identifier)
      end

      if @resource.nil?
        raise ActiveRecord::RecordNotFound
      end
    rescue ActiveRecord::RecordNotFound
      return render json: error("#{resource_class} not found with id #{identifier}"), status: :not_found
    end
  end

  public

  def activate
    task_ids = params[:task_ids] || []
    if task_ids.empty?
      render json: error("未提供任务ID列表")
    else
      task_ids.each do |task_id|
        task = FtTask.find_by(task_id: task_id)
        if task.present?
          task.activate!
        end
      end
      render json: ok(task_ids)
    end
  end

  def deactivate
    task_ids = params[:task_ids] || []
    if task_ids.empty?
      render json: error("未提供任务ID列表")
    else
      task_ids.each do |task_id|
        task = FtTask.find_by(task_id: task_id)
        if task.present?
          task.deactivate!
        end
      end
      render json: ok(task_ids)
    end
  end

  # 执行指定任务
  def execute
    task_id = params[:task_id] || params[:id]

    begin
      @task = FtTask.find_by(task_id: task_id)

      if @task.nil?
        render json: error("Task with id #{task_id} not found")
      else
        @task.enqueue
      end
    rescue => e
      Rails.logger.error "Execute task error: #{e.message}"
      render json: error("执行任务异常: #{e.message}")
    end
  end

  # 批量执行任务
  def execute_batch
    task_ids = params[:task_ids] || []

    if task_ids.empty?
      render json: error("未提供任务ID列表")
      return
    end

    results = {}
    task_ids.each do |task_id|
      begin
        execution_service = TaskExecutionService.new(task_id)
        results[task_id] = execution_service.execute
      rescue => e
        results[task_id] = {
          success: false,
          error: e.message,
          logs: [e.message]
        }
      end
    end

    render json: ok({
                      message: "批量执行完成",
                      results: results,
                      total: task_ids.length,
                      success_count: results.values.count { |r| r[:success] },
                      failed_count: results.values.count { |r| !r[:success] }
                    })
  end

  # 检查任务是否可以执行
  def check_executable
    task_id = params[:task_id] || params[:id]

    task = FtTask.find_by(task_id: task_id)
    if task.nil?
      render json: error("Task with id #{task_id} not found")
      return
    end

    can_execute = task.can_execute_now?

    render json: ok({
                      task_id: task_id,
                      task_name: task.name,
                      task_type: task.task_type,
                      status: task.status,
                      can_execute: can_execute,
                      effective_time: task.effective_time,
                      lose_efficacy_time: task.lose_efficacy_time,
                      dependencies_satisfied: task.dependencies_satisfied?
                    })
  end

  # 获取任务列表（按条件筛选）
  def list_executable
    task_type = params[:task_type]
    status = params[:status]

    query = FtTask.includes(:catalog, :ft_flow)
    query = query.where(task_type: task_type) if task_type.present?
    query = query.where(status: status) if status.present?

    tasks = query.order(:priority, :effective_time).limit(100)

    executable_tasks = tasks.select(&:can_execute_now?)

    render json: ok({
                      total: tasks.count,
                      executable_count: executable_tasks.length,
                      tasks: executable_tasks.map do |task|
                        task.as_json(only: [:task_id, :name, :task_type, :status, :effective_time, :priority])
                      end
                    })
  end

  # 获取任务执行历史（如果需要的话）
  def execution_history
    task_id = params[:task_id] || params[:id]

    task = FtTask.find_by(task_id: task_id)
    if task.nil?
      render json: error("Task with id #{task_id} not found")
      return
    end

    render json: ok({
                      task_id: task_id,
                      task_name: task.name,
                      current_status: task.status,
                      created_at: task.created_at,
                      updated_at: task.updated_at
                    })
  end

  # 立即执行任务
  def execute_immediate
    begin
      execution_params = params.permit(
        :task_id, :execution_type, :single_date, :date_range_start, :date_range_end,
        :execute_dependencies, :execution_time_type, :delay_time,
        task_ids: [], multiple_dates: []
      )

      # 支持单个任务或批量任务执行
      task_ids = if execution_params[:task_ids].present?
                   execution_params[:task_ids]
                 elsif execution_params[:task_id].present?
                   [execution_params[:task_id]]
                 else
                   []
                 end

      if task_ids.empty?
        render json: error("任务ID不能为空"), status: :bad_request
        return
      end

      # 验证所有任务是否存在且为激活状态
      tasks = FtTask.where(task_id: task_ids)
      not_found_ids = task_ids - tasks.pluck(:task_id)

      if not_found_ids.any?
        render json: error("任务不存在: #{not_found_ids.join(', ')}"), status: :not_found
        return
      end

      # 检查任务状态
      inactive_tasks = tasks.where.not(status: 'active')
      if inactive_tasks.any?
        inactive_ids = inactive_tasks.pluck(:task_id)
        return render json: error("只能执行激活状态的任务，以下任务状态不正确: #{inactive_ids.join(', ')}")
      end

      # 处理日期参数
      execution_dates = []

      case execution_params[:execution_type]
      when 'single_date'
        execution_dates.push(execution_params[:single_date].to_date.to_s)
      when 'multiple_dates'
        execution_dates.concat(execution_params[:multiple_dates].map(&:to_date).map(&:to_s))
      when 'date_range'
        start_date = execution_params[:date_range_start].to_date
        end_date = execution_params[:date_range_end].to_date
        (start_date..end_date).each do |date|
          execution_dates.push(date.to_s)
        end
      else
        raise ArgumentError, "Invalid execution type: #{execution_params[:execution_type]}"
      end

      if execution_dates.empty?
        return render json: error("执行日期不能为空"), status: :bad_request
      end

      tasks.order(:priority).each do |task|
        execution_dates.each do |execution_date|
          params = {
            task_id: task.task_id,
            execution_type: "manual",
            run_dependencies: execution_params[:execute_dependencies].present?,
            data_time: task.period_type === 'hourly' ? execution_date + ' 00' : execution_date,
          }

          if execution_params[:execution_time_type] == 'delayed' && execution_params[:delay_time].present?
            Resque.enqueue_at(execution_params[:delay_time].to_time.to_i, FtTaskExecutionJob, params)
          else
            Resque.enqueue(FtTaskExecutionJob, params)
          end
        end
      end
      render json: ok("任务已提交执行")
    rescue ArgumentError => e
      Rails.logger.error "Invalid execution parameters: #{e.message}"
      render json: error("执行参数无效: #{e.message}"), status: :bad_request
    rescue => e
      Rails.logger.error "Immediate execution error: #{e.message}"
      render json: error("立即执行请求失败: #{e.message}"), status: :internal_server_error
    end
  end
end
