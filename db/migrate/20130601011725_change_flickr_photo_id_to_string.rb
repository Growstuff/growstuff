# frozen_string_literal: true

class ChangeFlickrPhotoIdToString < ActiveRecord::Migration[4.2]
  def up
    remove_column :photos, :flickr_photo_id
    add_column :photos, :flickr_photo_id, :string
  end

  def down
    # Postgres doesn't allow you to cast strings to integers
    # Hence there's no way of rolling back this migration without losing
    # information.
    remove_column :photos, :flickr_photo_id
    change_column :photos, :flickr_photo_id, :integer
  end
end
