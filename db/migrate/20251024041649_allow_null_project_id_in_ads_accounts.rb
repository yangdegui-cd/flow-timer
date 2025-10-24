class AllowNullProjectIdInAdsAccounts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ads_accounts, :project_id, true
  end
end
