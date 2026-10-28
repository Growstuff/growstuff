# frozen_string_literal: true

class PhotoAssociation < ApplicationRecord
  belongs_to :photo, touch: true, inverse_of: :photo_associations
  belongs_to :crop, optional: true, touch: true # , counter_cache: true
  belongs_to :photographable, polymorphic: true, touch: true

  # What part of the item a photo is of, for the items that have parts: a job's
  # photo from before or after it was done, the front or back of a seed packet.
  # Most photos have no label.
  LABELS = {
    'Job'  => %w(before after),
    'Seed' => %w(front back)
  }.freeze

  normalizes :label, with: ->(label) { label.presence }
  validates :label, inclusion: { in: ->(association) { LABELS.fetch(association.photographable_type, []) } }, allow_nil: true

  validate :photo_and_item_have_same_owner
  validate :crop_present

  ##
  ## Triggers
  before_validation :set_crop
  before_save :take_label_from_other_photos, if: :seed_label?

  # Photos of a seed packet say what the packet says, not what the crop looks
  # like, so a photo labelled as one is left out of a crop's own photos.
  scope :of_packets, -> { where(photographable_type: 'Seed').where.not(label: nil) }
  # Those of a seed that has no text from its packet yet, which is what still
  # needs reading.
  scope :awaiting_text, -> { of_packets.where(photographable_id: Seed.unscoped.where(packet_text: [nil, '']).select(:id)) }

  def self.item(item_id, item_type)
    find_by!(photographable_id: item_id, photographable_type: item_type).photographable
  end

  private

  def seed_label?
    label? && photographable_type == 'Seed'
  end

  # A seed has one photo of each side of its packet: the newest one wins.
  def take_label_from_other_photos
    photographable.photo_associations.where(label:).where.not(id:).update_all(label: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def set_crop
    if %w(Planting Seed Harvest).include?(photographable_type)
      self.crop_id = photographable.crop_id
    elsif photographable_type == 'Crop'
      self.crop_id = photographable_id
    end
  end

  def photo_and_item_have_same_owner
    return if photographable_type == 'Crop'
    return if photographable.blank?

    errors.add(:photo, :photo_owner_mismatch) unless photographable.owner_id == photo.owner_id
  end

  def crop_present
    return unless %w(Planting Seed Harvest).include?(photographable_type)

    errors.add(:crop_id, :calculate_crop_failed) if crop_id.blank?
  end
end
