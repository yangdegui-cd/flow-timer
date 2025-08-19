class RenameOauthProviderToSysOauthProvider < ActiveRecord::Migration[7.1]
  def change
    rename_table :oauth_providers, :sys_oauth_providers
  end
end
