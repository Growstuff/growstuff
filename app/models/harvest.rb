# frozen_string_literal: true

class Harvest < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  extend FriendlyId
  include PhotoCapable
  include Ownable
  include SearchHarvests

  friendly_id :harvest_slug, use: %i(slugged finders)

  # Constants
  UNITS_VALUES = {
    "individual" => "individual",
    "bunches"    => "bunch",
    "sprigs"     => "sprig",
    "handfuls"   => "handful",
    "litres"     => "litre",
    "pints"      => "pint",
    "quarts"     => "quart",
    "buckets"    => "bucket",
    "baskets"    => "basket",
    "bushels"    => "bushel"
  }.freeze

  WEIGHT_UNITS_VALUES = {
    "kg" => "kg",
    "lb" => "lb",
    "oz" => "oz"
  }.freeze

  ##
  ## Triggers
  after_validation :cleanup_quantities
  before_save :set_si_weight

  ##
  ## Relationships
  belongs_to :crop, counter_cache: true
  belongs_to :plant_part, counter_cache: true
  belongs_to :planting, optional: true, counter_cache: true

  ##
  ## Scopes
  scope :interesting, -> { has_photos.one_per_owner }
  scope :recent, -> { order(created_at: :desc) }
  scope :one_per_owner, lambda {
    joins("JOIN members m ON (m.id=harvests.owner_id)
            LEFT OUTER JOIN harvests h2
            ON (m.id=h2.owner_id AND harvests.id < h2.id)").where("h2 IS NULL")
  }

  delegate :name, :slug, to: :crop, prefix: true
  delegate :login_name, :slug, to: :owner, prefix: true
  delegate :name, to: :plant_part, prefix: true

  ##
  ## Validations
  validates :crop, approved: true
  validates :crop, presence: { message: "must be present and exist in our database" }
  validates :plant_part, presence: { message: "must be present and exist in our database" }
  validates :harvested_at, presence: true
  validates :quantity, allow_nil: true, numericality: {
    only_integer: false, greater_than_or_equal_to: 0
  }
  validates :unit, allow_blank: true, inclusion: {
    in: UNITS_VALUES.values, message: "%<value>s is not a valid unit"
  }
  validates :weight_quantity, allow_nil: true, numericality: { only_integer: false }
  validates :weight_unit, allow_blank: true, inclusion: {
    in: WEIGHT_UNITS_VALUES.values, message: "%<value>s is not a valid unit"
  }
  validate :crop_must_match_planting
  validate :owner_must_match_planting
  validate :harvest_must_be_after_planting

  def time_from_planting_to_harvest
    return if planting.blank?

    harvested_at - planting.planted_at
  end

  def default_photo
    most_liked_photo || planting&.default_photo
  end

  # we're storing the harvest weight in kilograms in the db too
  # to make data manipulation easier
  def set_si_weight
    return if weight_unit.nil?

    weight_string = "#{weight_quantity} #{weight_unit}"
    self.si_weight = Unit.new(weight_string).convert_to("kg").to_s("%0.3f").delete(" kg").to_f
  end

  def cleanup_quantities
    self.quantity = nil if quantity&.zero?
    self.unit = nil if quantity.blank?
    self.weight_quantity = nil if weight_quantity&.zero?
    self.weight_unit = nil if weight_quantity.blank?
  end

  def harvest_slug
    "#{owner.login_name}-#{crop}".downcase.tr(' ', '-')
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    # 50 individual apples, weighing 3lb
    # 2 buckets of apricots, weighing 10kg
    "#{quantity_to_human} #{unit_to_human} #{crop_name_to_human} #{weight_to_human}".strip
  end

  def quantity_to_human
    return number_to_human(quantity.to_s, strip_insignificant_zeros: true) if quantity

    ""
  end

  def unit_to_human
    return "" unless quantity && unit
    return 'individual' if unit == 'individual'
    return "#{unit} of" if quantity == 1

    "#{unit.pluralize} of"
  end

  def weight_to_human
    return "" unless weight_quantity

    "weighing #{number_to_human(weight_quantity, strip_insignificant_zeros: true)} #{weight_unit}"
  end

  def crop_name_to_human
    if unit != 'individual' # buckets of apricot*s*
      crop.name.pluralize
    elsif quantity == 1
      crop.name
    else
      crop.name.pluralize
    end.to_s
  end

  private

  def crop_must_match_planting
    return if planting.blank? # only check if we are linked to a planting

    errors.add(:planting, "must be the same crop") unless crop == planting.crop
  end

  def owner_must_match_planting
    return if planting.blank? # only check if we are linked to a planting

    errors.add(:owner, "of harvest must be the same as planting") unless owner == planting.owner
  end

  def harvest_must_be_after_planting
    # only check if we are linked to a planting
    return unless harvested_at.present? && planting.present? && planting.planted_at.present?

    errors.add(:planting, "cannot be harvested before planting") unless harvested_at > planting.planted_at
  end
end
