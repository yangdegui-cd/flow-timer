class AddAdjustFieldsToConfig < ActiveRecord::Migration[7.1]
  def change
    add_column :configs, :adjust_api_token, :string
    add_column :configs, :adjust_api_server, :string, default: 'https://dash.adjust.com/control-center/reports-service/report'
  end
end
