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

ActiveRecord::Schema[7.1].define(version: 2025_10_24_080953) do
  create_table "ads_accounts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_id", null: false
    t.bigint "ads_platform_id", null: false
    t.bigint "project_id"
    t.bigint "sys_user_id", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.string "app_id"
    t.text "app_secret"
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
    t.string "creative_id"
    t.string "creative_name"
    t.string "campaign_status"
    t.string "campaign_objective"
    t.string "buying_type"
    t.decimal "campaign_daily_budget", precision: 15, scale: 2
    t.decimal "campaign_lifetime_budget", precision: 15, scale: 2
    t.string "adset_status"
    t.string "optimization_goal"
    t.string "billing_event"
    t.decimal "adset_daily_budget", precision: 15, scale: 2
    t.decimal "bid_amount", precision: 15, scale: 2
    t.string "ad_status"
    t.string "ad_format"
    t.text "ad_creative_data"
    t.text "targeting_data"
    t.string "age_min"
    t.string "age_max"
    t.string "gender"
    t.text "countries"
    t.text "regions"
    t.text "cities"
    t.text "interests"
    t.text "behaviors"
    t.text "demographics"
    t.text "placements"
    t.string "device_platform"
    t.string "publisher_platform"
    t.bigint "impressions", default: 0
    t.bigint "clicks", default: 0
    t.decimal "spend", precision: 15, scale: 2, default: "0.0"
    t.bigint "reach", default: 0
    t.decimal "frequency", precision: 8, scale: 4, default: "0.0"
    t.decimal "cpm", precision: 15, scale: 4, default: "0.0"
    t.decimal "cpc", precision: 15, scale: 4, default: "0.0"
    t.decimal "ctr", precision: 10, scale: 6, default: "0.0"
    t.bigint "conversions", default: 0
    t.bigint "purchases", default: 0
    t.decimal "conversion_value", precision: 15, scale: 2, default: "0.0"
    t.decimal "purchase_value", precision: 15, scale: 2, default: "0.0"
    t.decimal "roas", precision: 10, scale: 4, default: "0.0"
    t.decimal "cost_per_conversion", precision: 15, scale: 4, default: "0.0"
    t.decimal "cost_per_purchase", precision: 15, scale: 4, default: "0.0"
    t.bigint "video_views", default: 0
    t.bigint "video_views_3s", default: 0
    t.bigint "video_views_10s", default: 0
    t.bigint "video_views_15s", default: 0
    t.bigint "video_views_25_percent", default: 0
    t.bigint "video_views_50_percent", default: 0
    t.bigint "video_views_75_percent", default: 0
    t.bigint "video_views_100_percent", default: 0
    t.decimal "video_avg_play_time", precision: 10, scale: 2, default: "0.0"
    t.bigint "likes", default: 0
    t.bigint "comments", default: 0
    t.bigint "shares", default: 0
    t.bigint "saves", default: 0
    t.bigint "follows", default: 0
    t.bigint "link_clicks", default: 0
    t.bigint "post_engagements", default: 0
    t.bigint "app_installs", default: 0
    t.bigint "app_launches", default: 0
    t.bigint "registrations", default: 0
    t.bigint "add_to_carts", default: 0
    t.bigint "checkouts", default: 0
    t.string "attribution_window"
    t.string "conversion_device"
    t.string "conversion_action_type"
    t.string "audience_type"
    t.string "audience_name"
    t.bigint "audience_size"
    t.string "country_code"
    t.string "country_name"
    t.string "region_code"
    t.string "region_name"
    t.string "city_name"
    t.string "device_type"
    t.string "os_type"
    t.string "browser_type"
    t.string "placement_type"
    t.string "ad_position"
    t.decimal "bid_strategy_amount", precision: 15, scale: 4
    t.string "bid_strategy_type"
    t.decimal "budget_remaining", precision: 15, scale: 2
    t.decimal "budget_used_percent", precision: 5, scale: 2
    t.decimal "quality_score", precision: 5, scale: 2
    t.decimal "relevance_score", precision: 5, scale: 2
    t.datetime "campaign_start_time"
    t.datetime "campaign_end_time"
    t.datetime "adset_start_time"
    t.datetime "adset_end_time"
    t.text "platform_metrics"
    t.text "raw_data"
    t.text "custom_fields"
    t.text "tags"
    t.string "data_status", default: "active"
    t.string "data_source"
    t.datetime "data_fetched_at"
    t.datetime "last_updated_at"
    t.string "unique_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "datetime", comment: "精确到小时的时间"
    t.integer "hour_of_day", comment: "一天中的小时 0-23"
    t.string "day_of_week", comment: "星期几"
    t.string "impression_device", comment: "展示设备"
    t.string "device_model", comment: "设备型号"
    t.string "operating_system", comment: "操作系统"
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
    t.index ["ad_id", "date"], name: "idx_ads_data_ad_date"
    t.index ["ad_status"], name: "index_ads_data_on_ad_status"
    t.index ["ads_account_id", "platform", "date"], name: "idx_ads_data_account_platform_date"
    t.index ["ads_account_id"], name: "index_ads_data_on_ads_account_id"
    t.index ["adset_id", "date"], name: "idx_ads_data_adset_date"
    t.index ["adset_status"], name: "index_ads_data_on_adset_status"
    t.index ["age_range"], name: "index_ads_data_on_age_range", comment: "年龄段索引"
    t.index ["campaign_id", "date"], name: "idx_ads_data_campaign_date"
    t.index ["campaign_status"], name: "index_ads_data_on_campaign_status"
    t.index ["country_code", "region_code"], name: "idx_ads_data_country_region"
    t.index ["country_code", "region_code"], name: "index_ads_data_on_country_code_and_region_code", comment: "地理位置组合索引"
    t.index ["country_code"], name: "index_ads_data_on_country_code"
    t.index ["creative_type"], name: "index_ads_data_on_creative_type", comment: "创意类型索引"
    t.index ["data_fetched_at"], name: "index_ads_data_on_data_fetched_at"
    t.index ["data_status"], name: "index_ads_data_on_data_status"
    t.index ["datetime"], name: "index_ads_data_on_datetime", comment: "时间索引"
    t.index ["day_of_week"], name: "index_ads_data_on_day_of_week", comment: "星期索引"
    t.index ["device_model"], name: "index_ads_data_on_device_model", comment: "设备型号索引"
    t.index ["device_platform"], name: "index_ads_data_on_device_platform"
    t.index ["hour_of_day"], name: "index_ads_data_on_hour_of_day", comment: "小时索引"
    t.index ["operating_system"], name: "index_ads_data_on_operating_system", comment: "操作系统索引"
    t.index ["placement_type"], name: "index_ads_data_on_placement_type"
    t.index ["platform", "date"], name: "idx_ads_data_platform_date"
    t.index ["project_id", "platform", "date"], name: "idx_ads_data_project_platform_date"
    t.index ["project_id"], name: "index_ads_data_on_project_id"
    t.index ["publisher_platform"], name: "index_ads_data_on_publisher_platform"
    t.index ["year", "month"], name: "idx_ads_data_year_month"
    t.index ["year", "quarter"], name: "idx_ads_data_year_quarter"
    t.index ["year", "week"], name: "idx_ads_data_year_week"
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
    t.index ["enabled"], name: "index_automation_rules_on_enabled"
    t.index ["project_id", "enabled"], name: "index_automation_rules_on_project_id_and_enabled"
    t.index ["project_id"], name: "index_automation_rules_on_project_id"
  end

  create_table "catalogs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "space_id", null: false
    t.integer "sort", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_id"], name: "fk_rails_179c689b91"
  end

  create_table "ft_flow_versions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "flow_id", null: false
    t.integer "version", default: 1, null: false
    t.json "flow_config", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ft_flows", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "flow_id", null: false
    t.text "description"
    t.json "params", null: false
    t.bigint "version_id", default: 1, null: false
    t.bigint "catalog_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalog_id"], name: "index_ft_flows_on_catalog_id"
    t.index ["flow_id"], name: "index_ft_flows_on_flow_id", unique: true
    t.index ["status"], name: "index_ft_flows_on_status"
    t.index ["version_id"], name: "fk_rails_aeceb6558b"
  end

  create_table "ft_task_executions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "task_id", limit: 225, null: false
    t.string "execution_id", null: false
    t.string "status", default: "pending", null: false
    t.json "result"
    t.text "error_message"
    t.json "data_quality"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "duration_seconds"
    t.string "execution_type", default: "system", comment: "system, manual"
    t.string "queue"
    t.string "data_time", null: false, comment: "数据时间"
    t.json "system_params", null: false
    t.json "custom_params", null: false
    t.string "resque_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_ft_task_executions_on_created_at"
    t.index ["execution_id"], name: "index_ft_task_executions_on_execution_id", unique: true
    t.index ["resque_job_id"], name: "index_ft_task_executions_on_resque_job_id"
    t.index ["status"], name: "index_ft_task_executions_on_status"
    t.index ["task_id"], name: "index_ft_task_executions_on_task_id"
  end

  create_table "ft_tasks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "task_id", null: false
    t.string "flow_id", null: false
    t.bigint "catalog_id", null: false
    t.string "status", null: false
    t.string "task_type", null: false
    t.string "period_type"
    t.string "cron_expression"
    t.timestamp "effective_time", null: false
    t.timestamp "lose_efficacy_time"
    t.json "params"
    t.string "queue", default: "default", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "dependents", comment: "依赖的任务ID列表，存储为JSON数组"
    t.index ["catalog_id"], name: "index_ft_tasks_on_catalog_id"
    t.index ["flow_id"], name: "index_ft_tasks_on_flow_id"
    t.index ["period_type"], name: "index_ft_tasks_on_period_type"
    t.index ["priority"], name: "index_ft_tasks_on_priority"
    t.index ["status"], name: "index_ft_tasks_on_status"
    t.index ["task_id"], name: "index_ft_tasks_on_task_id", unique: true
  end

  create_table "meta_cos", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false, comment: "COS配置名称"
    t.text "description", comment: "描述信息"
    t.string "region", null: false, comment: "COS地域，如ap-guangzhou"
    t.string "secret_id", null: false, comment: "腾讯云SecretId"
    t.string "secret_key", null: false, comment: "腾讯云SecretKey（加密存储）"
    t.string "bucket", null: false, comment: "存储桶名称"
    t.string "prefix", default: "", comment: "文件前缀路径"
    t.string "storage_class", default: "STANDARD", comment: "存储类型：STANDARD, STANDARD_IA, ARCHIVE等"
    t.string "acl", default: "private", comment: "访问权限：private, public-read, public-read-write"
    t.boolean "use_ssl", default: true, comment: "是否使用SSL"
    t.json "extra_config", comment: "额外配置参数（JSON格式）"
    t.string "status", default: "inactive", comment: "状态：active, inactive, error, testing"
    t.datetime "last_test_at", comment: "最后测试时间"
    t.text "test_result", comment: "测试结果信息"
    t.string "environment", default: "development", comment: "环境标识"
    t.string "tags", comment: "标签，逗号分隔"
    t.text "notes", comment: "备注信息"
    t.integer "sort", default: 0, comment: "排序权重"
    t.bigint "created_by", comment: "创建者ID"
    t.bigint "updated_by", comment: "更新者ID"
    t.bigint "catalog_id", comment: "所属目录ID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket", "region"], name: "index_meta_cos_on_bucket_and_region", comment: "存储桶地域组合索引"
    t.index ["catalog_id"], name: "index_meta_cos_on_catalog_id", comment: "目录索引"
    t.index ["created_by"], name: "index_meta_cos_on_created_by", comment: "创建者索引"
    t.index ["environment"], name: "index_meta_cos_on_environment", comment: "环境索引"
    t.index ["name"], name: "index_meta_cos_on_name", unique: true, comment: "COS配置名称唯一索引"
    t.index ["region"], name: "index_meta_cos_on_region", comment: "地域索引"
    t.index ["status"], name: "index_meta_cos_on_status", comment: "状态索引"
  end

  create_table "meta_datasources", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false, comment: "连接名称"
    t.string "db_type", null: false, comment: "数据库类型：mysql, oracle, hive, postgresql, mariadb, trino, clickhouse, sqlserver"
    t.string "host", null: false, comment: "主机地址"
    t.integer "port", null: false, comment: "端口号"
    t.string "username", null: false, comment: "用户名"
    t.string "password", null: false, comment: "密码"
    t.text "description", comment: "描述信息"
    t.string "status", default: "inactive", comment: "连接状态：active, inactive, error, testing"
    t.json "extra_config", comment: "额外配置参数（JSON格式）"
    t.datetime "last_test_at", comment: "最后测试时间"
    t.text "test_result", comment: "测试结果信息"
    t.bigint "created_by", comment: "创建者ID"
    t.bigint "updated_by", comment: "更新者ID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "catalog_id"
    t.index ["catalog_id"], name: "index_meta_datasources_on_catalog_id"
    t.index ["created_by"], name: "index_meta_datasources_on_created_by", comment: "创建者索引"
    t.index ["db_type"], name: "index_meta_datasources_on_db_type", comment: "数据库类型索引"
    t.index ["host", "port"], name: "index_meta_datasources_on_host_and_port", comment: "主机端口组合索引"
    t.index ["name"], name: "index_meta_datasources_on_name", unique: true, comment: "连接名称唯一索引"
    t.index ["status"], name: "index_meta_datasources_on_status", comment: "状态索引"
  end

  create_table "meta_hosts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "hostname", null: false
    t.integer "port", default: 22
    t.string "username", null: false
    t.string "password"
    t.text "ssh_key"
    t.string "status", default: "active"
    t.string "environment"
    t.json "tags"
    t.text "notes"
    t.datetime "last_tested_at"
    t.string "last_test_result"
    t.text "last_test_error"
    t.integer "sort", default: 0
    t.string "created_by"
    t.string "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "auth_type"
    t.bigint "catalog_id"
    t.index ["catalog_id"], name: "index_meta_hosts_on_catalog_id"
    t.index ["environment"], name: "index_meta_hosts_on_environment"
    t.index ["hostname"], name: "index_meta_hosts_on_hostname"
    t.index ["name"], name: "index_meta_hosts_on_name", unique: true
    t.index ["status"], name: "index_meta_hosts_on_status"
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
    t.index ["active_ads_automate"], name: "index_projects_on_active_ads_automate"
    t.index ["name"], name: "index_projects_on_name", unique: true
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "spaces", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "space_type"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_type"], name: "index_spaces_on_space_type"
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

  add_foreign_key "ads_accounts", "ads_platforms"
  add_foreign_key "ads_accounts", "projects"
  add_foreign_key "ads_accounts", "sys_users"
  add_foreign_key "ads_data", "ads_accounts"
  add_foreign_key "ads_data", "projects"
  add_foreign_key "automation_logs", "projects"
  add_foreign_key "automation_logs", "sys_users"
  add_foreign_key "automation_rules", "projects"
  add_foreign_key "catalogs", "spaces", on_delete: :cascade
  add_foreign_key "ft_flows", "catalogs", on_delete: :cascade
  add_foreign_key "ft_flows", "ft_flow_versions", column: "version_id", on_delete: :cascade
  add_foreign_key "ft_tasks", "catalogs", on_delete: :cascade
  add_foreign_key "ft_tasks", "ft_flows", column: "flow_id", primary_key: "flow_id", on_delete: :cascade
  add_foreign_key "meta_datasources", "catalogs"
  add_foreign_key "meta_hosts", "catalogs"
  add_foreign_key "sys_logs", "sys_users", column: "user_id"
  add_foreign_key "sys_oauth_providers", "sys_users"
  add_foreign_key "sys_role_permissions", "sys_permissions"
  add_foreign_key "sys_role_permissions", "sys_roles"
  add_foreign_key "sys_user_projects", "projects"
  add_foreign_key "sys_user_projects", "sys_users"
  add_foreign_key "sys_user_roles", "sys_roles"
  add_foreign_key "sys_user_roles", "sys_users"
end
