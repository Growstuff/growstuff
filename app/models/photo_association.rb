class PhotoAssociation < ApplicationRecord
  belongs_to :photo, inverse_of: :photo_associations
  belongs_to :photographable, polymorphic: true
  belongs_to :crop, optional: true

  validate :photo_and_item_have_same_owner

  ##
  ## Triggers
  before_save :set_crop

  def item
    find_by!(photographable_id: photographable_id, photographable_type: photographable_type).photographable
  end

  def self.item(item_id, item_type)
    find_by!(photographable_id: item_id, photographable_type: item_type).photographable
  end

  def set_crop
    self.crop_id = photographable.crop_id if %w(Planting Seed Harvest).include?(photographable_type)
  end

  private

  def photo_and_item_have_same_owner
    errors.add(:photo, "must have same owner as item it links to") unless photographable.owner_id == photo.owner_id
  end
end
