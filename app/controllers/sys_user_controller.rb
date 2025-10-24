class SysUserController < ApplicationController
  before_action :set_user, only: [:show, :update, :destroy, :change_status, :assign_roles, :remove_role]

  def index
    query = JSON.parse(params[:query] || '{}')

    users = SysUser.includes(:sys_roles, :sys_oauth_providers).where(query)

    render json: ok({ users: users.map { |user| user_json(user) }})
  end

  def show
    render json: ok({ sys_user: user_detail_json(@sys_user) })
  end

  def create
    return unless require_permission!('manage_users')

    user = SysUser.new(user_params)

    if user.save
      # 分配默认角色
      if params[:roles].present?
        assign_user_roles(user, params[:roles])
      else
        user.add_role('viewer')
      end

      render json: ok({
                        sys_user: user_detail_json(user),
                        message: '用户创建成功'
                      })
    else
      render json: error(user.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def change_status
    if @sys_user == current_user && params[:status] != 'active'
      return render json: error('不能修改自己的账号状态'), status: :forbidden
    end

    if @sys_user.update(status: params[:status])
      render json: ok({
                        sys_user: user_json(@sys_user),
                        message: "用户状态已更新为#{@sys_user.status}"
                      })
    else
      render json: error(@sys_user.errors.full_messages.join(', ')), status: :unprocessable_entity
    end
  end

  def assign_roles
    role_ids = params[:role_ids] || []

    # 移除所有现有角色
    @sys_user.sys_user_roles.destroy_all

    # 分配新角色
    role_ids.each do |role_id|
      role = SysRole.find_by(id: role_id)
      @sys_user.sys_user_roles.find_or_create_by(sys_role: role) if role
    end

    render json: ok({
                      sys_user: user_detail_json(@sys_user),
                      message: '角色分配成功'
                    })
  end

  def remove_role
    role_name = params[:role_name]

    if @sys_user.remove_role(role_name)
      render json: ok({
                        sys_user: user_detail_json(@sys_user),
                        message: "角色#{role_name}移除成功"
                      })
    else
      render json: error('角色移除失败'), status: :unprocessable_entity
    end
  end

  def roles
    render json: ok({ roles: SysRole.ordered.map { |role| role_json(role) } })
  end


  private

  def set_user
    @sys_user = SysUser.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('用户不存在'), status: :not_found
  end

  def user_params
    params.permit(:email, :password, :name, :avatar_url, :status)
  end


  def assign_user_roles(user, role_names)
    role_names.each do |role_name|
      role = SysRole.find_by(name: role_name)
      user.user_roles.find_or_create_by(sys_role: role) if role
    end
  end

  def build_search_conditions
    conditions = {}

    conditions[:status] = params[:status] if params[:status].present?
    conditions[:email] = { like: "%#{params[:email]}%" } if params[:email].present?
    conditions[:name] = { like: "%#{params[:name]}%" } if params[:name].present?

    conditions
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar_url: user.avatar_url,
      status: user.status,
      last_login_at: user.last_login_at,
      created_at: user.created_at,
      roles: user.sys_roles.map { |role| { id: role.id, name: role.name, display_name: role.display_name } },
      oauth_providers: user.sys_oauth_providers.map(&:provider)
    }
  end

  def user_detail_json(user)
    user_json(user).merge(
      permissions: user.permissions,
      oauth_accounts: user.sys_oauth_providers.map do |oauth|
        {
          provider: oauth.provider,
          provider_name: oauth.provider_name,
          display_info: oauth.display_info,
          connected_at: oauth.created_at,
          valid_token: oauth.valid_token?
        }
      end
    )
  end

  def role_json(role)
    {
      id: role.id,
      name: role.name,
      display_name: role.display_name,
      description: role.description,
      permissions: role.sys_permissions,
      system_role: role.is_system?,
      user_count: role.users.count
    }
  end

  def pagination_info(collection)
    {
      current_page: collection.current_page,
      per_page: collection.limit_value,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
