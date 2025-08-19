# frozen_string_literal: true

class FlowExecutionService < ApplicationService
  # 流程执行服务，处理流程的执行逻辑
  # 支持节点实例化、依赖关系分析和拓扑排序执行
  # 使用BaseNode的统一接口来执行各类节点

  # @param flow_id [String] 流程ID
  # @raise [RuntimeError] 如果流程或流程版本不存在
  attr_reader :flow, :flow_version, :execution_context, :execution_log

  def initialize(flow_id, execution_id)
    super()
    @flow = FtFlow.find_by(flow_id: flow_id)
    @task_execution = FtTaskExecution.find_by(execution_id: execution_id)
    @flow_version = @flow.try(&:ft_flow_version)
    @node_instances = {} # 存储节点实例
    @node_dependencies = {} # 存储节点依赖关系
    validate!
  end

  def execute(global_params = {})
    log_info("开始执行流程: #{@flow.name} (#{@flow.flow_id})")
    log_info("流程版本: #{@flow_version.version}")
    @global_params = global_params
    begin
      @task_execution.running!

      # 获取流程配置
      @flow_config = @flow_version.flow_config.deep_symbolize_keys

      nodes = @flow_config[:nodes] || []
      edges = @flow_config[:edges] || []

      log_info("流程配置加载完成，节点数: #{nodes.length}, 边数: #{edges.length}")
      # 过滤掉flow_params节点，这些节点仅用于参数配置，不参与实际执行
      executable_nodes = nodes.reject { |node|
        node_data = node[:data] || {}
        node_data[:node_type] == 'flow_params'
      }

      if executable_nodes.empty?
        log_info("流程没有可执行节点，执行完成")
        @task_execution.completed!
        return { success: true, logs: @logs }
      end

      log_info("总节点数: #{nodes.length}, 可执行节点数: #{executable_nodes.length}")

      # 创建节点实例并建立依赖关系
      create_node_instances(executable_nodes, edges)

      # 分析节点依赖关系
      execution_order = analyze_execution_order(executable_nodes, edges)

      # 按拓扑顺序执行节点
      execute_nodes_in_order(execution_order)

      log_info("流程执行完成")
      @task_execution.completed!
    rescue => e
      log_error("流程执行失败: #{e.message}")
      log_error("错误堆栈: #{e.backtrace.first(5).join('\n')}")
      @task_execution.failed!(e.message)
      { success: false, error: e.message, logs: @logs}
    ensure
      @task_execution.update!(result: @flow_config)
    end
  end

  private

  # 创建节点实例并建立依赖关系
  def create_node_instances(nodes, edges)
    # 首先创建所有节点实例
    nodes.each do |node|
      node_id = node[:id]
      node_data = node[:data] || {}
      node_type = node_data[:node_type]

      # 动态创建节点类实例
      node_class_name = "#{node_type.camelize}Node"

      unless Object.const_defined?(node_class_name)
        log_error("未找到节点类型 #{node_type} 的类定义 #{node_class_name}")
        raise "未找到节点类型 #{node_type}"
      end

      node_class = Object.const_get(node_class_name)
      @node_instances[node_id] = node_class.new(node_id, node_data, @global_params)

      log_info("创建节点实例: #{node_data[:label] || node_id} (类型: #{node_type})")
    end

    # 建立节点间的依赖关系
    build_node_relationships(edges)
  end

  # 建立节点间的依赖关系
  def build_node_relationships(edges)
    # 初始化依赖关系
    @node_instances.each_key do |node_id|
      @node_dependencies[node_id] = []
    end

    edges.each do |edge|
      source_id = edge[:source]
      target_id = edge[:target]

      next unless source_id && target_id
      next unless @node_instances[source_id] && @node_instances[target_id]

      # 记录依赖关系
      @node_dependencies[target_id] << source_id

      # 设置节点间的前后关系
      source_node = @node_instances[source_id]
      target_node = @node_instances[target_id]

      target_node.prev_nodes << source_node
      source_node.next_nodes << target_node

      log_info("建立依赖关系: #{source_id} -> #{target_id}")
    end
  end

  # 按顺序执行节点
  def execute_nodes_in_order(execution_order)
    execution_order.each do |node_id|
      node_instance = @node_instances[node_id]
      next unless node_instance

      execute_node_instance(node_instance, node_id)
    end
  end

  # 执行单个节点实例
  def execute_node_instance(node_instance, node_id)
    node_data = node_instance.data
    node_type = node_data[:node_type]

    begin
      log_info("执行节点: #{node_data[:label] || node_id} (类型: #{node_type})")
      node_instance.execute
      @logs.concat(node_instance.logs)
    rescue => e
      log_error("节点执行失败: #{e.message}")
      raise e
    ensure
      set_node_exec_result(node_id, node_instance.data)
    end
  end

  def set_node_exec_result(node_id, result)
    @flow_config[:nodes].each do |node|
      if node[:id] == node_id
        node[:data] = (node[:data] || {}).merge(result)
      end
    end
  end


  def analyze_execution_order(nodes, edges)
    if edges.empty?
      return nodes.map { |node| node[:id] }
    end

    dependencies = {}
    nodes.each { |node| dependencies[node[:id]] = [] }

    edges.each do |edge|
      source = edge[:source]
      target = edge[:target]
      dependencies[target] << source if source && target
    end

    # 拓扑排序
    visited = Set.new
    result = []

    def topological_visit(node_id, dependencies, visited, result)
      return if visited.include?(node_id)

      visited.add(node_id)
      dependencies[node_id].each do |dep|
        topological_visit(dep, dependencies, visited, result)
      end
      result << node_id
    end

    dependencies.keys.each do |node_id|
      topological_visit(node_id, dependencies, visited, result)
    end

    result
  end


  def validate!
    raise "Flow with id #{flow_id} not found" unless @flow
    raise "Task execution with id #{execution_id} not found" unless @task_execution
    raise "Flow version not found for flow #{flow_id}" unless @flow_version
  end
end
