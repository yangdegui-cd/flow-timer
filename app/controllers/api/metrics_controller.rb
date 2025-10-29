class Api::MetricsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :categories, :calculate]
  skip_before_action :validate_permission!, only: [:index, :show, :categories, :calculate]

  # GET /api/metrics
  # 获取指标列表
  def index
    render json ok(Metric.active.ordered)
  end

  # GET /api/metrics/categories
  # 获取分组的指标
  def categories
    grouped_metrics = Metric.active.ordered.group_by(&:category)

    result = grouped_metrics.map do |category, metrics|
      {
        category: category,
        category_name: Metric::CATEGORIES[category.to_sym] || category,
        metrics: metrics.as_json(
          only: [:id, :name_cn, :name_en, :description, :sql_expression,
                 :unit, :color, :data_source]
        )
      }
    end

    render json: { categories: result }
  end

  # GET /api/metrics/:id
  # 获取单个指标详情
  def show
    metric = Metric.find(params[:id])

    render json: {
      metric: metric.as_json(
        only: [:id, :name_cn, :name_en, :description, :sql_expression,
               :unit, :color, :category, :data_source, :filter_max,
               :filter_min, :sort_order]
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: '指标不存在' }, status: :not_found
  end

  # POST /api/metrics/calculate
  # 根据指标和维度计算数据
  def calculate
    metric_ids = params[:metric_ids] || []
    start_date = params[:start_date]
    end_date = params[:end_date]
    project_id = params[:project_id]
    platform = params[:platform]
    ads_account_id = params[:ads_account_id]

    # 维度参数
    time_dimension = params[:time_dimension] # quarter/month/week/date/hour
    dimensions = params[:dimensions] || [] # [project_id, platform, ads_account_id, campaign_name, adset_name, ad_name]

    if metric_ids.empty?
      render json: { error: '请至少选择一个指标' }, status: :bad_request
      return
    end

    metrics = Metric.where(id: metric_ids).active

    # 构建基础查询
    query = AdsMergeDatum.all

    if project_id.present?
      query = query.where(project_id: project_id)
    end

    if platform.present?
      query = query.where(platform: platform)
    end

    if ads_account_id.present?
      query = query.where(ads_account_id: ads_account_id)
    end

    if start_date.present? && end_date.present?
      query = query.where(date: start_date..end_date)
    end

    # 如果没有选择任何维度，返回汇总数据
    if time_dimension.blank? && dimensions.empty?
      results = calculate_total(query, metrics)
      render json: {
        results: results,
        query_params: build_query_params(start_date, end_date, project_id, platform, ads_account_id, time_dimension, dimensions)
      }
      return
    end

    # 构建分组维度
    group_fields = build_group_fields(time_dimension, dimensions)
    select_fields = build_select_fields(time_dimension, dimensions, metrics)

    # 执行分组查询
    begin
      # 根据维度添加必要的 JOIN
      if dimensions.include?('project_id')
        query = query.joins('LEFT JOIN projects ON ads_merge_data.project_id = projects.id')
      end
      if dimensions.include?('ads_account_id')
        query = query.joins('LEFT JOIN ads_accounts ON ads_merge_data.ads_account_id = ads_accounts.id')
      end

      grouped_data = query
        .select(select_fields.join(', '))
        .group(group_fields.join(', '))
        .order(group_fields.first)

      results = format_grouped_results(grouped_data, time_dimension, dimensions, metrics)

      render json: {
        results: results,
        query_params: build_query_params(start_date, end_date, project_id, platform, ads_account_id, time_dimension, dimensions),
        total_rows: results.length
      }
    rescue => e
      render json: { error: "查询失败: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  # 计算汇总数据（无分组）
  def calculate_total(query, metrics)
    metrics.map do |metric|
      begin
        value = query.pluck(Arel.sql(metric.sql_expression)).first

        {
          metric_id: metric.id,
          name_cn: metric.name_cn,
          name_en: metric.name_en,
          value: value,
          formatted_value: metric.format_value(value),
          unit: metric.unit,
          color: metric.color
        }
      rescue => e
        {
          metric_id: metric.id,
          name_cn: metric.name_cn,
          name_en: metric.name_en,
          error: e.message
        }
      end
    end
  end

  # 构建分组字段
  def build_group_fields(time_dimension, dimensions)
    fields = []

    # 添加时间维度
    if time_dimension.present?
      case time_dimension
      when 'quarter'
        fields << Arel.sql("CONCAT(YEAR(date), '-Q', QUARTER(date))")
      when 'month'
        fields << Arel.sql("DATE_FORMAT(date, '%Y-%m')")
      when 'week'
        fields << Arel.sql("CONCAT(YEAR(date), '-W', LPAD(WEEK(date, 1), 2, '0'))")
      when 'date'
        fields << Arel.sql('date')
      when 'hour'
        fields << Arel.sql('datetime')
      end
    end

    # 添加其他维度
    dimensions.each do |dim|
      case dim
      when 'project_id', 'platform', 'ads_account_id', 'campaign_name', 'adset_name', 'ad_name'
        fields << Arel.sql(dim)
      end
    end

    fields
  end

  # 构建SELECT字段
  def build_select_fields(time_dimension, dimensions, metrics)
    fields = []

    # 添加时间维度
    if time_dimension.present?
      case time_dimension
      when 'quarter'
        fields << Arel.sql("CONCAT(YEAR(date), '-Q', QUARTER(date)) as time_value")
      when 'month'
        fields << Arel.sql("DATE_FORMAT(date, '%Y-%m') as time_value")
      when 'week'
        fields << Arel.sql("CONCAT(YEAR(date), '-W', LPAD(WEEK(date, 1), 2, '0')) as time_value")
      when 'date'
        fields << Arel.sql('date as time_value')
      when 'hour'
        fields << Arel.sql('datetime as time_value')
      end
    end

    # 添加其他维度
    dimensions.each do |dim|
      case dim
      when 'project_id'
        fields << Arel.sql('project_id')
        fields << Arel.sql('projects.name as project_name')
      when 'platform'
        fields << Arel.sql('platform')
      when 'ads_account_id'
        fields << Arel.sql('ads_account_id')
        fields << Arel.sql('ads_accounts.name as ads_account_name')
      when 'campaign_name', 'adset_name', 'ad_name'
        fields << Arel.sql(dim)
      end
    end

    # 添加指标计算
    metrics.each do |metric|
      fields << Arel.sql("#{metric.sql_expression} as metric_#{metric.id}")
    end

    fields
  end

  # 格式化分组结果
  def format_grouped_results(grouped_data, time_dimension, dimensions, metrics)
    grouped_data.map do |row|
      result = {}

      # 添加时间维度
      if time_dimension.present?
        result[:time_dimension] = time_dimension
        result[:time_value] = row['time_value']
      end

      # 添加其他维度
      dimensions.each do |dim|
        case dim
        when 'project_id'
          result[:project_id] = row['project_id']
          result[:project_name] = row['project_name']
        when 'platform'
          result[:platform] = row['platform']
        when 'ads_account_id'
          result[:ads_account_id] = row['ads_account_id']
          result[:ads_account_name] = row['ads_account_name']
        when 'campaign_name'
          result[:campaign_name] = row['campaign_name']
        when 'adset_name'
          result[:adset_name] = row['adset_name']
        when 'ad_name'
          result[:ad_name] = row['ad_name']
        end
      end

      # 添加指标值
      result[:metrics] = metrics.map do |metric|
        value = row["metric_#{metric.id}"]
        {
          metric_id: metric.id,
          name_cn: metric.name_cn,
          name_en: metric.name_en,
          value: value,
          formatted_value: metric.format_value(value),
          unit: metric.unit,
          color: metric.color
        }
      end

      result
    end
  end

  # 构建查询参数返回
  def build_query_params(start_date, end_date, project_id, platform, ads_account_id, time_dimension, dimensions)
    {
      start_date: start_date,
      end_date: end_date,
      project_id: project_id,
      platform: platform,
      ads_account_id: ads_account_id,
      time_dimension: time_dimension,
      dimensions: dimensions
    }
  end
end
