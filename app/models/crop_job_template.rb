# frozen_string_literal: true

# A crop's suggested jobs, offered to gardeners who plant it. It belongs to the
# crop it is written for and applies to that crop's varieties too. Only
# published templates are offered. Its creator is the member who wrote it;
# templates loaded from the seed files have none.
class CropJobTemplate < ApplicationRecord
  belongs_to :crop
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_crop_job_templates
  has_many :steps, -> { order(:position, :id) }, class_name: 'CropJobStep', dependent: :destroy, inverse_of: :crop_job_template

  # Which months a season is depends on the gardener's hemisphere, so it is
  # worked out where the template is offered.
  enum :season, { any: 'any', spring_summer: 'spring_summer', autumn_winter: 'autumn_winter' }, prefix: true, validate: true
  enum :status, { draft: 'draft', published: 'published' }, validate: true

  SEASONS = { 'spring_summer' => %i(spring summer), 'autumn_winter' => %i(autumn winter) }.freeze

  validates :name, presence: true

  # Those written for the crop itself or, if it is a variety, for the crop it
  # is a variety of.
  scope :for_crop, ->(crop) { where(crop_id: [crop.id, crop.parent_id].compact) }

  accepts_nested_attributes_for :steps, allow_destroy: true, reject_if: :all_blank

  # The months this template is for where a grower at this latitude is, or nil when
  # it is for any time or we don't know which hemisphere they are in, so there is
  # nothing to warn about.
  def season_months(latitude)
    seasons = SEASONS[season]
    return if seasons.blank? || latitude.blank?

    SeasonsHelper::SEASON_MONTHS[latitude.to_f.negative? ? :southern : :northern].slice(*seasons).values.flatten.sort
  end

  # Whether a day is in this template's season for a grower at this latitude.
  def in_season?(date, latitude)
    months = season_months(latitude)
    months.nil? || months.include?(date.month)
  end

  def to_s
    name
  end
end
