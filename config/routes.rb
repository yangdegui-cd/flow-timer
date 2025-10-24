Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  require 'resque-scheduler'
  require 'resque/scheduler/server'

  mount Resque::Server.new => "/resque"
  mount ActionCable.server => '/cable'
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # 认证相关路由
  scope :auth do
    post :login, to: 'auth#login'
    post :register, to: 'auth#register'
    delete :logout, to: 'auth#logout'
    get :me, to: 'auth#me'
    put :change_password, to: 'auth#change_password'
    put :update_profile, to: 'auth#update_profile'
    post :bind_oauth, to: 'auth#bind_oauth'
    delete 'unbind_oauth/:provider', to: 'auth#unbind_oauth'
  end

  # OAuth回调路由（初始化路由由omniauth中间件处理）
  get '/auth/:provider/callback', to: 'auth#oauth_callback'
  get '/auth/failure', to: 'auth#oauth_failure'

  # 用户管理路由
  resources :sys_user do
    member do
      put :change_status
      put :assign_roles
      delete :remove_role
    end
    collection do
      get :roles
      get :permissions
    end
  end

  # 角色管理路由
  resources :sys_role do
    member do
      put :update_permissions
      get :permissions
      put :assign_permissions
    end
    collection do
      get :available_permissions
    end
  end

  # 权限管理路由
  resources :sys_permission, except: [:new, :edit] do
    collection do
      put :batch_status
      get :modules
      post :sync_system_permissions
    end
  end

  # 系统日志管理路由
  resources :sys_logs, only: [:index, :show] do
    collection do
      get :my_logs
      get :stats
      post :cleanup
    end
  end

  # 项目管理路由
  resources :projects do
    member do
      post :assign_users
    end

    # 项目下的自动化规则管理
    resources :automation_rules, only: [:index, :create]

    # 项目下的广告账户管理
    resources :ads_accounts, except: [:new, :edit] do
      member do
        post :sync
        post :refresh_token
        patch :toggle
        post :bind
        delete :unbind
      end
      collection do
        get :by_platform
        get :available
      end
    end

    # 项目下的自动化日志管理
    resources :automation_logs, only: [:index] do
      collection do
        get :stats
      end
    end
  end

  # 自动化日志详情（独立路由）
  resources :automation_logs, only: [:show]

  # 自动化规则管理（独立路由）
  resources :automation_rules, only: [:show, :update, :destroy] do
    member do
      patch :toggle
    end
  end

  # 广告平台路由
  resources :ads_platforms, only: [:index, :show]

  # Facebook授权路由
  scope :facebook_auth do
    post :authorize, to: 'facebook_auth#authorize'
    get :callback, to: 'facebook_auth#callback'
  end

  # 其他平台授权路由 (预留)
  scope :google_auth do
    post :authorize, to: 'google_auth#authorize'
    get :callback, to: 'google_auth#callback'
  end

  # 用户项目关联管理路由
  resources :sys_user_projects, except: [:new, :edit] do
    collection do
      get 'user_projects/:user_id', to: 'sys_user_projects#user_projects'
      get 'project_users/:project_id', to: 'sys_user_projects#project_users'
      post :bulk_assign
    end
  end

  # API路由
  namespace :api do
    # 广告数据API
    resources :ads_data, only: [:index, :show] do
      collection do
        get :stats
        get :campaigns
        get :accounts
      end
    end
  end

  # Resque 监控相关路由
  scope :resque_monitor do
    get :stats, to: 'resque_monitor#stats'
    get :queues, to: 'resque_monitor#queues'
    get 'queue/:name', to: 'resque_monitor#queue_detail'
    get 'queue/:name/details', to: 'resque_monitor#queue_details'
    get :workers, to: 'resque_monitor#workers'
    get :failed_jobs, to: 'resque_monitor#failed_jobs'
    post 'failed/:id/retry', to: 'resque_monitor#retry_failed'
    delete 'failed/:id', to: 'resque_monitor#remove_failed_job'
    delete :clear_failed, to: 'resque_monitor#clear_failed'
    post :requeue_all_failed, to: 'resque_monitor#requeue_all_failed'
    delete 'queue/:name', to: 'resque_monitor#remove_queue'
    delete 'queue/:name/clear', to: 'resque_monitor#clear_queue'
    post :restart_workers, to: 'resque_monitor#restart_workers'
    # resque-scheduler 相关路由
    get :scheduled_jobs, to: 'resque_monitor#scheduled_jobs'
    get :delayed_jobs, to: 'resque_monitor#delayed_jobs'
    delete :clear_delayed_jobs, to: 'resque_monitor#clear_delayed_jobs'
    delete 'delayed/:timestamp/:job_class', to: 'resque_monitor#remove_delayed_job'
  end
end
