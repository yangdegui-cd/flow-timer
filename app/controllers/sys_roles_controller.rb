class SysRolesController < ApplicationController
  before_action :check_manage_roles_permission, except: [:index, :show]
  before_action :set_role, only: [:show, :update, :destroy, :update_permissions]

  def index
    roles = SysRole.includes(:users).ordered

    render json: ok({
      roles: roles.map { |role| role_summary_json(role) }
    })
  end

  def show
    render json: ok({ sys_role: role_detail_json(@sys_role) })
  end

  def create
    role = SysRole.new(role_params)

    if role.save
      render json: ok({
        sys_role: role_detail_json(role),
        message: '角色创建成功'
      })
    else
      render json: error(role.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def update
    # 系统预定义角色不允许修改名称
    update_params = @sys_role.system_role? ? role_params.except(:name) : role_params

    if @sys_role.update(update_params)
      render json: ok({
                        sys_role: role_detail_json(@sys_role),
                        message: '角色更新成功'
      })
    else
      render json: error(@sys_role.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def destroy
    if @sys_role.system_role?
      return render json: error('系统预定义角色不能删除'), status: :forbidden
    end

    if @sys_role.users.exists?
      return render json: error('该角色下还有用户，不能删除'), status: :conflict
    end

    if @sys_role.destroy
      render json: ok({ message: '角色删除成功' })
    else
      render json: error('角色删除失败'), status: :internal_server_error
    end
  end

  def update_permissions
    permissions = params[:permissions] || []

    # 验证权限是否有效
    invalid_permissions = permissions - SysRole.available_permissions
    if invalid_permissions.any?
      return render json: error("无效的权限: #{invalid_permissions.join(', ')}"), status: :unprocessable_entity
    end

    if @sys_role.update(permissions: permissions)
      render json: ok({
                        sys_role: role_detail_json(@sys_role),
                        message: '权限更新成功'
      })
    else
      render json: error(@sys_role.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def available_permissions
    render json: ok({
      permissions: SysRole.available_permissions,
      descriptions: SysRole.permission_descriptions,
      grouped_permissions: grouped_permissions
    })
  end

  private

  def check_manage_roles_permission
    require_permission!('manage_roles')
  end

  def set_role
    @sys_role = SysRole.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('角色不存在'), status: :not_found
  end

  def role_params
    params.permit(:name, :description, permissions: [])
  end

  def role_summary_json(role)
    {
      id: role.id,
      name: role.name,
      display_name: role.display_name,
      description: role.description,
      system_role: role.system_role?,
      user_count: role.users.count,
      permission_count: role.permissions.length,
      created_at: role.created_at
    }
  end

  def role_detail_json(role)
    role_summary_json(role).merge(
      permissions: role.permissions,
      users: role.users.active.limit(10).map do |user|
        {
          id: user.id,
          name: user.name,
          email: user.email,
          avatar_url: user.avatar_url
        }
      end,
      total_users: role.users.count
    )
  end

  def grouped_permissions
    {
      'user_management' => {
        'label' => '用户管理',
        'permissions' => ['manage_users', 'manage_roles']
      },
      'task_management' => {
        'label' => '任务管理',
        'permissions' => ['manage_tasks', 'create_tasks', 'edit_tasks', 'delete_tasks', 'view_tasks']
      },
      'flow_management' => {
        'label' => '流程管理',
        'permissions' => ['manage_flows', 'create_flows', 'edit_flows', 'delete_flows', 'view_flows']
      },
      'execution_management' => {
        'label' => '执行管理',
        'permissions' => ['manage_executions', 'view_executions']
      },
      'monitoring' => {
        'label' => '系统监控',
        'permissions' => ['view_resque_monitor']
      },
      'system' => {
        'label' => '系统管理',
        'permissions' => ['manage_system']
      }
    }
  end
end
