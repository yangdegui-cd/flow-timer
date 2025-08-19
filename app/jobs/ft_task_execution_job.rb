class FtTaskExecutionJob < BaseResqueJob
  @queue = :task_execution

  def self.perform(params)
    TaskExecutionService.new(params).execute
  end
end
