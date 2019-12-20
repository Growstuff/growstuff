# frozen_string_literal: true

class AddMetadataToPhotos < ActiveRecord::Migration[4.2]
  def up
    change_table :photos do |t|
      t.string :title
      t.string :license_name
      t.string :license_url
      t.string :link_url
      t.change :title, :string, null: false
      t.change :license_name, :string, null: false
      t.change :link_url, :string, null: false
    end
  end

  def down
    change_table :photos do |t|
      t.remove :title
      t.remove :license_name
      t.remove :license_url
      t.remove :link_url
    end
  end
end
