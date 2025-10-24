# 权限系统初始化
Rails.application.config.after_initialize do
  # 只在非生产环境或明确启用时运行权限同步
  should_sync = Rails.env.development? || 
                Rails.env.test? || 
                ENV['SYNC_PERMISSIONS'] == 'true'
  
  if should_sync
    begin
      # 确保数据库已迁移
      if ActiveRecord::Base.connection.table_exists?('sys_permissions')
        PermissionSyncService.sync_all_permissions
        Rails.logger.info "权限系统初始化完成"
      else
        Rails.logger.warn "权限表不存在，跳过权限同步"
      end
    rescue => e
      Rails.logger.error "权限系统初始化失败: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end