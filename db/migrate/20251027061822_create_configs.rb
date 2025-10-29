class CreateConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :configs do |t|
      t.boolean :use_email_notification
      t.string :smtp_server
      t.integer :smtp_port
      t.string :email_notification_email
      t.string :email_notification_pwd
      t.string :email_notification_name
      t.string :email_notification_display_name
      t.boolean :email_notification_use_tls
      t.string :qy_wechat_notification_key
      t.string :qy_wechat_notification_url
      t.timestamps
    end

    Config.create!({use_email_notification: true, email_notification_use_tls:true})
  end
end
