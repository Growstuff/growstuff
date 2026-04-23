class AddEnYoutubeUrlToCrops < ActiveRecord::Migration[7.2]
  def change
    add_column :crops, :en_youtube_url, :string
  end
end
