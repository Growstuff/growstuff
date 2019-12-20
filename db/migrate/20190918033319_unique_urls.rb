# frozen_string_literal: true

class UniqueUrls < ActiveRecord::Migration[5.2]
  def change
    add_index :photos, :fullsize_url, unique: true
    add_index :photos, :thumbnail_url, unique: true
  end
end
