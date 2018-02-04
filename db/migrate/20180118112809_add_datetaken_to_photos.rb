class AddDatetakenToPhotos < ActiveRecord::Migration
  def change
    add_column :photos, :date_taken, :datetime
    # Fetch from flickr, the photos updated the longest ago will be fetched first
    Photo.all.order(:updated_at).each do |photo|
      say "Fetch flickr data for #{photo}"
      photo.set_flickr_metadata!
    end
  end
end
