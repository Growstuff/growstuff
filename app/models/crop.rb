class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :system_name, use: :slugged
  attr_accessible :en_wikipedia_url, :system_name, :parent_id

  has_many :scientific_names
  has_many :plantings
  has_many :photos, :through => :plantings
  has_many :seeds

  belongs_to :parent, :class_name => 'Crop'
  has_many :varieties, :class_name => 'Crop', :foreign_key => 'parent_id'

  default_scope order("lower(system_name) asc")
  scope :recent, reorder("created_at desc")

  validates :en_wikipedia_url,
    :format => {
      :with => /^https?:\/\/en\.wikipedia\.org\/wiki/,
      :message => 'is not a valid English Wikipedia URL'
    }

  def Crop.random
    @crop = Crop.offset(rand(Crop.count)).first
    return @crop
  end

  def to_s
    return system_name
  end

  def default_scientific_name
    if scientific_names.count > 0
      return scientific_names.first.scientific_name
    else
      return nil
    end
  end

  def plantings_count
    return plantings.count
  end

  # crop.default_photo
  # currently returns the first available photo, but exists so that
  # later we can choose a default photo based on different criteria,
  # eg. popularity
  def default_photo
    return photos.first
  end

  # crop.sunniness
  # returns hash indicating whether this crop is grown in
  # sun/semi-shade/shade
  # key: sunniness (eg. 'sun')
  # value: count of how many times it's been used by plantings
  def sunniness
    sunniness = Hash.new(0)
    plantings.each do |p|
      if !p.sunniness.blank?
        sunniness[p.sunniness] += 1
      end
    end
    return sunniness
  end

  # crop.planted_from
  # returns a hash of propagation methods (seed, seedling, etc),
  # key: propagation method (eg. 'seed')
  # value: count of how many times it's been used by plantings
  def planted_from
    planted_from = Hash.new(0)
    plantings.each do |p|
      if !p.planted_from.blank?
        planted_from[p.planted_from] += 1
      end
    end
    return planted_from
  end

  # Crop.interesting
  # returns a list of interesting crops, for use on the homepage etc
  def Crop.interesting
    return Rails.cache.fetch("interesting_crops", :expires_in => 1.day) do
      howmany = 12 # max number to find
      interesting_crops = Array.new
      min_plantings = 3 # needs this many plantings to be interesting
      min_photos    = 3 # needs this many photos to be interesting

      # it's inefficient to shuffle this up-front, but if we cache
      # the crops on the homepage it won't be run too often, and there's
      # not *that* many crops.
      Crop.all.shuffle.each do |c|
        break if interesting_crops.length == howmany
        next unless c.photos.count >= min_photos
        next unless c.plantings_count >= min_plantings
        interesting_crops.push(c)
      end

      interesting_crops
    end
  end

end
