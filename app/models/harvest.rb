class Harvest < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  extend FriendlyId
  include PhotoCapable

  friendly_id :harvest_slug, use: %i(slugged finders)

  # Constants
  UNITS_VALUES = {
    "individual" => "individual",
    "bunches" => "bunch",
    "sprigs" => "sprig",
    "handfuls" => "handful",
    "litres" => "litre",
    "pints" => "pint",
    "quarts" => "quart",
    "buckets" => "bucket",
    "baskets" => "basket",
    "bushels" => "bushel"
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
  belongs_to :crop
  belongs_to :owner, class_name: 'Member', counter_cache: true
  belongs_to :plant_part
  belongs_to :planting

  ##
  ## Scopes
  default_scope { joins(:owner) } # Ensures owner exists

  ##
  ## Validations
  validates :crop, approved: true
  validates :crop, presence: { message: "must be present and exist in our database" }
  validates :plant_part, presence: { message: "must be present and exist in our database" }
  validates :harvested_at, presence: true
  validates :quantity, allow_nil: true, numericality: {
    only_integer: false, greater_than_or_equal_to: 0
  }
  validates :unit, allow_nil: true, allow_blank: true, inclusion: {
    in: UNITS_VALUES.values, message: "%<value>s is not a valid unit"
  }
  validates :weight_quantity, allow_nil: true, numericality: { only_integer: false }
  validates :weight_unit, allow_nil: true, allow_blank: true, inclusion: {
    in: WEIGHT_UNITS_VALUES.values, message: "%<value>s is not a valid unit"
  }
  validate :crop_must_match_planting
  validate :owner_must_match_planting
  validate :harvest_must_be_after_planting

  def time_from_planting_to_harvest
    return if planting.blank?
    harvested_at - planting.planted_at
  end

  # we're storing the harvest weight in kilograms in the db too
  # to make data manipulation easier
  def set_si_weight
    return if weight_unit.nil?
    weight_string = "#{weight_quantity} #{weight_unit}"
    self.si_weight = Unit.new(weight_string).convert_to("kg").to_s("%0.3f").delete(" kg").to_f
  end

  def cleanup_quantities
    self.quantity = nil if quantity && quantity.zero?
    self.unit = nil if quantity.blank?
    self.weight_quantity = nil if weight_quantity && weight_quantity.zero?
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
    return "" unless quantity
    if unit == 'individual'
      'individual'
    elsif quantity == 1
      "#{unit} of"
    else
      "#{unit.pluralize} of"
    end
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

  def default_photo
    photos.order(created_at: :desc).first || crop.default_photo
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
