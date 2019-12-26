# frozen_string_literal: true

class CropPosts < ActiveRecord::Migration[5.2]
  def change
    rename_table :crops_posts, :crop_posts
  end
end
