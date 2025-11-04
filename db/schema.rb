# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_03_093122) do
  create_table "ad_states", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "platform", null: false, comment: "广告平台: facebook, google, tiktok等"
    t.bigint "ads_account_id", null: false, comment: "广告账户ID"
    t.string "campaign_id", null: false, comment: "广告系列ID"
    t.string "campaign_name", comment: "广告系列名称"
    t.string "campaign_effective_status", comment: "广告系列实际状态"
    t.string "campaign_objective", comment: "广告目标: APP_INSTALLS, CONVERSIONS等"
    t.string "campaign_buying_type", comment: "购买类型: AUCTION, RESERVATION"
    t.string "adset_id", null: false, comment: "广告组ID"
    t.string "adset_name", comment: "广告组名称"
    t.string "adset_effective_status", comment: "广告组实际状态"
    t.string "ad_id", null: false, comment: "广告ID"
    t.string "ad_name", comment: "广告名称"
    t.string "ad_effective_status", comment: "广告实际状态"
    t.boolean "is_active", default: false, comment: "是否正在投放"
    t.decimal "daily_budget", precision: 15, scale: 2, comment: "每日预算（元）"
    t.decimal "lifetime_budget", precision: 15, scale: 2, comment: "总预算（元）"
    t.string "budget_remaining", comment: "剩余预算"
    t.string "spend_cap", comment: "花费上限"
    t.decimal "bid_amount", precision: 15, scale: 2, comment: "出价金额（元）"
    t.string "bid_strategy", comment: "出价策略"
    t.string "optimization_goal", comment: "优化目标"
    t.string "billing_event", comment: "计费事件"
    t.json "targeting", comment: "定向设置（JSON）"
    t.string "creative_id", comment: "创意ID"
    t.string "creative_name", comment: "创意名称"
    t.text "image_url", comment: "图片素材URL"
    t.string "image_hash", comment: "图片哈希"
    t.string "video_id", comment: "视频ID"
    t.text "video_url", comment: "视频URL"
    t.text "thumbnail_url", comment: "视频缩略图URL"
    t.text "ad_title", comment: "广告标题"
    t.text "ad_body", comment: "广告正文"
    t.text "ad_description", comment: "广告描述"
    t.string "call_to_action", comment: "行动号召按钮"
    t.text "link_url", comment: "落地页链接"
    t.datetime "start_time", comment: "开始时间"
    t.datetime "stop_time", comment: "结束时间"
    t.datetime "platform_created_time", comment: "平台创建时间"
    t.datetime "platform_updated_time", comment: "平台更新时间"
    t.datetime "synced_at", comment: "最后同步时间"
    t.string "sync_status", default: "pending", comment: "同步状态: pending, synced, error"
    t.text "sync_error", comment: "同步错误信息"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_key", limit: 32, comment: "MD5哈希唯一键"
    t.index ["ad_id"], name: "index_ad_states_on_ad_id"
    t.index ["ads_account_id"], name: "index_ad_states_on_ads_account_id"
    t.index ["adset_id"], name: "index_ad_states_on_adset_id"
    t.index ["campaign_id"], name: "index_ad_states_on_campaign_id"
    t.index ["creative_id"], name: "index_ad_states_on_creative_id"
    t.index ["is_active"], name: "index_ad_states_on_is_active"
    t.index ["platform", "ad_id"], name: "idx_ad_states_platform_ad"
    t.index ["platform", "ad_name"], name: "idx_ad_states_platform_ad_name"
    t.index ["platform", "adset_id"], name: "idx_ad_states_platform_adset"
    t.index ["platform", "adset_name"], name: "idx_ad_states_platform_adset_name"
    t.index ["platform", "campaign_id"], name: "idx_ad_states_platform_campaign"
    t.index ["platform", "campaign_name"], name: "idx_ad_states_platform_campaign_name"
    t.index ["platform"], name: "index_ad_states_on_platform"
    t.index ["synced_at"], name: "index_ad_states_on_synced_at"
    t.index ["unique_key"], name: "index_ad_states_on_unique_key", unique: true
  end

  create_table "ads_accounts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_id", null: false
    t.bigint "ads_platform_id", null: false
    t.bigint "project_id"
    t.bigint "sys_user_id", null: false
    t.string "account_status", default: "active"
    t.string "currency"
    t.string "timezone"
    t.decimal "account_balance", precision: 15, scale: 2
    t.decimal "daily_budget", precision: 15, scale: 2
    t.boolean "active", default: true
    t.datetime "last_sync_at"
    t.integer "sync_frequency", default: 60
    t.string "sync_status", default: "pending"
    t.text "last_error"
    t.text "config"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_status"], name: "index_ads_accounts_on_account_status"
    t.index ["active"], name: "index_ads_accounts_on_active"
    t.index ["ads_platform_id", "account_id"], name: "index_ads_accounts_on_platform_and_account_id", unique: true
    t.index ["ads_platform_id"], name: "index_ads_accounts_on_ads_platform_id"
    t.index ["project_id"], name: "index_ads_accounts_on_project_id"
    t.index ["sync_status"], name: "index_ads_accounts_on_sync_status"
    t.index ["sys_user_id"], name: "index_ads_accounts_on_sys_user_id"
  end

  create_table "ads_adjust_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "project_id", null: false, comment: "项目ID"
    t.string "platform", default: "adjust", null: false, comment: "平台标识"
    t.date "date", null: false, comment: "日期"
    t.string "hour", comment: "小时 00-23"
    t.datetime "datetime", comment: "精确到小时的时间"
    t.string "campaign_network", comment: "推广活动网络（对应 campaign_name）"
    t.string "campaign_id_network", comment: "推广活动网络ID（对应 campaign_id）"
    t.string "adgroup_network", comment: "广告组网络（对应 adset_name）"
    t.string "adgroup_id_network", comment: "广告组网络ID（对应 adset_id）"
    t.string "creative_network", comment: "创意网络（对应 ad_name/creative_name）"
    t.string "creative_id_network", comment: "创意网络ID（对应 ad_id/creative_id）"
    t.bigint "installs", default: 0, comment: "安装数"
    t.bigint "network_clicks", default: 0, comment: "网络点击数（对应 clicks）"
    t.bigint "network_impressions", default: 0, comment: "网络展示数（对应 impressions）"
    t.decimal "cost", precision: 15, scale: 2, default: "0.0", comment: "成本（对应 spend）"
    t.decimal "cohort_all_revenue", precision: 15, scale: 2, default: "0.0", comment: "群组总收入"
    t.decimal "all_revenue_total_d0", precision: 15, scale: 2, default: "0.0", comment: "D0 总收入"
    t.decimal "all_revenue_total_d1", precision: 15, scale: 2, default: "0.0", comment: "D1 总收入"
    t.decimal "all_revenue_total_d2", precision: 15, scale: 2, default: "0.0", comment: "D2 总收入"
    t.decimal "all_revenue_total_d3", precision: 15, scale: 2, default: "0.0", comment: "D3 总收入"
    t.decimal "all_revenue_total_d4", precision: 15, scale: 2, default: "0.0", comment: "D4 总收入"
    t.decimal "all_revenue_total_d5", precision: 15, scale: 2, default: "0.0", comment: "D5 总收入"
    t.decimal "all_revenue_total_d6", precision: 15, scale: 2, default: "0.0", comment: "D6 总收入"
    t.bigint "retained_users_d0", default: 0, comment: "D0 留存用户数"
    t.bigint "retained_users_d1", default: 0, comment: "D1 留存用户数"
    t.bigint "retained_users_d2", default: 0, comment: "D2 留存用户数"
    t.bigint "retained_users_d3", default: 0, comment: "D3 留存用户数"
    t.bigint "retained_users_d4", default: 0, comment: "D4 留存用户数"
    t.bigint "retained_users_d5", default: 0, comment: "D5 留存用户数"
    t.bigint "retained_users_d6", default: 0, comment: "D6 留存用户数"
    t.bigint "paying_users_d0", default: 0, comment: "D0 付费用户数"
    t.bigint "paying_users_d1", default: 0, comment: "D1 付费用户数"
    t.bigint "paying_users_d2", default: 0, comment: "D2 付费用户数"
    t.bigint "paying_users_d3", default: 0, comment: "D3 付费用户数"
    t.bigint "paying_users_d4", default: 0, comment: "D4 付费用户数"
    t.bigint "paying_users_d5", default: 0, comment: "D5 付费用户数"
    t.bigint "paying_users_d6", default: 0, comment: "D6 付费用户数"
    t.string "data_status", default: "active", comment: "active, deleted, invalid"
    t.string "data_source", default: "adjust_api", comment: "adjust_api, manual, import"
    t.datetime "data_fetched_at", comment: "数据拉取时间"
    t.string "unique_key", comment: "唯一标识：project_id + date + hour + dimensions 的组合哈希"
    t.text "raw_data", comment: "完整的原始API响应（JSON）"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adgroup_network"], name: "idx_ads_adjust_data_adgroup"
    t.index ["campaign_network"], name: "idx_ads_adjust_data_campaign"
    t.index ["creative_network"], name: "idx_ads_adjust_data_creative"
    t.index ["data_fetched_at"], name: "index_ads_adjust_data_on_data_fetched_at"
    t.index ["data_status"], name: "index_ads_adjust_data_on_data_status"
    t.index ["date"], name: "index_ads_adjust_data_on_date"
    t.index ["datetime"], name: "index_ads_adjust_data_on_datetime"
    t.index ["project_id", "date", "hour"], name: "idx_ads_adjust_data_project_date_hour"
    t.index ["project_id", "date"], name: "idx_ads_adjust_data_project_date"
    t.index ["project_id"], name: "index_ads_adjust_data_on_project_id"
  end

  create_table "ads_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "ads_account_id", null: false
    t.bigint "project_id", null: false
    t.string "platform", null: false
    t.date "date", null: false
    t.string "hour"
    t.string "week"
    t.string "month"
    t.string "quarter"
    t.string "year"
    t.string "campaign_id"
    t.string "campaign_name"
    t.string "adset_id"
    t.string "adset_name"
    t.string "ad_id"
    t.string "ad_name"
    t.bigint "impressions", default: 0
    t.bigint "clicks", default: 0
    t.decimal "spend", precision: 15, scale: 2, default: "0.0"
    t.bigint "conversions", default: 0
    t.bigint "app_installs", default: 0
    t.text "raw_data"
    t.string "data_status", default: "active"
    t.string "data_source"
    t.datetime "data_fetched_at"
    t.string "unique_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "datetime", comment: "精确到小时的时间"
    t.integer "hour_of_day", comment: "一天中的小时 0-23"
    t.string "day_of_week", comment: "星期几"
    t.string "impression_device", comment: "展示设备"
    t.string "device_model", comment: "设备型号"
    t.string "browser_name", comment: "浏览器名称"
    t.string "carrier", comment: "运营商"
    t.string "dma_code", comment: "DMA区域代码"
    t.string "postal_code", comment: "邮政编码"
    t.string "user_bucket", comment: "用户分桶"
    t.string "click_device", comment: "点击设备"
    t.string "age_range", comment: "年龄段"
    t.string "call_to_action", comment: "行动号召按钮"
    t.string "link_click_destination", comment: "链接点击目标"
    t.string "creative_type", comment: "创意类型"
    t.bigint "purchase_conversions", default: 0, comment: "购买转化"
    t.bigint "add_to_cart_conversions", default: 0, comment: "加购转化"
    t.bigint "lead_conversions", default: 0, comment: "潜客转化"
    t.bigint "app_install_conversions", default: 0, comment: "应用安装转化"
    t.bigint "page_likes", default: 0, comment: "页面赞"
    t.bigint "post_shares", default: 0, comment: "帖子分享"
    t.bigint "video_play_actions", default: 0, comment: "视频播放操作"
    t.bigint "installs", default: 0
    t.decimal "revenue", precision: 15, scale: 2, default: "0.0"
    t.index ["ad_id", "date"], name: "idx_ads_data_ad_date"
    t.index ["ads_account_id", "platform", "date"], name: "idx_ads_data_account_platform_date"
    t.index ["ads_account_id"], name: "index_ads_data_on_ads_account_id"
    t.index ["adset_id", "date"], name: "idx_ads_data_adset_date"
    t.index ["age_range"], name: "index_ads_data_on_age_range", comment: "年龄段索引"
    t.index ["campaign_id", "date"], name: "idx_ads_data_campaign_date"
    t.index ["creative_type"], name: "index_ads_data_on_creative_type", comment: "创意类型索引"
    t.index ["data_fetched_at"], name: "index_ads_data_on_data_fetched_at"
    t.index ["data_status"], name: "index_ads_data_on_data_status"
    t.index ["datetime"], name: "index_ads_data_on_datetime", comment: "时间索引"
    t.index ["day_of_week"], name: "index_ads_data_on_day_of_week", comment: "星期索引"
    t.index ["device_model"], name: "index_ads_data_on_device_model", comment: "设备型号索引"
    t.index ["hour_of_day"], name: "index_ads_data_on_hour_of_day", comment: "小时索引"
    t.index ["platform", "date"], name: "idx_ads_data_platform_date"
    t.index ["project_id", "platform", "date"], name: "idx_ads_data_project_platform_date"
    t.index ["project_id"], name: "index_ads_data_on_project_id"
    t.index ["year", "month"], name: "idx_ads_data_year_month"
    t.index ["year", "quarter"], name: "idx_ads_data_year_quarter"
    t.index ["year", "week"], name: "idx_ads_data_year_week"
  end

  create_table "ads_dimensions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "display_name"
    t.string "name"
    t.string "column"
    t.string "category"
    t.string "description"
    t.integer "sort_order", default: 0
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "display_config", comment: "前端展示配置（宽度、对齐方式等）"
    t.index ["column"], name: "index_ads_dimensions_on_column", unique: true
    t.index ["name"], name: "index_ads_dimensions_on_name", unique: true
  end

  create_table "ads_metrics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "display_name", null: false, comment: "中文名称"
    t.string "key", null: false, comment: "英文名称"
    t.text "description", comment: "描述"
    t.text "sql_expression", null: false, comment: "SQL表达式"
    t.string "unit", comment: "单位"
    t.string "color", comment: "展示颜色"
    t.decimal "filter_max", precision: 15, scale: 2, comment: "筛选最大值"
    t.decimal "filter_min", precision: 15, scale: 2, comment: "筛选最小值"
    t.string "category", comment: "分类"
    t.string "data_source", comment: "数据源：platform(平台数据), adjust(Adjust数据), calculated(计算指标)"
    t.integer "sort_order", default: 0, comment: "排序"
    t.boolean "is_active", default: true, comment: "是否启用"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "display_config", comment: "前端展示配置（对齐方式、格式化等）"
    t.index ["category"], name: "index_metrics_on_category"
    t.index ["data_source"], name: "index_metrics_on_data_source"
    t.index ["is_active"], name: "index_metrics_on_is_active"
    t.index ["key"], name: "index_metrics_on_name_en", unique: true
  end

  create_table "ads_platforms", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "api_version"
    t.string "base_url"
    t.string "oauth_url"
    t.text "scopes"
    t.string "auth_method", default: "oauth2"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_ads_platforms_on_active"
    t.index ["slug"], name: "index_ads_platforms_on_slug", unique: true
  end

  create_table "automation_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "sys_user_id"
    t.string "action_type", null: false, comment: "操作类型: 项目编辑, 规则触发, 定时任务, 调整广告投放"
    t.text "action", comment: "具体操作内容"
    t.integer "duration", comment: "执行时长(毫秒)"
    t.string "status", default: "success", null: false, comment: "状态: success, failed"
    t.json "remark", comment: "备注信息"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_automation_logs_on_action_type"
    t.index ["created_at"], name: "index_automation_logs_on_created_at"
    t.index ["project_id"], name: "index_automation_logs_on_project_id"
    t.index ["status"], name: "index_automation_logs_on_status"
    t.index ["sys_user_id"], name: "index_automation_logs_on_sys_user_id"
  end

  create_table "automation_rules", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.string "time_granularity", default: "hour", null: false
    t.integer "time_range", default: 1, null: false
    t.json "condition_group", null: false
    t.string "action", null: false
    t.decimal "action_value", precision: 10, scale: 2
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_type", default: "recent", null: false, comment: "时间类型：recent-最近，range-范围"
    t.json "time_range_config", comment: "时间范围配置（当time_type为range时使用）"
    t.index ["enabled"], name: "index_automation_rules_on_enabled"
    t.index ["project_id", "enabled"], name: "index_automation_rules_on_project_id_and_enabled"
    t.index ["project_id"], name: "index_automation_rules_on_project_id"
  end

  create_table "configs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "website_base_url", limit: 225
    t.boolean "use_email_notification"
    t.string "smtp_server"
    t.integer "smtp_port"
    t.string "email_notification_email"
    t.string "email_notification_pwd"
    t.string "email_notification_name"
    t.string "email_notification_display_name"
    t.boolean "email_notification_use_tls"
    t.string "qy_wechat_notification_key"
    t.string "qy_wechat_notification_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "adjust_api_token"
    t.string "adjust_api_server", default: "https://dash.adjust.com/control-center/reports-service/report"
    t.string "facebook_app_id"
    t.string "facebook_app_secret"
    t.text "facebook_access_token"
    t.datetime "facebook_token_expired_at"
    t.text "google_ads_developer_token", comment: "Google Ads 开发者令牌"
    t.string "google_ads_client_id", comment: "Google Ads OAuth 客户端ID"
    t.string "google_ads_client_secret", comment: "Google Ads OAuth 客户端密钥"
    t.text "google_ads_refresh_token", comment: "Google Ads 刷新令牌"
    t.string "google_ads_customer_id", comment: "Google Ads 客户账户ID"
    t.string "tiktok_app_id", comment: "TikTok 应用ID"
    t.string "tiktok_app_secret", comment: "TikTok 应用密钥"
    t.text "tiktok_access_token", comment: "TikTok 访问令牌"
    t.datetime "tiktok_token_expired_at", comment: "TikTok 令牌过期时间"
    t.string "api_domain", comment: "后端API域名(含端口), 如: 192.168.101.99:3000"
    t.boolean "api_use_ssl", default: false, comment: "后端API是否启用SSL"
  end

  create_table "projects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date", null: false
    t.integer "time_zone"
    t.boolean "active_ads_automate", default: true, null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "adjust_game_token"
    t.index ["active_ads_automate"], name: "index_projects_on_active_ads_automate"
    t.index ["name"], name: "index_projects_on_name", unique: true
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "sys_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", comment: "系统操作日志表", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "用户ID"
    t.string "controller_name", limit: 100, null: false, comment: "控制器名称"
    t.string "action_name", limit: 50, null: false, comment: "动作名称"
    t.string "request_method", limit: 10, null: false, comment: "请求方法 GET/POST/PUT/DELETE"
    t.string "request_url", limit: 500, null: false, comment: "请求URL"
    t.text "url_params", comment: "URL参数 JSON格式"
    t.text "body_params", comment: "请求体参数 JSON格式"
    t.datetime "request_time", null: false, comment: "请求开始时间"
    t.datetime "response_time", comment: "响应结束时间"
    t.integer "duration", comment: "请求耗时(毫秒)"
    t.integer "status_code", comment: "HTTP状态码"
    t.string "ip_address", limit: 45, comment: "客户端IP地址"
    t.string "user_agent", limit: 500, comment: "用户代理"
    t.text "error_message", comment: "错误信息(如果有)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controller_name", "action_name"], name: "index_sys_logs_on_controller_name_and_action_name", comment: "控制器动作索引"
    t.index ["ip_address"], name: "index_sys_logs_on_ip_address", comment: "IP地址索引"
    t.index ["request_method"], name: "index_sys_logs_on_request_method", comment: "请求方法索引"
    t.index ["request_time"], name: "index_sys_logs_on_request_time", comment: "请求时间索引"
    t.index ["status_code"], name: "index_sys_logs_on_status_code", comment: "状态码索引"
    t.index ["user_id"], name: "index_sys_logs_on_user_id"
  end

  create_table "sys_oauth_providers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "sys_user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.json "extra_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_sys_oauth_providers_on_provider_and_uid", unique: true
    t.index ["sys_user_id", "provider"], name: "index_sys_oauth_providers_on_sys_user_id_and_provider", unique: true
    t.index ["sys_user_id"], name: "index_sys_oauth_providers_on_sys_user_id"
  end

  create_table "sys_permissions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", limit: 100, null: false, comment: "权限标识"
    t.string "name", limit: 100, null: false, comment: "权限名称"
    t.text "description", comment: "权限描述"
    t.string "module", limit: 50, null: false, comment: "所属模块"
    t.string "action", limit: 20, null: false, comment: "操作类型"
    t.string "resource", limit: 200, comment: "资源标识"
    t.boolean "is_active", default: true, null: false, comment: "是否启用"
    t.integer "sort_order", default: 0, null: false, comment: "排序"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_system", default: false, null: false, comment: "是否系统权限"
    t.index ["code"], name: "index_sys_permissions_on_code", unique: true
    t.index ["is_active"], name: "index_sys_permissions_on_is_active"
    t.index ["is_system"], name: "index_sys_permissions_on_is_system"
    t.index ["module"], name: "index_sys_permissions_on_module"
  end

  create_table "sys_role_permissions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "sys_role_id", null: false
    t.bigint "sys_permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sys_permission_id"], name: "index_sys_role_permissions_on_sys_permission_id"
    t.index ["sys_role_id", "sys_permission_id"], name: "idx_unique_role_permission", unique: true
    t.index ["sys_role_id"], name: "index_sys_role_permissions_on_sys_role_id"
  end

  create_table "sys_roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", limit: 100
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_system", default: false, null: false, comment: "是否系统角色"
    t.boolean "is_active", default: true, null: false, comment: "是否启用"
    t.integer "sort_order", default: 0, null: false, comment: "排序"
    t.index ["code"], name: "index_sys_roles_on_code", unique: true
    t.index ["is_active"], name: "index_sys_roles_on_is_active"
    t.index ["is_system"], name: "index_sys_roles_on_is_system"
    t.index ["name"], name: "index_sys_roles_on_name", unique: true
  end

  create_table "sys_user_projects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "sys_user_id", null: false
    t.bigint "project_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "assigned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_sys_user_projects_on_project_id"
    t.index ["role"], name: "index_sys_user_projects_on_role"
    t.index ["sys_user_id", "project_id"], name: "index_sys_user_projects_on_sys_user_id_and_project_id", unique: true
    t.index ["sys_user_id"], name: "index_sys_user_projects_on_sys_user_id"
  end

  create_table "sys_user_roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "sys_user_id", null: false
    t.bigint "sys_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sys_role_id"], name: "index_sys_user_roles_on_sys_role_id"
    t.index ["sys_user_id", "sys_role_id"], name: "index_sys_user_roles_on_sys_user_id_and_sys_role_id", unique: true
    t.index ["sys_user_id"], name: "index_sys_user_roles_on_sys_user_id"
  end

  create_table "sys_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.string "name", null: false
    t.string "avatar_url"
    t.string "status", default: "active", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_sys_users_on_email", unique: true
    t.index ["status"], name: "index_sys_users_on_status"
  end

  add_foreign_key "ad_states", "ads_accounts"
  add_foreign_key "ads_accounts", "ads_platforms"
  add_foreign_key "ads_accounts", "projects"
  add_foreign_key "ads_accounts", "sys_users"
  add_foreign_key "ads_adjust_data", "projects"
  add_foreign_key "ads_data", "ads_accounts"
  add_foreign_key "ads_data", "projects"
  add_foreign_key "automation_logs", "projects"
  add_foreign_key "automation_logs", "sys_users"
  add_foreign_key "automation_rules", "projects"
  add_foreign_key "sys_logs", "sys_users", column: "user_id"
  add_foreign_key "sys_oauth_providers", "sys_users"
  add_foreign_key "sys_role_permissions", "sys_permissions"
  add_foreign_key "sys_role_permissions", "sys_roles"
  add_foreign_key "sys_user_projects", "projects"
  add_foreign_key "sys_user_projects", "sys_users"
  add_foreign_key "sys_user_roles", "sys_roles"
  add_foreign_key "sys_user_roles", "sys_users"
end
