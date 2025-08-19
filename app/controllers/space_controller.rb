# frozen_string_literal: true

class SpaceController < ApplicationController
  include DefaultCrud

  def index
    query = JSON.parse(params.fetch("query", "{}"))
    if query.present? && query["type"].present?
      render json: ok(Space.get_all(query["type"]))
    else
      render json: ok(Space.all)
    end
  end

  # 批量更新空间排序
  def batch_sort
    space_sorts = params[:space_sorts] || []

    if space_sorts.empty?
      return render json: error("未提供排序数据"), status: :bad_request
    end

    begin
      updated_spaces = []
      errors = []

      # 使用事务确保数据一致性
      ActiveRecord::Base.transaction do
        space_sorts.each do |sort_data|
          space_id = sort_data[:id]
          new_sort = sort_data[:sort]

          begin
            space = Space.find(space_id)
            
            # 更新排序
            space.update!(sort: new_sort)
            
            updated_spaces << {
              space_id: space_id,
              old_sort: space.sort_was,
              new_sort: new_sort,
              status: 'success'
            }

          rescue ActiveRecord::RecordNotFound
            errors << {
              space_id: space_id,
              error: '空间不存在'
            }
          rescue => e
            errors << {
              space_id: space_id,
              error: e.message
            }
          end
        end

        # 如果有错误，记录但不回滚
        if errors.any?
          Rails.logger.warn "Space sort errors: #{errors}"
        end
      end

      Rails.logger.info "Space sort completed: #{updated_spaces.length} spaces updated"

      render json: ok({
        message: "排序更新完成",
        total: space_sorts.length,
        success_count: updated_spaces.length,
        error_count: errors.length,
        updated_spaces: updated_spaces,
        errors: errors
      })

    rescue => e
      Rails.logger.error "Batch space sort error: #{e.message}"
      render json: error("批量排序时发生错误"), status: :internal_server_error
    end
  end

  private

  def batch_sort_params
    params.permit(space_sorts: [:id, :sort])
  end
end
