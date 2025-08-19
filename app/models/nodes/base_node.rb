# frozen_string_literal: true

class BaseNode < ApplicationService
  attr_accessor :inputs, :data, :prev_nodes, :next_nodes, :begin_time, :end_time

  PERFORM_STATUS = {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }


  def initialize(node_id, node_data, execution_context = {})
    super()
    @node_id = node_id
    @data = node_data || {}
    @execution_context = execution_context
    @inputs = {} # 支持多个输入，key为来源节点ID，value为输出数据
    @prev_nodes = []
    @next_nodes = []
    @begin_time = nil
    @end_time = nil

    # 初始化节点数据结构
    @data['perform_status'] = PERFORM_STATUS[:pending]
    @data['perform_result'] = {}
    @data['perform_error'] = nil
  end

  def perform
    raise NotImplementedError, "Please implement #{self.class}##{__method__}"
  end

  def process
    begin
      @begin_time = Time.now
      self.update_perform_status(PERFORM_STATUS[:processing])

      result = self.perform
      duration = (Time.now - @begin_time).to_f.round(3)

      self.update_perform_status(PERFORM_STATUS[:completed])
      self.update_perform_result(result.merge({ duration: duration }))

      result
    rescue => e
      e.backtrace.each { |line| Rails.logger.error(line) }
      self.update_perform_status(PERFORM_STATUS[:failed])
      self.update_perform_error(e.message)
      raise e
    ensure
      @end_time = Time.now
    end
  end

  # 添加输入数据（来自前置节点的输出）
  def add_input(source_node_id, output_data)
    @inputs[source_node_id] = output_data
  end

  # 获取合并后的输入数据
  def get_merged_inputs
    return {} if @inputs.empty?

    # 如果只有一个输入，直接返回
    return @inputs.values.first if @inputs.size == 1

    # 多个输入时进行合并
    merged = {}
    @inputs.each do |source_id, data|
      if data.is_a?(Hash)
        merged.merge!(data)
      else
        merged[source_id] = data
      end
    end
    merged
  end

  # 设置前置节点
  def set_prev_nodes(nodes)
    @prev_nodes = nodes || []
  end

  # 设置后续节点
  def set_next_nodes(nodes)
    @next_nodes = nodes || []
  end

  def update_perform_status(status)
    raise ArgumentError, "Invalid perform status: #{status}" if status.nil? || !PERFORM_STATUS.values.include?(status)
    self.data["perform_status"] = status
  end

  def update_perform_result(result)
    self.data["perform_result"] = (self.data["perform_result"] || {}).merge(result || {})
  end

  def update_perform_error(error)
    self.data["perform_error"] = error
  end

  # 检查是否可以运行（所有前置节点都已完成）
  def can_execute?
    return true if @prev_nodes.empty?
    @prev_nodes.all? { |node| node.data["perform_status"] == PERFORM_STATUS[:completed] }
  end

  # 检查是否有前置节点失败
  def has_failed_predecessors?
    @prev_nodes.any? { |node| node.data["perform_status"] == PERFORM_STATUS[:failed] }
  end

  # 获取所有前置节点的输出数据
  def collect_predecessor_outputs
    @prev_nodes.each do |node|
      if node.data["perform_status"] == PERFORM_STATUS[:completed]
        output = node.data["perform_result"] || {}
        add_input(node.instance_variable_get(:@node_id), output)
      end
    end
  end

  # 执行节点（供FlowExecutionService调用）
  def execute
    return false unless can_execute?

    if has_failed_predecessors?
      update_perform_status(PERFORM_STATUS[:failed])
      update_perform_error("前置节点执行失败")
      return false
    end

    # 收集前置节点的输出作为输入
    collect_predecessor_outputs
    # 执行节点
    result = process
    true
  end
end
