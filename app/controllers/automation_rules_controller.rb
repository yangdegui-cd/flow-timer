class AutomationRulesController < ApplicationController
  include AutomationLoggable

  skip_before_action :authenticate_user!
  skip_before_action :validate_permission!
  before_action :set_project, only: [:index, :create]
  before_action :set_automation_rule, only: [:show, :update, :destroy, :toggle]

  # GET /projects/:project_id/automation_rules
  def index
    @rules = @project.automation_rules.order(created_at: :desc)
    render json: ok(@rules)
  end

  # GET /automation_rules/:id
  def show
    render json: ok(@rule)
  end

  # POST /projects/:project_id/automation_rules
  def create
    # 调试：打印接收到的参数
    Rails.logger.info "Received params: #{params.inspect}"
    Rails.logger.info "Automation rule params: #{automation_rule_params.inspect}"

    @rule = @project.automation_rules.new(automation_rule_params)

    if @rule.save
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '创建自动化规则',
        status: 'success',
        remark: {
          project_name: @project.name,
          rule_name: @rule.name,
          rule_id: @rule.id,
          params: automation_rule_params.to_h
        },
        user: current_user
      )
      render json: ok(@rule), status: :created
    else
      Rails.logger.error "Validation errors: #{@rule.errors.full_messages}"
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '创建自动化规则失败',
        status: 'failed',
        remark: {
          project_name: @project.name,
          params: automation_rule_params.to_h,
          errors: @rule.errors.full_messages
        },
        user: current_user
      )
      render json: error(@rule.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  # PUT /automation_rules/:id
  def update
    if @rule.update(automation_rule_params)
      changes = @rule.previous_changes.except('updated_at')
      log_automation_action(
        project: @rule.project,
        action_type: '项目编辑',
        action: '更新自动化规则',
        status: 'success',
        remark: {
          project_name: @rule.project.name,
          rule_name: @rule.name,
          rule_id: @rule.id,
          changes: changes,
          params: automation_rule_params.to_h
        },
        user: current_user
      )
      render json: ok(@rule)
    else
      log_automation_action(
        project: @rule.project,
        action_type: '项目编辑',
        action: '更新自动化规则失败',
        status: 'failed',
        remark: {
          project_name: @rule.project.name,
          rule_name: @rule.name,
          rule_id: @rule.id,
          params: automation_rule_params.to_h,
          errors: @rule.errors.full_messages
        },
        user: current_user
      )
      render json: error(@rule.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  # DELETE /automation_rules/:id
  def destroy
    project = @rule.project
    rule_name = @rule.name
    rule_id = @rule.id

    @rule.destroy

    log_automation_action(
      project: project,
      action_type: '项目编辑',
      action: '删除自动化规则',
      status: 'success',
      remark: {
        project_name: project.name,
        rule_name: rule_name,
        rule_id: rule_id
      },
      user: current_user
    )

    render json: ok(nil, '规则删除成功')
  end

  # PATCH /automation_rules/:id/toggle
  def toggle
    enabled = params[:enabled]

    if enabled.nil?
      render json: error('缺少enabled参数'), status: :bad_request
      return
    end

    if @rule.update(enabled: enabled)
      log_automation_action(
        project: @rule.project,
        action_type: '项目编辑',
        action: "#{enabled ? '启用' : '禁用'}自动化规则",
        status: 'success',
        remark: {
          project_name: @rule.project.name,
          rule_name: @rule.name,
          rule_id: @rule.id,
          enabled: enabled
        },
        user: current_user
      )
      render json: ok(@rule, "规则已#{enabled ? '启用' : '禁用'}")
    else
      log_automation_action(
        project: @rule.project,
        action_type: '项目编辑',
        action: "#{enabled ? '启用' : '禁用'}自动化规则失败",
        status: 'failed',
        remark: {
          project_name: @rule.project.name,
          rule_name: @rule.name,
          rule_id: @rule.id,
          enabled: enabled,
          errors: @rule.errors.full_messages
        },
        user: current_user
      )
      render json: error(@rule.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: error('项目不存在'), status: :not_found
  end

  def set_automation_rule
    @rule = AutomationRule.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('规则不存在'), status: :not_found
  end

  def automation_rule_params
    # 从嵌套的automation_rule参数中获取数据（如果存在）
    # 否则从顶层参数获取
    source_params = params[:automation_rule] || params

    # 提取允许的参数
    permitted = ActionController::Parameters.new(
      name: source_params[:name],
      time_type: source_params[:time_type],
      time_granularity: source_params[:time_granularity],
      time_range: source_params[:time_range],
      action: source_params[:action],
      action_value: source_params[:action_value],
      enabled: source_params[:enabled]
    )

    # 单独处理condition_group，转换为Hash
    if source_params[:condition_group].present?
      permitted[:condition_group] = source_params[:condition_group].to_unsafe_h
    end

    # 单独处理time_range_config，转换为Hash
    if source_params[:time_range_config].present?
      permitted[:time_range_config] = source_params[:time_range_config].to_unsafe_h
    end

    permitted.permit!
  end
end
