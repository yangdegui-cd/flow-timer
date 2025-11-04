class AddApiDomainToConfigs < ActiveRecord::Migration[7.1]
  def change
    add_column :configs, :api_domain, :string, comment: '后端API域名(含端口), 如: 192.168.101.99:3000'
    add_column :configs, :api_use_ssl, :boolean, default: false, comment: '后端API是否启用SSL'
  end
end
