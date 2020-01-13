# frozen_string_literal: true

class PhotoAssociation < ApplicationRecord
  belongs_to :photo, touch: true, inverse_of: :photo_associations
  belongs_to :crop, optional: true, touch: true # , counter_cache: true
  belongs_to :photographable, polymorphic: true, touch: true

  validate :photo_and_item_have_same_owner
  validate :crop_present

  ##
  ## Triggers
  before_validation :set_crop

  def self.item(item_id, item_type)
    find_by!(photographable_id: item_id, photographable_type: item_type).photographable
  end

  private

  def set_crop
    if %w(Planting Seed Harvest).include?(photographable_type)
      self.crop_id = photographable.crop_id
    elsif photographable_type == 'Crop'
      self.crop_id = photographable_id
    end
  end

  def photo_and_item_have_same_owner
    return if photographable_type == 'Crop'

    errors.add(:photo, "must have same owner as item it links to") unless photographable.owner_id == photo.owner_id
  end

  def crop_present
    if %w(Planting Seed Harvest).include?(photographable_type)
      errors.add(:crop_id, "failed to calculate crop") if crop_id.blank?
    end
  end
end
