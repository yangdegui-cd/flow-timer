class AddWebsiteFieldsToConfig < ActiveRecord::Migration[7.1]
  def change
    add_column :configs, :website_base_url, :string unless column_exists?(:configs, :website_base_url)
    add_column :configs, :facebook_auth_callback_url, :string unless column_exists?(:configs, :facebook_auth_callback_url)
  end
end
