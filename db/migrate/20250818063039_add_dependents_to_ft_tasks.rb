class AddDependentsToFtTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :ft_tasks, :dependents, :json, comment: '依赖的任务ID列表，存储为JSON数组'

    # 为现有记录设置默认值
    reversible do |dir|
      dir.up do
        execute "UPDATE ft_tasks SET dependents = '[]' WHERE dependents IS NULL"
      end
    end
  end
end
