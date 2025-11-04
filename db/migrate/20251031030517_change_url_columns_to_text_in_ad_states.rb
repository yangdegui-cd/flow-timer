class ChangeUrlColumnsToTextInAdStates < ActiveRecord::Migration[7.1]
  def change
    # 将 URL 字段从 varchar(255) 改为 text，以支持更长的 URL
    change_column :ad_states, :image_url, :text, comment: '图片素材URL'
    change_column :ad_states, :video_url, :text, comment: '视频URL'
    change_column :ad_states, :thumbnail_url, :text, comment: '视频缩略图URL'
    change_column :ad_states, :link_url, :text, comment: '落地页链接'
  end
end
