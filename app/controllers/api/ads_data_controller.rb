class Api::AdsDataController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :stats, :campaigns, :accounts]
  skip_before_action :validate_permission!, only: [:index, :show, :stats, :campaigns, :accounts]

  # 获取广告数据列表
  def index
    ads_account_id = params[:ads_account_id]
    project_id = params[:project_id]
    platform = params[:platform]
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20

    query = AdsMergeDatum.includes(:ads_account, :project)

    # 筛选项目
    if project_id.present?
      query = query.where(project_id: project_id)
    end

    # 筛选平台
    if platform.present?
      query = query.where(platform: platform)
    end

    # 筛选广告账户
    if ads_account_id.present?
      query = query.where(ads_account_id: ads_account_id)
    end

    # 筛选日期范围
    if params[:start_date].present? && params[:end_date].present?
      query = query.where(date: params[:start_date]..params[:end_date])
    end

    # 筛选活动
    if params[:campaign_name].present?
      query = query.where('campaign_name LIKE ?', "%#{params[:campaign_name]}%")
    end

    # 搜索
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      query = query.where(
        'campaign_name LIKE ? OR adset_name LIKE ? OR ad_name LIKE ?',
        search_term, search_term, search_term
      )
    end

    # 排序
    order_by = params[:order_by] || 'date'
    order_direction = params[:order_direction] || 'desc'
    query = query.order("#{order_by} #{order_direction}")

    # 分页
    total_count = query.count
    ads_data = query.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: ads_data.map { |data|
        data.as_json.merge(
          ads_account_name: data.ads_account.name,
          project_name: data.project.name,
          platform_name: data.ads_account.ads_platform.name
        )
      },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  # 获取数据统计
  def stats
    project_id = params[:project_id]
    platform = params[:platform]
    ads_account_id = params[:ads_account_id]
    query = AdsMergeDatum.all

    # 筛选项目
    if project_id.present?
      query = query.where(project_id: project_id)
    end

    # 筛选平台
    if platform.present?
      query = query.where(platform: platform)
    end

    # 筛选广告账户
    if ads_account_id.present?
      query = query.where(ads_account_id: ads_account_id)
    end

    # 日期范围筛选
    if params[:start_date].present? && params[:end_date].present?
      query = query.where(date: params[:start_date]..params[:end_date])
    end
    # 如果没有指定日期范围，不添加日期过滤，显示所有数据

    # 核心指标汇总
    total_stats = {
      impressions: query.sum(:impressions) || 0,
      clicks: query.sum(:clicks) || 0,
      spend: query.sum(:spend) || 0,
      reach: 0,  # ads_merge_data 视图中没有此字段
      conversions: query.sum(:conversions) || 0,
      conversion_value: query.sum(:revenue) || 0,
      video_views: query.sum(:video_play_actions) || 0,
      likes: query.sum(:page_likes) || 0,
      comments: 0,  # ads_merge_data 视图中没有此字段
      shares: query.sum(:post_shares) || 0,
      saves: 0,  # ads_merge_data 视图中没有此字段
      # Adjust数据
      adjust_install: query.sum(:adjust_install) || 0,
      adjust_spend: query.sum(:adjust_spend) || 0
    }

    # 平均指标
    avg_stats = {
      avg_ctr: total_stats[:impressions] > 0 ?
               (total_stats[:clicks].to_f / total_stats[:impressions] * 100).round(4) : 0,
      avg_cpm: total_stats[:impressions] > 0 ?
               (total_stats[:spend].to_f / total_stats[:impressions] * 1000).round(4) : 0,
      avg_cpc: total_stats[:clicks] > 0 ?
               (total_stats[:spend].to_f / total_stats[:clicks]).round(4) : 0,
      avg_conversion_rate: total_stats[:clicks] > 0 ?
                          (total_stats[:conversions].to_f / total_stats[:clicks] * 100).round(4) : 0,
      avg_cost_per_conversion: total_stats[:conversions] > 0 ?
                              (total_stats[:spend].to_f / total_stats[:conversions]).round(4) : 0,
      avg_roas: total_stats[:spend] > 0 ?
               (total_stats[:conversion_value].to_f / total_stats[:spend]).round(4) : 0,
      avg_frequency: 0
    }

    # 按日统计
    daily_stats = query.group(:date)
                       .sum(:impressions)
                       .map { |date, impressions|
                         date_data = query.where(date: date)
                         {
                           date: date.strftime('%Y-%m-%d'),
                           datetime: date.strftime('%Y-%m-%d'),
                           impressions: impressions || 0,
                           clicks: date_data.sum(:clicks) || 0,
                           spend: date_data.sum(:spend) || 0,
                           conversions: date_data.sum(:conversions) || 0,
                           reach: 0,  # ads_merge_data 视图中没有此字段
                           adjust_install: date_data.sum(:adjust_install) || 0
                         }
                       }.sort_by { |item| item[:date] }

    # 按活动统计
    campaign_stats = query.group(:campaign_name)
                          .sum(:spend)
                          .map { |campaign_name, spend|
                            campaign_data = query.where(campaign_name: campaign_name)
                            impressions = campaign_data.sum(:impressions)
                            clicks = campaign_data.sum(:clicks)
                            conversions = campaign_data.sum(:conversions)

                            {
                              campaign_name: campaign_name,
                              impressions: impressions || 0,
                              clicks: clicks || 0,
                              spend: spend || 0,
                              conversions: conversions || 0,
                              ctr: clicks > 0 && impressions > 0 ?
                                   (clicks.to_f / impressions * 100).round(4) : 0,
                              cpm: spend > 0 && impressions > 0 ?
                                   (spend.to_f / impressions * 1000).round(4) : 0
                            }
                          }.sort_by { |item| -item[:spend] }

    render json: {
      total_stats: total_stats,
      average_stats: avg_stats,
      hourly_stats: [],  # 暂时为空，可以后续添加
      daily_stats: daily_stats,
      weekly_stats: [],  # 暂时为空，可以后续添加
      monthly_stats: [], # 暂时为空，可以后续添加
      campaign_stats: campaign_stats,
      adset_stats: [],   # 暂时为空，可以后续添加
      creative_stats: [], # 暂时为空，可以后续添加
      device_platform_stats: [], # 暂时为空，可以后续添加
      audience_stats: [], # 暂时为空，可以后续添加
      summary: {
        total_records: query.count,
        date_range: {
          start_date: query.minimum(:date),
          end_date: query.maximum(:date)
        },
        unique_campaigns: query.where.not(campaign_name: nil).distinct.count(:campaign_name),
        unique_adsets: query.where.not(adset_name: nil).distinct.count(:adset_name),
        unique_ads: query.where.not(ad_name: nil).distinct.count(:ad_name),
        total_accounts: query.distinct.count(:ads_account_id),
        data_granularity: 'day'  # 默认为天级别
      }
    }
  end

  # 获取活动列表
  def campaigns
    ads_account_id = params[:ads_account_id]
    project_id = params[:project_id]
    platform = params[:platform]
    query = AdsMergeDatum.select(:campaign_name, :campaign_id).distinct

    # 筛选项目
    if project_id.present?
      query = query.where(project_id: project_id)
    end

    # 筛选平台
    if platform.present?
      query = query.where(platform: platform)
    end

    # 筛选广告账户
    if ads_account_id.present?
      query = query.where(ads_account_id: ads_account_id)
    end

    campaigns = query.map { |data|
      {
        id: data.campaign_id,
        name: data.campaign_name
      }
    }.uniq { |c| c[:id] }

    render json: campaigns
  end

  # 获取广告账户列表
  def accounts
    project_id = params[:project_id]
    platform = params[:platform]

    accounts_query = AdsAccount.active.includes(:ads_platform, :project)

    # 筛选项目
    if project_id.present?
      accounts_query = accounts_query.where(project_id: project_id)
    end

    # 筛选平台
    if platform.present?
      accounts_query = accounts_query.joins(:ads_platform).where(ads_platforms: { slug: platform.downcase })
    end

    accounts = accounts_query.map { |account|
      {
        id: account.id,
        name: account.name,
        account_id: account.account_id,
        platform: account.ads_platform.name,
        project: account.project.name,
        data_count: AdsMergeDatum.where(ads_account: account).count
      }
    }

    render json: accounts
  end
end