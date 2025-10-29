class AutomationLogsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :validate_permission!
  before_action :set_project, only: [:index], if: -> { params[:project_id].present? }

  # GET /automation_logs (全局查询)
  # GET /projects/:project_id/automation_logs (项目级查询)
  def index
    # 根据是否有 project_id 参数决定查询范围
    @logs = params[:project_id].present? ? @project.automation_logs : AutomationLog.all

    # 项目筛选(仅用于全局查询)
    if params[:project_id].blank? && params[:project_id_filter].present?
      @logs = @logs.where(project_id: params[:project_id_filter])
    end

    # 筛选条件
    @logs = @logs.by_action_type(params[:action_type]) if params[:action_type].present?
    @logs = @logs.where(status: params[:status]) if params[:status].present?
    @logs = @logs.where(sys_user_id: params[:user_id]) if params[:user_id].present?

    # 时间范围筛选
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day
      @logs = @logs.by_date_range(start_date, end_date)
    end

    # 搜索
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @logs = @logs.where('action LIKE ? OR remark LIKE ?', search_term, search_term)
    end

    # 分页
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    total = @logs.count

    @logs = @logs.recent.offset((page - 1) * per_page).limit(per_page)

    # 全局查询时包含项目信息
    include_options = {
      sys_user: {
        only: [:id, :name, :email],
        methods: [:initials]
      }
    }
    include_options[:project] = { only: [:id, :name] } if params[:project_id].blank?

    render json: ok({
      logs: @logs.as_json(
        include: include_options,
        methods: [:duration_in_seconds, :display_status, :display_name]
      ),
      pagination: {
        current_page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
    })
  rescue Date::Error
    render json: error('日期格式错误'), status: :bad_request
  end

  # GET /automation_logs/:id
  def show
    @log = AutomationLog.find(params[:id])
    render json: ok(@log.as_json(
      include: {
        project: { only: [:id, :name] },
        sys_user: {
          only: [:id, :name, :email],
          methods: [:initials]
        }
      },
      methods: [:duration_in_seconds, :display_status, :display_name]
    ))
  rescue ActiveRecord::RecordNotFound
    render json: error('日志不存在'), status: :not_found
  end

  # GET /projects/:project_id/automation_logs/stats
  def stats
    @logs = @project.automation_logs

    # 应用相同的筛选条件
    @logs = @logs.by_action_type(params[:action_type]) if params[:action_type].present?
    @logs = @logs.where(status: params[:status]) if params[:status].present?

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day
      @logs = @logs.by_date_range(start_date, end_date)
    end

    stats = {
      total: @logs.count,
      success: @logs.where(status: 'success').count,
      failed: @logs.where(status: 'failed').count,
      by_action_type: @logs.group(:action_type).count,
      by_status: @logs.group(:status).count,
      recent_24h: @logs.where('created_at >= ?', 24.hours.ago).count
    }

    render json: ok(stats)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: error('项目不存在'), status: :not_found
  end
end
