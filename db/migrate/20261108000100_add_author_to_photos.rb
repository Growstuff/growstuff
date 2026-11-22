# frozen_string_literal: true

# Who took a photo that was added by someone other than its photographer, such as a
# crop wrangler adding a Creative Commons photo from Flickr. Photos members add of
# their own things have neither: the member is the photographer.
class AddAuthorToPhotos < ActiveRecord::Migration[8.1]
  def change
    change_table :photos, bulk: true do |t|
      t.string :author_name, comment: "The photographer, when not the member who added the photo."
      t.string :author_url, comment: "Where to find the photographer, such as their Flickr photostream."
    end
  end
end
