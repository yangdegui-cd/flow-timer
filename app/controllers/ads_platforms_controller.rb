class AdsPlatformsController < ApplicationController
  before_action :set_ads_platform, only: [:show]

  # GET /ads_platforms
  def index
    @ads_platforms = AdsPlatform.active.order(:name)

    render json: ok({
      data: @ads_platforms.as_json(only: [
        :id, :name, :slug, :api_version, :base_url, :oauth_url,
        :scopes, :auth_method, :description, :active
      ])
    })
  end

  # GET /ads_platforms/:id
  def show
    render json: ok({
      data: @ads_platform.as_json(only: [
        :id, :name, :slug, :api_version, :base_url, :oauth_url,
        :scopes, :auth_method, :description, :active, :created_at, :updated_at
      ])
    })
  end

  private

  def set_ads_platform
    @ads_platform = AdsPlatform.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: error('广告平台不存在'), status: :not_found
  end
end