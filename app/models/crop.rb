class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :scientific_names
  accepts_nested_attributes_for :scientific_names,
    :allow_destroy => true,
    :reject_if     => :all_blank

  has_many :alternate_names
  has_many :plantings
  has_many :photos, :through => :plantings
  has_many :seeds
  has_many :harvests
  has_many :plant_parts, -> { uniq }, :through => :harvests
  belongs_to :creator, :class_name => 'Member'

  belongs_to :parent, :class_name => 'Crop'
  has_many :varieties, :class_name => 'Crop', :foreign_key => 'parent_id'
  has_and_belongs_to_many :posts
  before_destroy {|crop| crop.posts.clear}

  default_scope { order("lower(name) asc") }
  scope :recent, -> { reorder("created_at desc") }
  scope :toplevel, -> { where(:parent_id => nil) }
  scope :popular, -> { reorder("plantings_count desc, lower(name) asc") }
  scope :randomized, -> { reorder('random()') } # ok on sqlite and psql, but not on mysql

  validates :en_wikipedia_url,
    :format => {
      :with => /\Ahttps?:\/\/en\.wikipedia\.org\/wiki/,
      :message => 'is not a valid English Wikipedia URL'
    }
  
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  index_name [Rails.env, "growstuff"].join('_')
  settings index: { number_of_shards: 1},
    analysis: {
      tokenizer: {
        gs_edgeNGram_tokenizer: {
          type: "edgeNGram",
          min_gram: 2,
          max_gram: 20,
          token_chars: [ "letter", "digit" ]
        }
      },
      analyzer: {
        gs_edgeNGram_analyzer: {
          tokenizer: "gs_edgeNGram_tokenizer",
          filter: ["lowercase"]
        }
      },
    } do
    mappings dynamic: 'false' do
      indexes :id, type: 'long'
      indexes :name, type: 'string', analyzer: 'gs_edgeNGram_analyzer'
      indexes :scientific_names do
        indexes :scientific_name, type: 'string', analyzer: 'gs_edgeNGram_analyzer', norms: { enabled: false }
      end
      indexes :alternate_names do
        indexes :name, type: 'string', analyzer: 'gs_edgeNGram_analyzer'
      end
    end
  end

  def as_indexed_json(options={})
    self.as_json(
      only: [:id, :name],
      include: {
        scientific_names: { only: :scientific_name },
        alternate_names: { only: :name }
             })
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
# - en_wikipedia_url (required)
# - parent (name, optional)
# - scientific name (optional, can be picked up from parent if it has one)

  def Crop.create_from_csv(row)
    name,en_wikipedia_url,parent,scientific_names,alternate_names = row

    cropbot = Member.find_by_login_name('cropbot')
    raise "cropbot account not found: run rake db:seed" unless cropbot

    crop = Crop.find_or_create_by(name: name)
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

    crop.add_scientific_names_from_csv(scientific_names)
    crop.add_alternate_names_from_csv(alternate_names)

  end

  def add_scientific_names_from_csv(scientific_names)
    names_to_add = []
    if ! scientific_names.blank? # i.e. we actually passed something in, which isn't a given
      names_to_add = scientific_names.split(%r{,\s*})
    elsif parent && parent.scientific_names.size > 0 # pick up from parent
      names_to_add = parent.scientific_names.map{|s| s.scientific_name}
    else
      logger.warn("Warning: no scientific name (not even on parent crop) for #{self}")
    end

    if names_to_add.size > 0
      cropbot = Member.find_by_login_name('cropbot')
      raise "cropbot account not found: run rake db:seed" unless cropbot

      names_to_add.each do |n|
        if self.scientific_names.exists?(:scientific_name => n)
          logger.warn("Warning: skipping duplicate scientific name #{n} for #{self}")
        else

          self.scientific_names.create(
            :scientific_name => n,
            :creator_id => cropbot.id
          )
        end
      end
    end
  end

  def add_alternate_names_from_csv(alternate_names)
    names_to_add = []
    if ! alternate_names.blank? # i.e. we actually passed something in, which isn't a given
      cropbot = Member.find_by_login_name('cropbot')
      raise "cropbot account not found: run rake db:seed" unless cropbot

      names_to_add = alternate_names.split(%r{,\s*})

      names_to_add.each do |n|
        if self.alternate_names.exists?(:name => n)
          logger.warn("Warning: skipping duplicate alternate name #{n} for #{self}")
        else
          self.alternate_names.create(
            :name => n,
            :creator_id => cropbot.id
          )
        end
      end

    end
  end

  # Crop.search(string)
  # searches for crops whose names match the string given
  # just uses SQL LIKE for now, but can be made fancier later
  def self.search(query)
    search_str = query.nil? ? "" : query.downcase
    response = __elasticsearch__.search( {
        query: {
          multi_match: {
            query: "#{search_str}",
            fields: ["name", "scientific_names.scientific_name", "alternate_names.name"]
          }
        },
        size: 50
      }
    )
    return response.records.to_a
  end

  def self.autosuggest(term)
    where("name ILIKE ?", "%#{term}%")
  end
end
