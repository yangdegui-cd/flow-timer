class Api::MetaDatabasesController < ApplicationController
  before_action :set_meta_database, only: [:show, :update, :destroy, :test_connection, :get_databases, :get_schemas, :get_catalogs]

  # GET /api/meta_databases
  def index
    @meta_databases = MetaDatasource.all

    # 支持筛选参数
    @meta_databases = @meta_databases.by_type(params[:db_type]) if params[:db_type].present?
    @meta_databases = @meta_databases.by_status(params[:status]) if params[:status].present?
    @meta_databases = @meta_databases.search_by_name(params[:name]) if params[:name].present?

    # 分页
    page = params[:page] || 1
    per_page = params[:per_page] || 20

    @meta_databases = @meta_databases.page(page).per(per_page)

    render json: {
      code: 200,
      message: '获取成功',
      data: {
        databases: @meta_databases.as_json,
        pagination: {
          current_page: @meta_databases.current_page,
          total_pages: @meta_databases.total_pages,
          total_count: @meta_databases.total_count,
          per_page: per_page.to_i
        }
      }
    }
  rescue => e
    render json: { code: 500, message: "获取数据库列表失败: #{e.message}" }, status: 500
  end

  # GET /api/meta_databases/:id
  def show
    render json: {
      code: 200,
      message: '获取成功',
      data: @meta_database.as_json
    }
  rescue => e
    render json: { code: 500, message: "获取数据库信息失败: #{e.message}" }, status: 500
  end

  # POST /api/meta_databases
  def create
    @meta_database = MetaDatasource.new(meta_database_params)

    if @meta_database.save
      render json: {
        code: 200,
        message: '创建成功',
        data: @meta_database.as_json
      }, status: 201
    else
      render json: {
        code: 400,
        message: '创建失败',
        errors: @meta_database.errors.full_messages
      }, status: 400
    end
  rescue => e
    render json: { code: 500, message: "创建数据库连接失败: #{e.message}" }, status: 500
  end

  # PATCH/PUT /api/meta_databases/:id
  def update
    if @meta_database.update(meta_database_params)
      render json: {
        code: 200,
        message: '更新成功',
        data: @meta_database.as_json
      }
    else
      render json: {
        code: 400,
        message: '更新失败',
        errors: @meta_database.errors.full_messages
      }, status: 400
    end
  rescue => e
    render json: { code: 500, message: "更新数据库连接失败: #{e.message}" }, status: 500
  end

  # DELETE /api/meta_databases/:id
  def destroy
    @meta_database.destroy
    render json: {
      code: 200,
      message: '删除成功'
    }
  rescue => e
    render json: { code: 500, message: "删除数据库连接失败: #{e.message}" }, status: 500
  end

  # POST /api/meta_databases/:id/test_connection
  def test_connection
    if @meta_database.test_connection
      render json: {
        code: 200,
        message: '连接测试成功',
        data: {
          success: true,
          message: @meta_database.test_result,
          databases: @meta_database.extra_config&.dig('discovered_databases'),
          catalogs: @meta_database.extra_config&.dig('discovered_catalogs'),
          test_time: @meta_database.last_test_at&.iso8601
        }
      }
    else
      render json: {
        code: 400,
        message: '连接测试失败',
        data: {
          success: false,
          message: @meta_database.test_result,
          test_time: @meta_database.last_test_at&.iso8601
        }
      }
    end
  rescue => e
    render json: { code: 500, message: "连接测试失败: #{e.message}" }, status: 500
  end

  # POST /api/meta_databases/test_connection
  def test_connection_without_save
    config = {
      db_type: params[:db_type],
      host: params[:host],
      port: params[:port],
      username: params[:username],
      password: params[:password],
      extra_config: params[:extra_config] || {}
    }

    result = DatasourceAdapterService.test_connection(config)

    if result[:success]
      render json: {
        code: 200,
        message: '连接测试成功',
        data: result
      }
    else
      render json: {
        code: 400,
        message: '连接测试失败',
        data: result
      }
    end
  rescue => e
    render json: { code: 500, message: "连接测试失败: #{e.message}" }, status: 500
  end

  # GET /api/meta_databases/:id/databases
  def get_databases
    catalog = params[:catalog]
    databases = @meta_database.get_databases(catalog)

    render json: {
      code: 200,
      message: '获取成功',
      data: databases
    }
  rescue => e
    render json: { code: 500, message: "获取数据库列表失败: #{e.message}" }, status: 500
  end

  # GET /api/meta_databases/:id/schemas
  def get_schemas
    database_name = params[:database]
    catalog = params[:catalog]

    if database_name.blank?
      render json: { code: 400, message: '缺少数据库名称参数' }, status: 400
      return
    end

    schemas = @meta_database.get_schemas(database_name, catalog)

    render json: {
      code: 200,
      message: '获取成功',
      data: schemas
    }
  rescue => e
    render json: { code: 500, message: "获取Schema列表失败: #{e.message}" }, status: 500
  end

  # GET /api/meta_databases/:id/catalogs
  def get_catalogs
    catalogs = @meta_database.get_catalogs

    render json: {
      code: 200,
      message: '获取成功',
      data: catalogs
    }
  rescue => e
    render json: { code: 500, message: "获取Catalog列表失败: #{e.message}" }, status: 500
  end

  # POST /api/meta_databases/:id/execute_sql
  def execute_sql
    sql = params[:sql]
    options = {
      database: params[:database],
      max_rows: params[:max_rows]&.to_i || 1000,
      timeout: params[:timeout]&.to_i || 300
    }

    if sql.blank?
      render json: { code: 400, message: '缺少SQL语句' }, status: 400
      return
    end

    result = @meta_database.execute_sql(sql, options)

    if result[:success]
      render json: {
        code: 200,
        message: 'SQL执行成功',
        data: result
      }
    else
      render json: {
        code: 400,
        message: 'SQL执行失败',
        data: result
      }
    end
  rescue => e
    render json: { code: 500, message: "SQL执行失败: #{e.message}" }, status: 500
  end

  private

  def set_meta_database
    @meta_database = MetaDatasource.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { code: 404, message: '数据库连接不存在' }, status: 404
  end

  def meta_database_params
    params.require(:meta_database).permit(
      :name, :db_type, :host, :port, :username, :password, :description, :status,
      extra_config: {}
    )
  end
end
