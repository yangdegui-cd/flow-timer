class SysUserProjectsController < ApplicationController
  include AutomationLoggable

  skip_before_action :authenticate_user!
  skip_before_action :validate_permission!

  def index
    @user_projects = SysUserProject.includes(:sys_user, :project).all
    render json: @user_projects.as_json(
      include: {
        sys_user: {
          only: [:id, :name, :email],
          methods: [:initials]
        },
        project: {
          only: [:id, :name, :start_date, :active_ads_automate, :status]
        }
      },
      methods: [:role_name]
    )
  end

  def user_projects
    user = SysUser.find(params[:user_id])
    projects = user.projects.includes(:sys_users, :sys_user_projects)

    render json: projects.as_json(
      include: {
        sys_users: {
          only: [:id, :name, :email],
          methods: [:initials]
        }
      },
      methods: [:user_count]
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: '用户不存在' }, status: :not_found
  end

  def project_users
    project = Project.find(params[:project_id])
    user_projects = project.sys_user_projects.includes(:sys_user)

    render json: user_projects.as_json(
      include: {
        sys_user: {
          only: [:id, :name, :email, :status],
          methods: [:initials]
        }
      },
      only: [:id, :role, :assigned_at],
      methods: [:role_name]
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: '项目不存在' }, status: :not_found
  end

  def create
    @user_project = SysUserProject.new(user_project_params)
    @user_project.assigned_at = Time.current

    if @user_project.save
      log_automation_action(
        project: @user_project.project,
        action_type: '项目编辑',
        action: '添加项目成员',
        status: 'success',
        remark: {
          project_name: @user_project.project.name,
          user_name: @user_project.sys_user.name,
          user_id: @user_project.sys_user_id,
          role: @user_project.role
        },
        user: current_user
      )
      render json: ok(@user_project.as_json(
        include: {
          sys_user: {
            only: [:id, :name, :email],
            methods: [:initials]
          },
          project: {
            only: [:id, :name, :start_date, :active_ads_automate, :status]
          }
        },
        methods: [:role_name]
      ))
    else
      render json: error(@user_project.errors.full_messages)
    end
  end

  def update
    @user_project = SysUserProject.find(params[:id])

    if @user_project.update(user_project_params)
      changes = @user_project.previous_changes.except('updated_at')
      log_automation_action(
        project: @user_project.project,
        action_type: '项目编辑',
        action: '更新项目成员角色',
        status: 'success',
        remark: {
          project_name: @user_project.project.name,
          user_name: @user_project.sys_user.name,
          user_id: @user_project.sys_user_id,
          changes: changes
        },
        user: current_user
      )
      render json: @user_project.as_json(
        include: {
          sys_user: {
            only: [:id, :name, :email],
            methods: [:initials]
          },
          project: {
            only: [:id, :name, :start_date, :active_ads_automate, :status]
          }
        },
        methods: [:role_name]
      )
    else
      log_automation_action(
        project: @user_project.project,
        action_type: '项目编辑',
        action: '更新项目成员角色失败',
        status: 'failed',
        remark: {
          project_name: @user_project.project.name,
          user_name: @user_project.sys_user.name,
          user_id: @user_project.sys_user_id,
          errors: @user_project.errors.full_messages
        },
        user: current_user
      )
      render json: {
        errors: @user_project.errors.full_messages,
        details: @user_project.errors
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: '用户项目关联不存在' }, status: :not_found
  end

  def destroy
    @user_project = SysUserProject.find(params[:id])
    project = @user_project.project
    user_name = @user_project.sys_user.name
    user_id = @user_project.sys_user_id

    @user_project.destroy

    log_automation_action(
      project: project,
      action_type: '项目编辑',
      action: '移除项目成员',
      status: 'success',
      remark: {
        project_name: project.name,
        user_name: user_name,
        user_id: user_id
      },
      user: current_user
    )

    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: '用户项目关联不存在' }, status: :not_found
  end

  def bulk_assign
    project_id = params[:project_id]
    user_assignments = params[:user_assignments] || []

    begin
      Project.transaction do
        project = Project.find(project_id)

        # 移除现有关联
        project.sys_user_projects.destroy_all

        # 批量创建新关联
        user_assignments.each do |assignment|
          user = SysUser.find(assignment[:user_id])
          project.sys_user_projects.create!(
            sys_user: user,
            role: assignment[:role] || 'member',
            assigned_at: Time.current
          )
        end

        log_automation_action(
          project: project,
          action_type: '项目编辑',
          action: '批量分配项目成员',
          status: 'success',
          remark: {
            project_name: project.name,
            user_assignments: user_assignments,
            user_count: user_assignments.length
          },
          user: current_user
        )

        render json: {
          message: '批量分配成功',
          project: project.reload.as_json(
            include: {
              sys_users: {
                only: [:id, :name, :email],
                methods: [:initials]
              }
            }
          )
        }
      end
    rescue ActiveRecord::RecordNotFound => e
      project = Project.find_by(id: project_id)
      if project
        log_automation_action(
          project: project,
          action_type: '项目编辑',
          action: '批量分配项目成员失败',
          status: 'failed',
          remark: {
            project_name: project.name,
            user_assignments: user_assignments,
            error: e.message
          },
          user: current_user
        )
      end
      render json: { error: "记录不存在: #{e.message}" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      project = Project.find_by(id: project_id)
      if project
        log_automation_action(
          project: project,
          action_type: '项目编辑',
          action: '批量分配项目成员失败',
          status: 'failed',
          remark: {
            project_name: project.name,
            user_assignments: user_assignments,
            error: e.record.errors.full_messages
          },
          user: current_user
        )
      end
      render json: { error: "分配失败: #{e.record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
    rescue => e
      project = Project.find_by(id: project_id)
      if project
        log_automation_action(
          project: project,
          action_type: '项目编辑',
          action: '批量分配项目成员失败',
          status: 'failed',
          remark: {
            project_name: project.name,
            user_assignments: user_assignments,
            error: e.message
          },
          user: current_user
        )
      end
      render json: { error: "系统错误: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def user_project_params
    params.require(:sys_user_project).permit(:sys_user_id, :project_id, :role)
  end
end
