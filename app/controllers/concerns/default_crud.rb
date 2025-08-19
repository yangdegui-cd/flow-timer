# app/controllers/concerns/default_crud.rb
module DefaultCrud
  extend ActiveSupport::Concern
  extend Result

  included do
    before_action :set_resource, only: [:show, :update, :destroy]
  end

  def index
    query = JSON.parse(params[:query] || "{}").deep_symbolize_keys
    @resources = resource_class.where(query).all
    # 如果资源有html_json方法，优先使用html_json，否则使用as_json
    data = @resources.map do |r|
      r.respond_to?(:html_json) ? r.html_json : r.as_json(only: resource_class.show_fields)
    end
    render json: ok(data)
  end

  def show
    render json: ok(@resource.as_json(only: resource_class.show_fields))
  end

  def create
    @resource = resource_class.new(params.permit(resource_class.create_fields))
    begin
      @resource.save!
      render json: ok(@resource.as_json(only: resource_class.show_fields))
    rescue  => e
      return render json: error(e.message)
    end
  end

  def update
    if @resource.update(params.permit(resource_class.update_fields))
      render json: ok(@resource.as_json(only: resource_class.show_fields))
    else
      render json: error(@resource.errors.full_messages.join(","))
    end
  end

  def destroy
    @resource.destroy
    if @resource.destroyed?
      render json: ok
    else
      render json: error(@resource.errors.full_messages.join(","))
    end
  end

  private

  def set_resource
    begin
      @resource = resource_class.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render json: error("#{resource_class} not found with id #{params[:id]}"), status: :not_found
    end
  end

  def resource_class
    controller_name.classify.constantize
  end

  def resource_params
    params.require(controller_name.singularize.to_sym).permit!
    # You can modify the strong parameters to fit your needs
  end
end
