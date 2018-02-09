class AddDatetakenToPhotos < ActiveRecord::Migration
  def up
    add_column :photos, :date_taken, :datetime
    update_flickr_metadata
  end

  def down
    add_column :photos, :date_taken
  end

  private

  def update_flickr_metadata
    # Fetch from flickr, the photos updated the longest ago will be fetched first
    Photo.all.order(:updated_at).each do |photo|
      say "Fetch flickr data for #{photo}"
      photo.set_flickr_metadata!
    end
  end
end
