class CreateOauthProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :oauth_providers do |t|
      t.references :sys_user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.json :extra_data

      t.timestamps
    end

    add_index :oauth_providers, [:provider, :uid], unique: true
    add_index :oauth_providers, [:sys_user_id, :provider], unique: true
  end
end
