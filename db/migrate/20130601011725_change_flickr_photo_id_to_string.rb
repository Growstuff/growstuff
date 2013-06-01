class ChangeFlickrPhotoIdToString < ActiveRecord::Migration
  def up
    change_column :photos, :flickr_photo_id, :string
  end
  def down
    change_column :photos, :flickr_photo_id, :integer
  end
end
