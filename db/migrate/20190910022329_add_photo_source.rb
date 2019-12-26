# frozen_string_literal: true

class AddPhotoSource < ActiveRecord::Migration[5.2]
  def change
    add_column :photos, :source, :string
    rename_column :photos, :flickr_photo_id, :source_id
    Photo.update_all(source: 'flickr') # rubocop:disable Rails/SkipsModelValidations
  end
end
