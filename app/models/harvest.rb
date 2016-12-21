class Harvest < ActiveRecord::Base
  extend FriendlyId
  include ActionView::Helpers::NumberHelper
  include PhotoCapable
  friendly_id :harvest_slug, use: [:slugged, :finders]

  belongs_to :crop
  belongs_to :owner, class_name: 'Member'
  belongs_to :plant_part

  default_scope { order('created_at DESC') }

  validates :crop, approved: true

  validates :crop, presence: { message: "must be present and exist in our database" }

  validates :plant_part, presence: { message: "must be present and exist in our database" }

  validates :quantity,
    numericality: {
      only_integer: false,
      greater_than_or_equal_to: 0 },
    allow_nil: true

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
  }
  validates :unit, inclusion: { in: UNITS_VALUES.values,
                                message: "%{value} is not a valid unit" },
                   allow_nil: true,
                   allow_blank: true

  validates :weight_quantity,
    numericality: { only_integer: false },
    allow_nil: true

  WEIGHT_UNITS_VALUES = {
    "kg" => "kg",
    "lb" => "lb",
    "oz" => "oz"
  }
  validates :weight_unit, inclusion: { in: WEIGHT_UNITS_VALUES.values,
                                       message: "%{value} is not a valid unit" },
                          allow_nil: true,
                          allow_blank: true

  after_validation :cleanup_quantities

  before_save :set_si_weight

  # we're storing the harvest weight in kilograms in the db too
  # to make data manipulation easier
  def set_si_weight
    return if self.weight_unit.nil?
    weight_string = "#{self.weight_quantity} #{self.weight_unit}"
    self.si_weight = Unit.new(weight_string).convert_to("kg").to_s("%0.3f").delete(" kg").to_f
  end

  def cleanup_quantities
    self.quantity = nil if quantity == 0
    self.unit = nil if quantity.blank?
    self.weight_quantity = nil if weight_quantity == 0
    self.weight_unit = nil if weight_quantity.blank?
  end

  def harvest_slug
    "#{owner.login_name}-#{crop}".downcase.gsub(' ', '-')
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    # 50 individual apples, weighing 3lb
    # 2 buckets of apricots, weighing 10kg
    string = ''
    if self.quantity
      string += "#{number_to_human(self.quantity.to_s, strip_insignificant_zeros: true)} "
      string += if self.unit == 'individual'
                  'individual '
                elsif self.quantity == 1
                  "#{self.unit} of "
                else
                  "#{self.unit.pluralize} of "
                end
    end

    string += if self.unit != 'individual' # buckets of apricot*s*
                "#{self.crop.name.pluralize}"
              elsif self.quantity == 1
                "#{self.crop.name}"
              else
                "#{self.crop.name.pluralize}"
              end

    if self.weight_quantity
      string += " weighing #{number_to_human(self.weight_quantity, strip_insignificant_zeros: true)}"\
        " #{self.weight_unit}"
    end

    string
  end

  def default_photo
    photos.first || crop.default_photo
  end
end
