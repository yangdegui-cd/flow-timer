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
  resources :sys_users do
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
  resources :sys_roles do
    member do
      put :update_permissions
    end
    collection do
      get :available_permissions
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
  resources :ft_flow do
    collection do
      get :current_version
      get :get_tree_list
      get :statistics
      patch :batch_update_status
      delete :batch_delete
    end
  end

  resources :ft_task do
    collection do
      post :execute_batch
      get :list_executable
      post :activate
      post :deactivate
      post :execute_immediate
    end
    member do
      post :execute
      get :check_executable
      get :execution_history
    end
  end

  resources :catalog do
    collection do
      post :move_batch
      patch :batch_sort
    end
    member do
      patch :move
    end
  end

  resources :space do
    collection do
      patch :batch_sort
    end
  end

  # 任务执行记录相关路由
  resources :ft_task_execution do
    collection do
      post :execute
      post :batch_execute
      get :stats
      get :show_result
    end
    member do
      post :cancel
      post :retry_execution
    end
  end

  # 流程执行相关路由
  resources :flows, controller: 'flow_execution', param: :flow_id do
    member do
      post :execute
      post :execute_async
      get :status
      post :stop
    end

    collection do
      post :execute_batch
      get :execution_history
      get :execute_by_condition
    end
  end

  # API 路由
  resources :meta_datasource do
    collection do
      get :test_connection
      get :get_tables
      get :get_databases
      get :get_catalogs
      get :get_schemas
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
