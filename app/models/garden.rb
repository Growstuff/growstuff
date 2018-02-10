class Garden < ActiveRecord::Base
  extend FriendlyId
  include Geocodable
  include PhotoCapable
  friendly_id :garden_slug, use: %i(slugged finders)

  belongs_to :owner, class_name: 'Member', foreign_key: 'owner_id', counter_cache: true
  has_many :plantings, dependent: :destroy
  has_many :crops, through: :plantings

  # set up geocoding
  geocoded_by :location
  after_validation :geocode
  after_validation :empty_unwanted_geocodes
  after_save :mark_inactive_garden_plantings_as_finished

  default_scope { joins(:owner) } # Ensures owner exists
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  validates :location,
    length: { maximum: 255 }

  validates :name,
    format: {
      with: /\A\w+[\w ()]+\z/
    },
    length: { maximum: 255 }

  validates :area,
    numericality: {
      only_integer: false,
      greater_than_or_equal_to: 0
    },
    allow_nil: true

  AREA_UNITS_VALUES = {
    "square metres" => "square metre",
    "square feet" => "square foot",
    "hectares" => "hectare",
    "acres" => "acre"
  }.freeze
  validates :area_unit, inclusion: { in: AREA_UNITS_VALUES.values,
                                     message: "%<value>s is not a valid area unit" },
                        allow_nil: true,
                        allow_blank: true

  after_validation :cleanup_area

  def cleanup_area
    self.area = nil if area && area.zero?
    self.area_unit = nil if area.blank?
  end

  def garden_slug
    "#{owner.login_name}-#{name}".downcase.tr(' ', '-')
  end

  # featured plantings returns the most recent 4 plantings for a garden,
  # choosing them so that no crop is repeated.
  def featured_plantings
    unique_plantings = []
    seen_crops = []

    plantings.order(created_at: :desc).includes(:garden, :crop, :owner, :harvests).each do |p|
      unless seen_crops.include?(p.crop)
        unique_plantings.push(p)
        seen_crops.push(p.crop)
      end
    end

    unique_plantings[0..3]
  end

  def to_s
    name
  end

  # When you mark a garden as inactive, all the plantings in it should be
  # marked as finished.  This automates that.
  def mark_inactive_garden_plantings_as_finished
    return unless active == false

    plantings.current.each do |p|
      p.finished = true
      p.save
    end
  end

  def default_photo
    photos.order(created_at: :desc).first
  end
end
