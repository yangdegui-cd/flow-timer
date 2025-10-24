namespace :permissions do
  desc "同步所有权限 (基于路由和基础权限)"
  task sync: :environment do
    puts "开始同步权限系统..."
    
    result = PermissionSyncService.sync_all_permissions
    
    puts "权限同步完成："
    puts "  - 路由权限: #{result[:route_permissions]}"
    puts "  - 基础权限: #{result[:basic_permissions]}"
    puts "  - 总权限数: #{result[:total_permissions]}"
    
    # 显示统计信息
    puts "\n权限模块统计："
    SysPermission.active.group(:module).count.each do |module_name, count|
      puts "  #{module_name}: #{count} 个权限"
    end
    
    puts "\n系统角色权限统计："
    SysRole.system.each do |role|
      stats = role.permission_stats
      puts "  #{role.display_name}: #{stats[:direct_permissions_count]} 个直接权限"
    end
  end

  desc "清理未使用的权限"
  task cleanup: :environment do
    puts "开始清理未使用的权限..."
    
    # 找出没有被任何角色使用的权限
    unused_permissions = SysPermission.left_joins(:sys_role_permissions)
                                     .where(sys_role_permissions: { id: nil })
                                     .where(is_system: false)
    
    if unused_permissions.any?
      puts "发现 #{unused_permissions.count} 个未使用的自定义权限："
      unused_permissions.each do |permission|
        puts "  - #{permission.code}: #{permission.name}"
      end
      
      print "确认删除这些权限吗？(y/N): "
      response = STDIN.gets.chomp.downcase
      
      if response == 'y' || response == 'yes'
        deleted_count = unused_permissions.destroy_all.count
        puts "已删除 #{deleted_count} 个权限"
      else
        puts "取消删除操作"
      end
    else
      puts "没有发现未使用的权限"
    end
  end

  desc "显示权限统计信息"
  task stats: :environment do
    puts "=== 权限系统统计 ==="
    
    total_permissions = SysPermission.count
    active_permissions = SysPermission.active.count
    system_permissions = SysPermission.system.count
    
    puts "权限总数: #{total_permissions}"
    puts "活跃权限: #{active_permissions}"
    puts "系统权限: #{system_permissions}"
    puts "自定义权限: #{total_permissions - system_permissions}"
    
    puts "\n按模块分组："
    SysPermission.active.group(:module).count.sort.each do |module_name, count|
      puts "  #{module_name}: #{count} 个权限"
    end
    
    puts "\n按动作分组："
    SysPermission.active.group(:action).count.sort.each do |action, count|
      puts "  #{action}: #{count} 个权限"
    end
    
    
    puts "\n角色权限统计："
    SysRole.all.each do |role|
      stats = role.permission_stats
      puts "  #{role.display_name}: #{stats[:direct_permissions_count]} 个权限"
    end
  end

  desc "验证权限系统完整性"
  task validate: :environment do
    puts "=== 验证权限系统完整性 ==="
    
    errors = []
    
    # 检查权限代码唯一性
    duplicate_codes = SysPermission.group(:code).having('COUNT(*) > 1').pluck(:code)
    if duplicate_codes.any?
      errors << "发现重复的权限代码: #{duplicate_codes.join(', ')}"
    end
    
    # 检查角色是否有权限
    roles_without_permissions = SysRole.left_joins(:sys_role_permissions)
                                       .where(sys_role_permissions: { id: nil })
                                       .pluck(:name)
    if roles_without_permissions.any?
      errors << "发现没有权限的角色: #{roles_without_permissions.join(', ')}"
    end
    
    
    if errors.any?
      puts "发现以下问题："
      errors.each { |error| puts "  ❌ #{error}" }
    else
      puts "✅ 权限系统完整性验证通过"
    end
  end

  desc "重建系统角色权限"
  task rebuild_roles: :environment do
    puts "重建系统角色权限..."
    
    PermissionSyncService.send(:sync_system_roles)
    
    puts "系统角色权限重建完成"
  end
end