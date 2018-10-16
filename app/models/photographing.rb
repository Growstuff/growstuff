class Photographing < ApplicationRecord
  belongs_to :photo, inverse_of: :photographings
  belongs_to :photographable, polymorphic: true

  validate :photo_and_item_have_same_owner

  def self.item(item_id, item_type)
    find_by!(photographable_id: item_id, photographable_type: item_type).photographable
  end

  def item
    find_by!(photographable_id: photographable_id, photographable_type: photographable_type).photographable
  end

  private

  def photo_and_item_have_same_owner
    errors.add(:photo, "must have same owner as item it links to") unless photographable.owner_id == photo.owner_id
  end
end
