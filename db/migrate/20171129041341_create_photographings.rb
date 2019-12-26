# frozen_string_literal: true

class CreatePhotographings < ActiveRecord::Migration[4.2]
  def change
    create_table :photographings do |t|
      t.integer :photo_id, null: false
      t.integer :photographable_id, null: false
      t.string :photographable_type, null: false
      t.timestamps null: false
    end

    add_foreign_key :photographings, :photos

    add_index :photographings, %i(photographable_id photographable_type photo_id),
              unique: true, name: 'items_to_photos_idx'
    add_index :photographings, %i(photographable_id photographable_type),
              name: 'photographable_idx'

    migrate_data
  end

  def migrate_data
    say "migrating garden photos"
    GardensPhoto.all.each do |g|
      Photographing.create! photo_id: g.photo_id, photographable_id: g.garden_id, photographable_type: 'Garden'
    end
    say "migrating planting photos"
    PhotosPlanting.all.each do |p|
      Photographing.create! photo_id: p.photo_id, photographable_id: p.planting_id, photographable_type: 'Planting'
    end
    say "migrating harvest photos"
    HarvestsPhoto.all.each do |h|
      Photographing.create! photo_id: h.photo_id, photographable_id: h.harvest_id, photographable_type: 'Harvest'
    end
    say "migrating seed photos"
    PhotosSeed.all.each do |s|
      Photographing.create! photo_id: s.photo_id, photographable_id: s.seed_id, photographable_type: 'Seed'
    end
  end
  class GardensPhoto < ApplicationRecord
    belongs_to :photo
    belongs_to :garden
  end
  class PhotosPlanting < ApplicationRecord
    belongs_to :photo
    belongs_to :planting
  end
  class HarvestsPhoto < ApplicationRecord
    belongs_to :photo
    belongs_to :harvest
  end
  class PhotosSeed < ApplicationRecord
    belongs_to :photo
    belongs_to :seed
  end
end
