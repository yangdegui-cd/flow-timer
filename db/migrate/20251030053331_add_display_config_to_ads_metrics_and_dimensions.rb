class AddDisplayConfigToAdsMetricsAndDimensions < ActiveRecord::Migration[7.1]
  def change
    # 为 ads_metrics 添加 display_config JSON 列
    add_column :ads_metrics, :display_config, :json, comment: '前端展示配置（对齐方式、格式化等）'

    # 为 ads_dimensions 添加 display_config JSON 列
    add_column :ads_dimensions, :display_config, :json, comment: '前端展示配置（宽度、对齐方式等）'

    # 更新维度的默认配置
    reversible do |dir|
      dir.up do
        # 时间维度配置
        execute <<-SQL
          UPDATE ads_dimensions
          SET display_config = '{"width": 120, "align": "center", "sortable": true, "frozen": true}'
          WHERE category = 'time';
        SQL

        # 项目维度配置
        execute <<-SQL
          UPDATE ads_dimensions
          SET display_config = '{"width": 150, "align": "left", "sortable": true}'
          WHERE name = 'project_id';
        SQL

        # 平台维度配置
        execute <<-SQL
          UPDATE ads_dimensions
          SET display_config = '{"width": 100, "align": "center", "sortable": true}'
          WHERE name = 'platform';
        SQL

        # 账号维度配置
        execute <<-SQL
          UPDATE ads_dimensions
          SET display_config = '{"width": 180, "align": "left", "sortable": true}'
          WHERE name = 'ads_account_id';
        SQL

        # 广告系列、广告组、广告维度配置
        execute <<-SQL
          UPDATE ads_dimensions
          SET display_config = '{"width": 200, "align": "left", "sortable": true, "ellipsis": true}'
          WHERE name IN ('campaign_name', 'adset_name', 'ad_name');
        SQL

        # 更新指标的默认配置
        # 货币类指标
        execute <<-SQL
          UPDATE ads_metrics
          SET display_config = '{"align": "right", "format": "currency", "decimals": 2}'
          WHERE unit IN ('$', '¥', '元', 'USD', 'CNY');
        SQL

        # 百分比指标
        execute <<-SQL
          UPDATE ads_metrics
          SET display_config = '{"align": "right", "format": "percent", "decimals": 2}'
          WHERE unit = '%';
        SQL

        # 数量类指标
        execute <<-SQL
          UPDATE ads_metrics
          SET display_config = '{"align": "right", "format": "number", "decimals": 0}'
          WHERE unit IN ('次', '个', '人') OR unit IS NULL;
        SQL
      end
    end
  end
end
