class RemoveFacebookAuthCallbackUrlFromConfigs < ActiveRecord::Migration[7.1]
  def change
    remove_column :configs, :facebook_auth_callback_url, :string
  end
end
