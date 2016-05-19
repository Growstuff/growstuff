class Garden < ActiveRecord::Base
  include Geocodable
  extend FriendlyId
  friendly_id :garden_slug, use: [:slugged, :finders]

  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'
  has_many :plantings, -> { order(created_at: :desc) }, :dependent => :destroy
  has_many :crops, :through => :plantings

  has_and_belongs_to_many :photos

   before_destroy do |garden|
     photolist = garden.photos.to_a # save a temp copy of the photo list
     garden.photos.clear # clear relationship b/w garden and photo

     photolist.each do |photo|
       photo.destroy_if_unused
     end
   end

  # set up geocoding
  geocoded_by :location
  after_validation :geocode
  after_validation :empty_unwanted_geocodes
  after_save :mark_inactive_garden_plantings_as_finished

  default_scope { order("lower(name) asc") }
  scope :active, -> { where(:active => true) }
  scope :inactive, -> { where(:active => false) }

  validates :location,
    :length => { :maximum => 255 }

  validates :name,
    :format => {
      :with => /\S/
    },
    :length => { :maximum => 255 }

  validates :area,
    :numericality => {
      :only_integer => false,
      :greater_than_or_equal_to => 0 },
    :allow_nil => true

  AREA_UNITS_VALUES = {
    "square metres" => "square metre",
    "square feet" => "square foot",
    "hectares" => "hectare",
    "acres" => "acre"
  }
  validates :area_unit, :inclusion => { :in => AREA_UNITS_VALUES.values,
        :message => "%{value} is not a valid area unit" },
        :allow_nil => true,
        :allow_blank => true

  after_validation :cleanup_area

  def cleanup_area
    if area == 0
      self.area = nil
    end
    if area.blank?
      self.area_unit = nil
    end
  end

  def garden_slug
    "#{owner.login_name}-#{name}".downcase.gsub(' ', '-')
  end

  # featured plantings returns the most recent 4 plantings for a garden,
  # choosing them so that no crop is repeated.
  def featured_plantings
    unique_plantings = []
    seen_crops = []

    plantings.each do |p|
      if (! seen_crops.include?(p.crop))
        unique_plantings.push(p)
        seen_crops.push(p.crop)
      end
    end

    return unique_plantings[0..3]
  end

  def to_s
    name
  end

  # When you mark a garden as inactive, all the plantings in it should be
  # marked as finished.  This automates that.
  def mark_inactive_garden_plantings_as_finished
    if (active == false)
      plantings.current.each do |p|
        p.finished = true
        p.save
      end
    end
  end

  def default_photo
    return photos.first
  end

end
