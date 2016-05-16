class Harvest < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  extend FriendlyId
  friendly_id :harvest_slug, use: [:slugged, :finders]

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member'
  belongs_to :plant_part

  has_and_belongs_to_many :photos

  before_destroy do |harvest|
    photolist = harvest.photos.to_a # save a temp copy of the photo list
    harvest.photos.clear # clear relationship b/w harvest and photo

    photolist.each do |photo|
      photo.destroy_if_unused
    end
  end

  default_scope { order('created_at DESC') }

  validates :crop, :approved => true

  validates :crop, :presence => {:message => "must be present and exist in our database"}

  validates :plant_part, :presence => {:message => "must be present and exist in our database"}

  validates :quantity,
    :numericality => {
      :only_integer => false,
      :greater_than_or_equal_to => 0 },
    :allow_nil => true

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
  validates :unit, :inclusion => { :in => UNITS_VALUES.values,
    :message => "%{value} is not a valid unit" },
    :allow_nil => true,
    :allow_blank => true

  validates :weight_quantity,
    :numericality => { :only_integer => false },
    :allow_nil => true

  WEIGHT_UNITS_VALUES = {
    "kg" => "kg",
    "lb" => "lb",
    "oz" => "oz"
  }
  validates :weight_unit, :inclusion => { :in => WEIGHT_UNITS_VALUES.values,
    :message => "%{value} is not a valid unit" },
    :allow_nil => true,
    :allow_blank => true

  after_validation :cleanup_quantities

  before_save :set_si_weight

  # we're storing the harvest weight in kilograms in the db too 
  # to make data manipulation easier
  def set_si_weight
    if self.weight_unit != nil
      weight_string = "#{self.weight_quantity} #{self.weight_unit}"
      self.si_weight = Unit(weight_string).convert_to("kg").to_s("%0.3f").delete(" kg").to_f
    end
  end

  def cleanup_quantities
    if quantity == 0
      self.quantity = nil
    end

    if quantity.blank?
      self.unit = nil
    end

    if weight_quantity == 0
      self.weight_quantity = nil
    end

    if weight_quantity.blank?
      self.weight_unit = nil
    end
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
      string += "#{number_to_human(self.quantity.to_s, :strip_insignificant_zeros => true)} "
      if self.unit == 'individual'
        string += 'individual '
      else
        if self.quantity == 1
          string += "#{self.unit} of "
        else
          string += "#{self.unit.pluralize} of "
        end
      end
    end

    if self.unit != 'individual' # buckets of apricot*s*
      string += "#{self.crop.name.pluralize}"
    elsif self.quantity == 1
      string += "#{self.crop.name}"
    else
      string += "#{self.crop.name.pluralize}"
    end

    if self.weight_quantity
      string += " weighing #{number_to_human(self.weight_quantity, :strip_insignificant_zeros => true)} #{self.weight_unit}"
    end

    return string
  end

  def default_photo
    return photos.first
  end

end
