# frozen_string_literal: true

# The text read from a label photo (a seed packet's front or back) belongs to that photo. It used to be on the seed,
# with the sides joined as "[front]" and "[back]".
class AddOcrToPhotos < ActiveRecord::Migration[8.1]
  SIDES = /\[(front|back)\]\n(.*?)(?=\n\n\[(?:front|back)\]\n|\z)/m

  class MigrationSeed < ActiveRecord::Base
    self.table_name = 'seeds'
  end

  class MigrationPhoto < ActiveRecord::Base
    self.table_name = 'photos'
  end

  class MigrationAssociation < ActiveRecord::Base
    self.table_name = 'photo_associations'
  end

  def change
    change_table :photos, bulk: true do |t|
      t.text :ocr_text, comment: 'The text read from the photo of a label, such as the front or back of a seed packet.'
      t.string :ocr_engine, comment: 'The software that read ocr_text, with its version, so photos it read can be read again.'
      t.datetime :ocr_at, comment: 'When ocr_text was read.'
    end

    reversible do |direction|
      direction.up do
        MigrationPhoto.reset_column_information
        MigrationSeed.where.not(packet_text: [nil, '']).find_each { |seed| move_text(seed) }
      end
    end
  end

  private

  # Text with no sides marked is put on the front, or the back if there is no front.
  def move_text(seed)
    sides = seed.packet_text.scan(SIDES).to_h
    sides = { (side_photo(seed, 'front') ? 'front' : 'back') => seed.packet_text } if sides.empty?
    sides.each do |side, text|
      photo_id = side_photo(seed, side)
      MigrationPhoto.find(photo_id).update!(ocr_text: text.strip) if photo_id && text.present?
    end
  end

  # The newest photo of that side, as Seed#packet_photo finds it.
  def side_photo(seed, side)
    MigrationAssociation.where(photographable_type: 'Seed', photographable_id: seed.id, label: side).order(:id).last&.photo_id
  end
end
