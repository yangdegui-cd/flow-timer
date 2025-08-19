# frozen_string_literal: true

class FlowExecutionJob < ApplicationJob
  queue_as :default

  def perform(flow_id, input_params = {})
    Rails.logger.info("开始异步执行流程: #{flow_id}")
    
    begin
      execution_service = FlowExecutionService.new(flow_id)
      result = execution_service.execute(input_params)
      
      Rails.logger.info("异步流程执行完成: #{flow_id}, 成功: #{result[:success]}")
      
      # 可以在这里添加执行完成后的回调处理
      handle_execution_completion(flow_id, result)
      
    rescue => e
      Rails.logger.error("异步流程执行失败: #{flow_id}, 错误: #{e.message}")
      handle_execution_failure(flow_id, e)
      raise e
    end
  end

  private

  def handle_execution_completion(flow_id, result)
    # 执行完成后的处理逻辑
    # 例如：发送通知、更新状态、触发其他流程等
    
    if result[:success]
      Rails.logger.info("流程 #{flow_id} 执行成功，结果已保存")
    else
      Rails.logger.error("流程 #{flow_id} 执行失败: #{result[:error]}")
    end
  end

  def handle_execution_failure(flow_id, error)
    # 执行失败后的处理逻辑
    # 例如：记录错误、发送告警、重试机制等
    
    Rails.logger.error("流程 #{flow_id} 执行异常: #{error.message}")
    Rails.logger.error("错误堆栈: #{error.backtrace.join('\n')}")
  end
end