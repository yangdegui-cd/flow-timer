class SysRoleController < ApplicationController
  before_action :check_manage_roles_permission, except: [:index, :show]
  before_action :set_role, only: [:show, :update, :destroy, :update_permissions, :permissions, :assign_permissions]

  def index
    roles = SysRole.includes(:sys_users).ordered
    render json: ok(roles.map { |role| role_summary_json(role) })
  end

  def show
    render json: ok({ sys_role: role_detail_json(@sys_role) })
  end



  def destroy
    if @sys_role.system_role?
      return render json: error('系统预定义角色不能删除'), status: :forbidden
    end

    if @sys_role.sys_users.exists?
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

  # GET /sys_role/:id/permissions - 获取角色权限
  def permissions
    permissions = @sys_role.sys_permissions.active.includes(:sys_role_permissions)
    render json: ok({
      permissions: permissions.map { |permission| permission_json(permission) }
    })
  end

  # PUT /sys_role/:id/assign_permissions - 分配权限给角色
  def assign_permissions
    permission_ids = params[:permission_ids] || []

    if permission_ids.empty?
      return render json: error('请选择要分配的权限'), status: :bad_request
    end

    # 验证权限ID是否有效
    valid_permission_ids = SysPermission.where(id: permission_ids).pluck(:id)
    invalid_ids = permission_ids.map(&:to_i) - valid_permission_ids

    if invalid_ids.any?
      return render json: error("无效的权限ID: #{invalid_ids.join(', ')}"), status: :unprocessable_entity
    end

    if @sys_role.assign_permissions(permission_ids: valid_permission_ids)
      render json: ok({
        message: '权限分配成功',
        assigned_count: valid_permission_ids.count
      })
    else
      render json: error('权限分配失败'), status: :internal_server_error
    end
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
      system_role: role.is_system?,
      user_count: role.sys_users.count,
      permissions: role.sys_permissions,
      created_at: role.created_at
    }
  end

  def role_detail_json(role)
    role_summary_json(role).merge(
      permissions: role.sys_permissions,
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

  def permission_json(permission)
    {
      id: permission.id,
      code: permission.code,
      name: permission.name,
      description: permission.description,
      module: permission.module,
      action: permission.action,
      resource: permission.resource,
      is_active: permission.is_active,
      is_system: permission.is_system,
      sort_order: permission.sort_order,
      created_at: permission.created_at,
      updated_at: permission.updated_at
    }
  end
end
