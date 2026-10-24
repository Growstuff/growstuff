# frozen_string_literal: true

# A crop's suggested jobs, offered to gardeners who plant it. It belongs to the
# crop it is written for and applies to that crop's varieties too. Only
# published templates are offered.
class CropJobTemplate < ApplicationRecord
  belongs_to :crop
  has_many :steps, -> { order(:position, :id) }, class_name: 'CropJobStep', dependent: :destroy, inverse_of: :crop_job_template

  # Which months a season is depends on the gardener's hemisphere, so it is
  # worked out where the template is offered.
  enum :season, { any: 'any', spring_summer: 'spring_summer', autumn_winter: 'autumn_winter' }, prefix: true, validate: true
  enum :status, { draft: 'draft', published: 'published' }, validate: true

  validates :name, presence: true

  # Those written for the crop itself or, if it is a variety, for the crop it
  # is a variety of.
  scope :for_crop, ->(crop) { where(crop_id: [crop.id, crop.parent_id].compact) }

  accepts_nested_attributes_for :steps, allow_destroy: true, reject_if: :all_blank

  def to_s
    name
  end
end
