class CheckAutomationRuleJob < BaseResqueJob
  @queue = :check_automation_rule

  def self.perform(project_id)
    project = Project.includes(:automation_rules)
                     .where(id: project_id)
                     .where(automation_rules: { enabled: true })
                     .first

    project&.automation_rules.each do |rule|
      begin
        CheckAutomationRuleService.new(rule).execute
      rescue => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
