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

ActiveRecord::Schema[7.1].define(version: 2025_08_18_063039) do
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
    t.integer "task_id", null: false
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

  create_table "spaces", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "space_type"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_type"], name: "index_spaces_on_space_type"
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

  create_table "sys_roles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.json "permissions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sys_roles_on_name", unique: true
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

  add_foreign_key "catalogs", "spaces", on_delete: :cascade
  add_foreign_key "ft_flows", "catalogs", on_delete: :cascade
  add_foreign_key "ft_flows", "ft_flow_versions", column: "version_id", on_delete: :cascade
  add_foreign_key "ft_tasks", "catalogs", on_delete: :cascade
  add_foreign_key "ft_tasks", "ft_flows", column: "flow_id", primary_key: "flow_id", on_delete: :cascade
  add_foreign_key "meta_datasources", "catalogs"
  add_foreign_key "meta_hosts", "catalogs"
  add_foreign_key "sys_oauth_providers", "sys_users"
  add_foreign_key "sys_user_roles", "sys_roles"
  add_foreign_key "sys_user_roles", "sys_users"
end
