class AddAdjustGameTokenToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :adjust_game_token, :string
  end
end
