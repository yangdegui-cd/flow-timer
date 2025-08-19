# frozen_string_literal: true

class CatalogController < ApplicationController
  include DefaultCrud

  # 移动目录到指定空间
  def move
    catalog_id = params[:id]
    target_space_id = params[:target_space_id]

    begin
      catalog = Catalog.find(catalog_id)
      target_space = Space.find(target_space_id)

      # 检查目标空间是否存在
      unless target_space
        return render json: error("目标空间不存在"), status: :not_found
      end

      # 检查是否真的需要移动
      if catalog.space_id == target_space_id
        return render json: ok({ message: "目录已在目标空间中" })
      end

      # 记录移动前的信息用于日志
      old_space = Space.find_by(id: catalog.space_id)
      old_space_name = old_space&.name || "未知空间"

      # 执行移动
      catalog.update!(space_id: target_space_id)

      Rails.logger.info "Catalog moved: #{catalog.name} from #{old_space_name} to #{target_space.name}"

      render json: ok({
        message: "目录移动成功",
        catalog: catalog.html_json,
        source_space: { id: old_space&.id, name: old_space_name },
        target_space: { id: target_space.id, name: target_space.name }
      })

    rescue ActiveRecord::RecordNotFound => e
      render json: error("记录不存在: #{e.message}"), status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: error("移动失败: #{e.message}"), status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Catalog move error: #{e.message}"
      render json: error("移动目录时发生错误"), status: :internal_server_error
    end
  end

  # 批量移动目录
  def move_batch
    catalog_ids = params[:catalog_ids] || []
    target_space_id = params[:target_space_id]

    if catalog_ids.empty?
      return render json: error("未提供目录ID列表"), status: :bad_request
    end

    begin
      target_space = Space.find(target_space_id)
      
      results = []
      errors = []

      catalog_ids.each do |catalog_id|
        begin
          catalog = Catalog.find(catalog_id)
          old_space_id = catalog.space_id

          # 跳过已在目标空间的目录
          if catalog.space_id == target_space_id
            results << {
              catalog_id: catalog_id,
              status: 'skipped',
              message: '目录已在目标空间中'
            }
            next
          end

          catalog.update!(space_id: target_space_id)
          
          results << {
            catalog_id: catalog_id,
            status: 'success',
            message: '移动成功',
            source_space_id: old_space_id,
            target_space_id: target_space_id
          }

        rescue ActiveRecord::RecordNotFound
          errors << {
            catalog_id: catalog_id,
            error: '目录不存在'
          }
        rescue => e
          errors << {
            catalog_id: catalog_id,
            error: e.message
          }
        end
      end

      render json: ok({
        message: "批量移动完成",
        total: catalog_ids.length,
        success_count: results.count { |r| r[:status] == 'success' },
        skipped_count: results.count { |r| r[:status] == 'skipped' },
        error_count: errors.length,
        results: results,
        errors: errors
      })

    rescue ActiveRecord::RecordNotFound
      render json: error("目标空间不存在"), status: :not_found
    rescue => e
      Rails.logger.error "Batch catalog move error: #{e.message}"
      render json: error("批量移动目录时发生错误"), status: :internal_server_error
    end
  end

  # 批量更新目录排序
  def batch_sort
    space_id = params[:space_id]
    catalog_sorts = params[:catalog_sorts] || []

    if catalog_sorts.empty?
      return render json: error("未提供排序数据"), status: :bad_request
    end

    begin
      # 验证空间是否存在
      space = Space.find(space_id)
      
      updated_catalogs = []
      errors = []

      # 使用事务确保数据一致性
      ActiveRecord::Base.transaction do
        catalog_sorts.each do |sort_data|
          catalog_id = sort_data[:id]
          new_sort = sort_data[:sort]

          begin
            catalog = Catalog.find(catalog_id)
            
            # 验证目录是否属于指定空间
            unless catalog.space_id == space_id.to_i
              errors << {
                catalog_id: catalog_id,
                error: '目录不属于指定空间'
              }
              next
            end

            # 更新排序
            catalog.update!(sort: new_sort)
            
            updated_catalogs << {
              catalog_id: catalog_id,
              old_sort: catalog.sort_was,
              new_sort: new_sort,
              status: 'success'
            }

          rescue ActiveRecord::RecordNotFound
            errors << {
              catalog_id: catalog_id,
              error: '目录不存在'
            }
          rescue => e
            errors << {
              catalog_id: catalog_id,
              error: e.message
            }
          end
        end

        # 如果有错误，回滚事务
        if errors.any?
          Rails.logger.warn "Catalog sort errors: #{errors}"
          # 继续执行，但记录错误
        end
      end

      Rails.logger.info "Catalog sort completed for space #{space.name}: #{updated_catalogs.length} catalogs updated"

      render json: ok({
        message: "排序更新完成",
        space_id: space_id,
        total: catalog_sorts.length,
        success_count: updated_catalogs.length,
        error_count: errors.length,
        updated_catalogs: updated_catalogs,
        errors: errors
      })

    rescue ActiveRecord::RecordNotFound
      render json: error("空间不存在"), status: :not_found
    rescue => e
      Rails.logger.error "Batch catalog sort error: #{e.message}"
      render json: error("批量排序时发生错误"), status: :internal_server_error
    end
  end

  private

  def move_params
    params.permit(:target_space_id)
  end

  def batch_move_params
    params.permit(:target_space_id, catalog_ids: [])
  end

  def batch_sort_params
    params.permit(:space_id, catalog_sorts: [:id, :sort])
  end
end
