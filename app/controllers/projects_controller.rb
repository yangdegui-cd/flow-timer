class ProjectsController < ApplicationController
  include AutomationLoggable

  skip_before_action :authenticate_user!
  skip_before_action :validate_permission!
  before_action :set_project, only: [:show, :update, :destroy, :assign_users]

  def index
    @projects = Project.includes(:sys_users).all
    render json: ok(@projects.as_json(
      include: {
        sys_users: {
          only: [:id, :name, :email],
          methods: [:initials]
        }
      },
      methods: [:user_count]
    ))
  end

  def show
    render json: ok(@project.as_json(
      include: {
        sys_users: {
          only: [:id, :name, :email],
          methods: [:initials]
        },
        sys_user_projects: {
          only: [:role, :assigned_at],
          include: {
            sys_user: {
              only: [:id, :name, :email]
            }
          }
        }
      }
    ))
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '创建项目',
        status: 'success',
        remark: {
          project_name: @project.name,
          params: project_params.to_h
        },
        user: current_user
      )
      render json: ok(@project), status: :created
    else
      render json: error(@project.errors.full_messages.join(', '))
    end
  end

  def update
    old_attributes = @project.attributes.slice('name', 'start_date', 'active_ads_automate', 'description', 'status')

    if @project.update(project_params)
      changes = @project.previous_changes.except('updated_at')
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '更新项目',
        status: 'success',
        remark: {
          project_name: @project.name,
          changes: changes,
          params: project_params.to_h
        },
        user: current_user
      )
      render json: ok(@project.as_json(
        include: {
          sys_users: {
            only: [:id, :name, :email],
            methods: [:initials]
          }
        }
      ))
    else
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '更新项目失败',
        status: 'failed',
        remark: {
          project_name: @project.name,
          params: project_params.to_h,
          errors: @project.errors.full_messages
        },
        user: current_user
      )
      render json: error(@project.errors.full_messages.join(', '))
    end
  end

  def destroy
    project_name = @project.name
    project_id = @project.id

    @project.destroy

    # 注意：删除后project已被销毁，无法再记录日志到该项目
    # 这里可以选择记录到系统日志或跳过
    Rails.logger.info "Project deleted: #{project_name} (ID: #{project_id})"

    render json: ok(nil, '项目删除成功')
  end

  def assign_users
    user_ids = params[:user_ids] || []
    role = params[:role] || 'member'

    begin
      Project.transaction do
        # 移除现有关联
        @project.sys_user_projects.destroy_all

        # 创建新关联
        user_ids.each do |user_id|
          user = SysUser.find(user_id)
          @project.sys_user_projects.create!(
            sys_user: user,
            role: role,
            assigned_at: Time.current
          )
        end
      end

      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '批量分配用户',
        status: 'success',
        remark: {
          project_name: @project.name,
          user_ids: user_ids,
          role: role,
          user_count: user_ids.length
        },
        user: current_user
      )

      render json: ok(@project.reload.as_json(
        include: {
          sys_users: {
            only: [:id, :name, :email],
            methods: [:initials]
          }
        }
      ), '用户分配成功')
    rescue ActiveRecord::RecordNotFound => e
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '批量分配用户失败',
        status: 'failed',
        remark: {
          project_name: @project.name,
          user_ids: user_ids,
          role: role,
          error: e.message
        },
        user: current_user
      )
      render json: error("用户不存在: #{e.message}"), status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '批量分配用户失败',
        status: 'failed',
        remark: {
          project_name: @project.name,
          user_ids: user_ids,
          role: role,
          error: e.record.errors.full_messages
        },
        user: current_user
      )
      render json: error("分配失败: #{e.record.errors.full_messages.join(', ')}"), status: :unprocessable_entity
    rescue => e
      log_automation_action(
        project: @project,
        action_type: '项目编辑',
        action: '批量分配用户失败',
        status: 'failed',
        remark: {
          project_name: @project.name,
          user_ids: user_ids,
          role: role,
          error: e.message
        },
        user: current_user
      )
      render json: error("系统错误: #{e.message}"), status: :internal_server_error
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('项目不存在'), status: :not_found
  end

  def project_params
    params.require(:project).permit(:name, :start_date, :active_ads_automate, :description, :status)
  end

  def authenticate_user!
    # 这里可以添加用户认证逻辑
    # 暂时跳过认证，实际使用时需要实现
    # true
  end
end
