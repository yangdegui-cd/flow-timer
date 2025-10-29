class AddFacebookFieldsToConfig < ActiveRecord::Migration[7.1]
  def change
    add_column :configs, :website_base_url, :string unless column_exists?(:configs, :website_base_url)
    add_column :configs, :facebook_app_id, :string unless column_exists?(:configs, :facebook_app_id)
    add_column :configs, :facebook_app_secret, :string unless column_exists?(:configs, :facebook_app_secret)
    add_column :configs, :facebook_access_token, :text unless column_exists?(:configs, :facebook_access_token)
    add_column :configs, :facebook_auth_callback_url, :text unless column_exists?(:configs, :facebook_auth_callback_url)
    add_column :configs, :facebook_token_expired_at, :datetime unless column_exists?(:configs, :facebook_token_expired_at)
  end
end
