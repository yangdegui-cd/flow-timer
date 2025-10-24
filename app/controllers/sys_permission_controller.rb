class SysPermissionController < ApplicationController
  include DefaultCrud
  include Result

  before_action :set_permission, only: [:show, :update, :destroy]


  # POST /sys_permission/sync_system_permissions
  def sync_system_permissions
    begin
      permissions_config = default_permissions_config
      SysPermission.sync_system_permissions(permissions_config)

      render json: success_result({
        message: '系统权限同步成功',
        synced_count: permissions_config.count
      })
    rescue StandardError => e
      Rails.logger.error "同步系统权限失败: #{e.message}"
      render json: error_result("同步失败: #{e.message}"), status: :unprocessable_entity
    end
  end

  private

  def set_permission
    @permission = SysPermission.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('权限不存在')
  end

  def permission_params
    params.require(:sys_permission).permit(:code, :name, :description, :module, :action, :resource, :is_active, :sort_order)
  end

  def module_display_name(module_name)
    case module_name
    when 'user' then '用户管理'
    when 'role' then '角色管理'
    when 'task' then '任务管理'
    when 'flow' then '流程管理'
    when 'execution' then '执行管理'
    when 'system' then '系统管理'
    when 'monitoring' then '监控管理'
    else module_name.humanize
    end
  end

  def module_description(module_name)
    case module_name
    when 'user' then '用户账户和个人资料管理'
    when 'role' then '角色权限管理'
    when 'task' then '任务创建和配置管理'
    when 'flow' then '工作流程定义和管理'
    when 'execution' then '任务执行记录管理'
    when 'system' then '系统配置和维护'
    when 'monitoring' then '系统监控和日志'
    else "#{module_name}模块相关功能"
    end
  end

  def default_permissions_config
    [
      # 用户管理权限
      { code: 'user:create', name: '创建用户', description: '创建新的用户账户', module: 'user', action: 'create' },
      { code: 'user:read', name: '查看用户', description: '查看用户信息', module: 'user', action: 'read' },
      { code: 'user:update', name: '编辑用户', description: '修改用户信息', module: 'user', action: 'update' },
      { code: 'user:delete', name: '删除用户', description: '删除用户账户', module: 'user', action: 'delete' },
      { code: 'user:manage_status', name: '管理用户状态', description: '启用/禁用用户账户', module: 'user', action: 'manage' },

      # 角色管理权限
      { code: 'role:create', name: '创建角色', description: '创建新的角色', module: 'role', action: 'create' },
      { code: 'role:read', name: '查看角色', description: '查看角色信息', module: 'role', action: 'read' },
      { code: 'role:update', name: '编辑角色', description: '修改角色信息', module: 'role', action: 'update' },
      { code: 'role:delete', name: '删除角色', description: '删除角色', module: 'role', action: 'delete' },
      { code: 'role:assign_permissions', name: '分配权限', description: '为角色分配权限', module: 'role', action: 'assign' },

      # 任务管理权限
      { code: 'task:create', name: '创建任务', description: '创建新的任务', module: 'task', action: 'create' },
      { code: 'task:read', name: '查看任务', description: '查看任务信息', module: 'task', action: 'read' },
      { code: 'task:update', name: '编辑任务', description: '修改任务配置', module: 'task', action: 'update' },
      { code: 'task:delete', name: '删除任务', description: '删除任务', module: 'task', action: 'delete' },
      { code: 'task:execute', name: '执行任务', description: '手动执行任务', module: 'task', action: 'execute' },

      # 流程管理权限
      { code: 'flow:create', name: '创建流程', description: '创建新的工作流程', module: 'flow', action: 'create' },
      { code: 'flow:read', name: '查看流程', description: '查看流程信息', module: 'flow', action: 'read' },
      { code: 'flow:update', name: '编辑流程', description: '修改流程定义', module: 'flow', action: 'update' },
      { code: 'flow:delete', name: '删除流程', description: '删除流程', module: 'flow', action: 'delete' },
      { code: 'flow:publish', name: '发布流程', description: '发布流程版本', module: 'flow', action: 'publish' },

      # 执行管理权限
      { code: 'execution:read', name: '查看执行记录', description: '查看任务执行历史', module: 'execution', action: 'read' },
      { code: 'execution:stop', name: '停止执行', description: '停止正在运行的任务', module: 'execution', action: 'stop' },
      { code: 'execution:retry', name: '重试执行', description: '重新执行失败的任务', module: 'execution', action: 'retry' },

      # 系统管理权限
      { code: 'system:config', name: '系统配置', description: '修改系统配置', module: 'system', action: 'config' },
      { code: 'system:monitor', name: '系统监控', description: '查看系统监控信息', module: 'system', action: 'monitor' },
      { code: 'system:logs', name: '查看日志', description: '查看系统日志', module: 'system', action: 'logs' },
      { code: 'system:backup', name: '数据备份', description: '执行数据备份', module: 'system', action: 'backup' }
    ]
  end
end
