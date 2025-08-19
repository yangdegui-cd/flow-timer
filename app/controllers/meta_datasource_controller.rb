class MetaDatasourceController < ApplicationController
  def test_connection
    @meta_datasource = MetaDatasource.find(params[:id])
    result = @meta_datasource.test_connection
    if result
      render json: ok(MetaDatasource.find(params[:id]).as_json(only: MetaDatasource.show_fields))
    else
      render json: error("Failed to connect to the database.")
    end
  end

  def get_catalogs
    @meta_datasource = MetaDatasource.find(params[:id])
    result = @meta_datasource.get_catalogs
    if result
      render json: ok(result)
    else
      render json: error("Failed to retrieve catalogs from the database.")
    end
  end

  def get_schemas
    @meta_datasource = MetaDatasource.find(params[:id])
    trino_catalog = params[:trino_catalog] || @meta_datasource.get_trino_default_catalog
    trino_schema = params[:trino_schema] || @meta_datasource.get_trino_default_schema
    result = @meta_datasource.get_schemas(trino_catalog, trino_schema)
    if result
      render json: ok(result)
    else
      render json: error("Failed to retrieve schemas from the database.")
    end
  end

  def get_databases
    @meta_datasource = MetaDatasource.find(params[:id])
    trino_catalog = params[:trino_catalog] || @meta_datasource.get_trino_default_catalog
    result = @meta_datasource.get_databases(trino_catalog)
    if result
      render json: ok(result)
    else
      render json: error("Failed to retrieve schemas from the database.")
    end
  end
end
