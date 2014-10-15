class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  attr_accessible :en_wikipedia_url, :name, :parent_id, :creator_id, :scientific_names_attributes

  has_many :scientific_names
  accepts_nested_attributes_for :scientific_names,
    :allow_destroy => true,
    :reject_if     => :all_blank

  has_many :plantings
  has_many :photos, :through => :plantings
  has_many :seeds
  has_many :harvests
  has_many :plant_parts, :through => :harvests, :uniq => :true
  belongs_to :creator, :class_name => 'Member'

  belongs_to :parent, :class_name => 'Crop'
  has_many :varieties, :class_name => 'Crop', :foreign_key => 'parent_id'

  default_scope order("lower(name) asc")
  scope :recent, reorder("created_at desc")
  scope :toplevel, where(:parent_id => nil)
  scope :popular, reorder("plantings_count desc, lower(name) asc")
  scope :randomized, reorder('random()') # ok on sqlite and psql, but not on mysql

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
    return name
  end

  def default_scientific_name
    if scientific_names.count > 0
      return scientific_names.first.scientific_name
    else
      return nil
    end
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

  # crop.popular_plant_parts
  # returns a hash of most harvested plant parts (fruit, seed, etc)
  # key: plant part (eg. 'fruit')
  # value: count of how many times it's been used by harvests
  def popular_plant_parts
    popular_plant_parts = Hash.new(0)
    harvests.each do |h|
      if h.plant_part
        popular_plant_parts[h.plant_part] += 1
      end
    end
    return popular_plant_parts
  end

  def interesting?
    min_plantings = 3 # needs this many plantings to be interesting
    min_photos    = 3 # needs this many photos to be interesting
    return false unless photos.count >= min_photos
    return false unless plantings_count >= min_plantings
    return true
  end

  # Crop.interesting
  # returns a list of interesting crops, for use on the homepage etc
  def Crop.interesting
  howmany = 12 # max number to find
  interesting_crops = Array.new
    Crop.randomized.each do |c|
      break if interesting_crops.length == howmany
      next unless c.interesting?
      interesting_crops.push(c)
    end
    return interesting_crops
  end

# Crop.create_from_csv(row)
# used by db/seeds.rb and rake growstuff:import_crops
# CSV fields:
# - name (required)
# - scientific name (optional, can be picked up from parent if it has one)
# - en_wikipedia_url (required)
# - parent (name, optional)

  def Crop.create_from_csv(row)
    name,scientific_name,en_wikipedia_url,parent = row

    cropbot = Member.find_by_login_name('cropbot')
    raise "cropbot account not found: run rake db:seed" unless cropbot

    crop = Crop.find_or_create_by_name(name)
    crop.update_attributes(
      :en_wikipedia_url => en_wikipedia_url,
      :creator_id => cropbot.id
    )

    if parent
      parent = Crop.find_by_name(parent)
      if parent
        crop.update_attributes(:parent_id => parent.id)
      else
        logger.warn("Warning: parent crop #{parent} not found")
      end
    end

    crop.add_scientific_name_from_csv(scientific_name)

  end

  def add_scientific_name_from_csv(scientific_name)
    name_to_add = nil
    if ! scientific_name.blank? # i.e. we actually passed one in, which isn't a given
      name_to_add = scientific_name
    elsif parent && parent.default_scientific_name
      name_to_add = parent.default_scientific_name
    else
      logger.warn("Warning: no scientific name (not even on parent crop) for #{self}")
    end

    if name_to_add
      if scientific_names.exists?(:scientific_name => name_to_add)
        logger.warn("Warning: skipping duplicate scientific name #{name_to_add} for #{self}")
      else
        cropbot = Member.find_by_login_name('cropbot')
        raise "cropbot account not found: run rake db:seed" unless cropbot

        scientific_names.create(
          :scientific_name => name_to_add,
          :creator_id => cropbot.id
        )
      end
    end

  end

  # Crop.search(string)
  # searches for crops whose names match the string given
  # just uses SQL LIKE for now, but can be made fancier later
  def self.search(query)
    where("name ILIKE ?", "%#{query}%")
  end

end
