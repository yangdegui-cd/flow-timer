class CleanupJob < BaseResqueJob
  @queue = :maintenance

  def perform(days_to_keep = 30)
    log_info("Starting cleanup of old task executions (keeping #{days_to_keep} days)")
    
    cutoff_date = days_to_keep.days.ago
    
    # Find old executions
    old_executions = FtTaskExecution.where('created_at < ?', cutoff_date)
    count = old_executions.count
    
    if count > 0
      log_info("Found #{count} old task executions to delete")
      
      # Delete in batches to avoid memory issues
      deleted_count = 0
      old_executions.find_in_batches(batch_size: 1000) do |batch|
        batch.each(&:destroy)
        deleted_count += batch.size
        log_info("Deleted #{deleted_count}/#{count} old executions")
      end
      
      log_info("Cleanup completed: #{deleted_count} task executions deleted")
    else
      log_info("No old task executions found to delete")
    end
    
    # Also clean up failed jobs older than 7 days
    clean_old_failed_jobs
    
    return { deleted_executions: count, cutoff_date: cutoff_date.iso8601 }
  end

  private

  def clean_old_failed_jobs
    begin
      # This is specific to Resque implementation
      # Clean up failed jobs older than 7 days
      cutoff_timestamp = 7.days.ago.to_i
      
      failed_count = Resque::Failure.count
      if failed_count > 0
        log_info("Found #{failed_count} failed jobs to examine")
        
        cleared_count = 0
        (0...failed_count).each do |i|
          job_data = Resque::Failure.all(i, 1)
          next if job_data.empty?
          
          job = job_data.first
          if job['failed_at'] && Time.parse(job['failed_at']).to_i < cutoff_timestamp
            Resque::Failure.remove(i - cleared_count)
            cleared_count += 1
          end
        end
        
        log_info("Cleaned up #{cleared_count} old failed jobs")
      else
        log_info("No failed jobs found")
      end
    rescue => e
      log_error("Failed to clean up old failed jobs: #{e.message}", e)
    end
  end
end