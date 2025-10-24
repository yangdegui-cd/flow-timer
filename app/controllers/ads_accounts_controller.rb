class AdsAccountsController < ApplicationController
  before_action :set_project, only: [:index, :create, :by_platform, :available, :bind, :unbind]
  before_action :set_ads_account, only: [:show, :update, :destroy, :sync, :refresh_token, :toggle]

  # GET /projects/:project_id/ads_accounts
  def index
    @ads_accounts = @project.ads_accounts.includes(:ads_platform, :sys_user)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(params[:per_page] || 20)

    render json: ok({
                      data: @ads_accounts.map(&:as_json_with_associations),
                      meta: pagination_meta(@ads_accounts)
                    })
  end

  # GET /ads_accounts/:id
  def show
    render json: ok({
                      data: @ads_account.as_json_with_associations
                    })
  end

  # POST /projects/:project_id/ads_accounts
  def create
    @ads_account = @project.ads_accounts.build(ads_account_params)
    @ads_account.sys_user = current_user

    if @ads_account.save
      render json: ok({
                        data: @ads_account.as_json_with_associations
                      }), status: :created
    else
      render json: error(@ads_account.errors.full_messages), status: :unprocessable_entity
    end
  end

  # PATCH/PUT /ads_accounts/:id
  def update
    if @ads_account.update(ads_account_update_params)
      render json: ok({
                        data: @ads_account.as_json_with_associations
                      })
    else
      render json: error(@ads_account.errors.full_messages), status: :unprocessable_entity
    end
  end

  # DELETE /ads_accounts/:id
  def destroy
    @ads_account.destroy!
    render json: ok({ message: '广告账户删除成功' })
  end

  # POST /ads_accounts/:id/sync
  def sync
    # TODO: 实现异步同步作业
    @ads_account.update!(sync_status: 'pending', last_sync_at: Time.current)
    # AdsAccountSyncJob.perform_later(@ads_account.id)

    render json: ok({ message: '同步任务已启动' })
  end

  # POST /ads_accounts/:id/refresh_token
  def refresh_token
    case @ads_account.ads_platform.slug
    when 'facebook'
      service = FacebookTokenService.new(@ads_account)
      if service.refresh_token
        render json: ok({
                          message: '令牌刷新成功',
                          data: @ads_account.reload.as_json_with_associations
                        })
      else
        render json: error('令牌刷新失败'), status: :unprocessable_entity
      end
    else
      render json: error('该平台暂不支持令牌刷新'), status: :unprocessable_entity
    end
  end

  # PATCH /ads_accounts/:id/toggle
  def toggle
    @ads_account.update!(active: params[:active])
    status_text = params[:active] ? '启用' : '禁用'

    render json: ok({
                      message: "广告账户已#{status_text}",
                      data: @ads_account.as_json_with_associations
                    })
  end

  # GET /projects/:project_id/ads_accounts/by_platform
  def by_platform
    accounts = @project.ads_accounts.includes(:ads_platform, :sys_user).active
    grouped = accounts.group_by { |account| account.ads_platform.slug }

    render json: ok({
                      data: grouped.transform_values { |accounts| accounts.map(&:as_json_with_associations) }
                    })
  end

  # GET /projects/:project_id/ads_accounts/available
  # 获取可用于绑定的广告账户（未绑定的账户或已绑定到当前项目的账户）
  def available
    available_accounts = AdsAccount.includes(:ads_platform, :sys_user).where(project_id: nil)
                                   .or(AdsAccount.where(project_id: @project.id))

    render json: ok({ data: available_accounts.map(&:as_json_with_associations) })
  end

  # POST /projects/:project_id/ads_accounts/:id/bind
  # 绑定广告账户到项目
  def bind
    account = current_user.ads_accounts.find(params[:id])

    # 检查账户是否已绑定到其他项目
    if account.project_id.present? && account.project_id != @project.id
      render json: error('该账户已绑定到其他项目')
      return
    end

    if account.update(project_id: @project.id)
      render json: ok({
                        message: '账户绑定成功',
                        data: account.reload.as_json_with_associations
                      })
    else
      render json: error(account.errors.full_messages)
    end
  rescue ActiveRecord::RecordNotFound
    render json: error('广告账户不存在或无权限访问')
  end

  # DELETE /projects/:project_id/ads_accounts/:id/unbind
  # 解绑广告账户
  def unbind
    account = @project.ads_accounts.find(params[:id])

    if account.update(project_id: nil)
      render json: ok({
                        message: '账户解绑成功'
                      })
    else
      render json: error(account.errors.full_messages)
    end
  rescue ActiveRecord::RecordNotFound
    render json: error('广告账户不存在或无权限访问')
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: error('项目不存在或无权限访问')
  end

  def set_ads_account
    @ads_account = current_user.ads_accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('广告账户不存在或无权限访问')
  end

  def ads_account_params
    params.require(:ads_account).permit(
      :name, :account_id, :ads_platform_id,
      :access_token, :refresh_token, :app_id, :app_secret,
      :currency, :timezone, :sync_frequency, :config
    )
  end

  def ads_account_update_params
    params.require(:ads_account).permit(
      :name, :sync_frequency, :active, :config
    )
  end

  def pagination_meta(collection)
    {
      total: collection.total_count,
      page: collection.current_page,
      per_page: collection.limit_value,
      total_pages: collection.total_pages
    }
  end
end
