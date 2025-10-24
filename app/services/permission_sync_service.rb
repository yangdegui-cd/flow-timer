class PermissionSyncService
  # 不需要权限检查的控制器
  EXCLUDED_CONTROLLERS = %w[
    auth
    rails/health
    rails/info
    rails/mailers
    resque-scheduler/server
    action_cable/server
    sys_permission_group
  ].freeze

  # 不需要权限检查的动作
  EXCLUDED_ACTIONS = %w[
    new
    edit
    show_result
  ].freeze

  # HTTP方法到动作类型的映射
  HTTP_METHOD_ACTIONS = {
    'GET' => 'read',
    'POST' => 'create',
    'PUT' => 'update',
    'PATCH' => 'update',
    'DELETE' => 'delete'
  }.freeze

  class << self
    def sync_all_permissions
      Rails.logger.info "开始同步权限系统..."

      # 1. 同步基于路由的权限
      route_permissions = sync_route_permissions

      # 2. 同步基础权限 (read, write, view)
      basic_permissions = sync_basic_permissions

      # 3. 更新系统角色权限
      sync_system_roles

      total_permissions = SysPermission.count
      Rails.logger.info "权限同步完成，共 #{total_permissions} 个权限"

      {
        route_permissions: route_permissions.count,
        basic_permissions: basic_permissions.count,
        total_permissions: total_permissions
      }
    end

    private

    def sync_route_permissions

      permissions = []
      controller_actions = extract_controller_actions

      controller_actions.each do |controller_name, actions|
        next if should_exclude_controller?(controller_name)

        module_name = normalize_controller_name(controller_name)

        actions.each do |action_name|
          next if should_exclude_action?(action_name)

          permission = build_route_permission(controller_name, action_name, module_name)
          permissions << permission if permission
        end
      end

      # 同步权限到数据库
      SysPermission.sync_system_permissions(permissions) if permissions.any?
      permissions
    end

    def sync_basic_permissions
      permissions = []
      controller_names = get_valid_controller_names

      controller_names.each do |controller_name|
        module_name = normalize_controller_name(controller_name)

        # 添加基础权限：read, write, view
        %w[read write view].each do |action|
          permissions << {
            code: "#{module_name}:#{action}",
            name: "#{action_display_name(action)}#{module_display_name(module_name)}",
            description: "#{action_description(action)}#{module_name}模块",
            module: module_name,
            action: action,
            resource: controller_name,
            is_system: true
          }
        end
      end

      # 同步权限到数据库
      SysPermission.sync_system_permissions(permissions) if permissions.any?
      permissions
    end

    def extract_controller_actions
      routes = Rails.application.routes.routes
      controller_actions = {}

      routes.each do |route|
        next unless route.defaults[:controller]

        controller_name = route.defaults[:controller]
        action_name = route.defaults[:action]

        controller_actions[controller_name] ||= Set.new
        controller_actions[controller_name] << action_name if action_name
      end

      controller_actions
    end

    def get_valid_controller_names
      controller_actions = extract_controller_actions
      controller_actions.keys.reject { |name| should_exclude_controller?(name) }
    end

    def should_exclude_controller?(controller_name)
      return true if controller_name.blank?

      EXCLUDED_CONTROLLERS.any? { |excluded| controller_name.include?(excluded) }
    end

    def should_exclude_action?(action_name)
      EXCLUDED_ACTIONS.include?(action_name)
    end

    def build_route_permission(controller_name, action_name, module_name)
      # 根据动作名称推断权限类型
      action_type = infer_action_type(action_name)
      return nil unless action_type

      {
        code: "#{module_name}:#{action_name}",
        name: "#{action_display_name(action_name)}#{module_display_name(module_name)}",
        description: "#{action_description(action_name)}#{module_name}模块的#{action_name}操作",
        module: module_name,
        action: action_type,
        resource: controller_name,
        is_system: true
      }
    end

    def normalize_controller_name(controller_name)
      controller_name
    end

    def infer_action_type(action_name)
      case action_name.to_s
      when /^(index|show|list|get_|search|stats|detail)/ then 'read'
      when /^(new|create)/ then 'create'
      when /^(edit|update|change|assign|move|sort|batch_update)/ then 'update'
      when /^(destroy|delete|remove|clear|batch_delete)/ then 'delete'
      when /^(execute|retry|cancel|stop|restart|activate|deactivate)/ then 'execute'
      when /^(sync|import|export|backup)/ then 'manage'
      else 'execute' # 默认为执行类型
      end
    end

    def action_display_name(action)
      case action.to_s
      when 'read' then '查看'
      when 'write' then '写入'
      when 'view' then '浏览'
      when 'create' then '创建'
      when 'update' then '更新'
      when 'delete' then '删除'
      when 'execute' then '执行'
      when 'manage' then '管理'
      when 'index' then '列表'
      when 'show' then '详情'
      when 'destroy' then '删除'
      else action.to_s.humanize
      end
    end

    def action_description(action)
      case action.to_s
      when 'read' then '查看和读取'
      when 'write' then '写入和修改'
      when 'view' then '浏览和展示'
      when 'create' then '创建新的'
      when 'update' then '更新和编辑'
      when 'delete' then '删除现有'
      when 'execute' then '执行操作于'
      when 'manage' then '管理和维护'
      when 'index' then '查看列表'
      when 'show' then '查看详情'
      when 'destroy' then '删除'
      else "执行#{action}操作于"
      end
    end

    def module_display_name(module_name)
      case module_name.to_s
      when 'sys_user' then '用户'
      when 'sys_role' then '角色'
      when 'sys_permission' then '权限'
      when 'ft_task' then '任务'
      when 'ft_flow' then '流程'
      when 'ft_task_execution' then '任务执行'
      when 'catalog' then '目录'
      when 'space' then '空间'
      when 'meta_datasource' then '元数据-数据源'
      when 'meta_host' then '元数据-主机'
      when 'system' then '系统'
      else module_name.to_s.humanize
      end
    end

    def sync_system_roles
      Rails.logger.info "开始更新系统角色权限..."

      # 确保系统角色存在
      ensure_system_roles_exist

      # 分配权限给各个角色
      assign_admin_permissions
      assign_operator_permissions
      assign_developer_permissions
      assign_viewer_permissions

      Rails.logger.info "系统角色权限更新完成"
    end

    def ensure_system_roles_exist
      [
        { name: 'admin', code: 'admin', description: '系统管理员，拥有所有权限' },
        { name: 'operator', code: 'operator', description: '运维人员，拥有除用户管理外的所有权限' },
        { name: 'developer', code: 'developer', description: '开发者，拥有开发相关权限' },
        { name: 'viewer', code: 'viewer', description: '查看者，只拥有查看权限' }
      ].each do |role_config|
        SysRole.find_or_create_by(name: role_config[:name]) do |role|
          role.code = role_config[:code]
          role.description = role_config[:description]
          role.is_system = true
          role.is_active = true
        end
      end
    end

    def assign_admin_permissions
      admin_role = SysRole.find_by(name: 'admin')
      return unless admin_role

      # 管理员拥有所有权限
      all_permission_ids = SysPermission.active.pluck(:id)
      admin_role.assign_permissions(permission_ids: all_permission_ids)
      Rails.logger.info "已为管理员角色分配 #{all_permission_ids.count} 个权限"
    end

    def assign_operator_permissions
      operator_role = SysRole.find_by(name: 'operator')
      return unless operator_role

      # 运维人员拥有除用户管理外的所有权限
      excluded_modules = %w[user role permission]
      permission_ids = SysPermission.active
                                    .where.not(module: excluded_modules)
                                    .pluck(:id)

      operator_role.assign_permissions(permission_ids: permission_ids)
      Rails.logger.info "已为运维人员角色分配 #{permission_ids.count} 个权限"
    end

    def assign_developer_permissions
      developer_role = SysRole.find_by(name: 'developer')
      return unless developer_role

      # 开发者拥有任务、流程、执行相关的所有权限，以及系统监控权限
      included_modules = %w[task flow execution taskexecution flowexecution datasource catalog space]
      permission_ids = SysPermission.active
                                    .where(module: included_modules)
                                    .pluck(:id)

      # 添加系统监控相关权限
      monitor_permissions = SysPermission.active
                                         .where(module: 'system')
                                         .where(action: %w[read monitor])
                                         .pluck(:id)

      all_permission_ids = (permission_ids + monitor_permissions).uniq
      developer_role.assign_permissions(permission_ids: all_permission_ids)
      Rails.logger.info "已为开发者角色分配 #{all_permission_ids.count} 个权限"
    end

    def assign_viewer_permissions
      viewer_role = SysRole.find_by(name: 'viewer')
      return unless viewer_role

      # 查看者只拥有读取和查看权限，排除用户和角色管理
      excluded_modules = %w[user role permission]
      permission_ids = SysPermission.active
                                    .where.not(module: excluded_modules)
                                    .where(action: %w[read view])
                                    .pluck(:id)

      viewer_role.assign_permissions(permission_ids: permission_ids)
      Rails.logger.info "已为查看者角色分配 #{permission_ids.count} 个权限"
    end
  end
end
