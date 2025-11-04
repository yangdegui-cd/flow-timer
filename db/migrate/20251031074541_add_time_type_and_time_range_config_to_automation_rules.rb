class AddTimeTypeAndTimeRangeConfigToAutomationRules < ActiveRecord::Migration[7.1]
  def change
    add_column :automation_rules, :time_type, :string, default: 'recent', null: false, comment: '时间类型：recent-最近，range-范围'
    add_column :automation_rules, :time_range_config, :json, comment: '时间范围配置（当time_type为range时使用）'
  end
end
