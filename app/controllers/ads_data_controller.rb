class Api::AdsDataController < ApplicationController
  # 获取广告数据列表
  def index
    ads_account_id = params[:ads_account_id]
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20

    query = AdsData.includes(:ads_account, :project)

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
    ads_account_id = params[:ads_account_id]
    query = AdsData.all

    if ads_account_id.present?
      query = query.where(ads_account_id: ads_account_id)
    end

    # 日期范围筛选
    if params[:start_date].present? && params[:end_date].present?
      query = query.where(date: params[:start_date]..params[:end_date])
    else
      # 默认最近30天
      query = query.where(date: 30.days.ago..Date.current)
    end

    # 核心指标汇总
    total_stats = query.sum_metrics

    # 平均指标
    avg_stats = AdsData.calculate_averages(query)

    # 按日统计
    daily_stats = query.group(:date)
                       .sum(:impressions)
                       .merge(query.group(:date).sum(:clicks))
                       .merge(query.group(:date).sum(:spend))
                       .merge(query.group(:date).sum(:conversions))
                       .map { |date, impressions|
                         clicks = query.where(date: date).sum(:clicks)
                         spend = query.where(date: date).sum(:spend)
                         conversions = query.where(date: date).sum(:conversions)
                         {
                           date: date,
                           impressions: impressions || 0,
                           clicks: clicks || 0,
                           spend: spend || 0,
                           conversions: conversions || 0
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
      daily_stats: daily_stats,
      campaign_stats: campaign_stats,
      summary: {
        total_records: query.count,
        date_range: {
          start_date: query.minimum(:date),
          end_date: query.maximum(:date)
        },
        unique_campaigns: query.distinct.count(:campaign_name),
        total_accounts: query.distinct.count(:ads_account_id)
      }
    }
  end

  # 获取活动列表
  def campaigns
    ads_account_id = params[:ads_account_id]
    query = AdsData.select(:campaign_name, :campaign_id).distinct

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
    accounts = AdsAccount.active.includes(:ads_platform, :project)
                        .map { |account|
                          {
                            id: account.id,
                            name: account.name,
                            account_id: account.account_id,
                            platform: account.ads_platform.name,
                            project: account.project.name,
                            data_count: AdsData.where(ads_account: account).count
                          }
                        }

    render json: accounts
  end
end
