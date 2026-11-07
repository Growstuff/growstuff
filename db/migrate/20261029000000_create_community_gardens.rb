# frozen_string_literal: true

class CreateCommunityGardens < ActiveRecord::Migration[8.1]
  def change
    create_table :community_gardens do |t|
      t.string :title, null: false
      t.string :website
      t.string :coordinates
      t.string :wikidata_id
      t.string :osm_id
      t.text :description
      t.string :email

      t.timestamps
    end

    add_index :community_gardens, :osm_id, unique: true
    add_index :community_gardens, :wikidata_id
  end
end
