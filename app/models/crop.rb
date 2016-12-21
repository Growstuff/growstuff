class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :scientific_names, after_add: :update_index, after_remove: :update_index
  accepts_nested_attributes_for :scientific_names,
    allow_destroy: true,
    reject_if: :all_blank

  has_many :alternate_names, after_add: :update_index, after_remove: :update_index, dependent: :destroy
  has_many :plantings
  has_many :photos, through: :plantings
  has_many :seeds
  has_many :harvests
  has_many :plant_parts, -> { uniq }, through: :harvests
  belongs_to :creator, class_name: 'Member'
  belongs_to :requester, class_name: 'Member'

  belongs_to :parent, class_name: 'Crop'
  has_many :varieties, class_name: 'Crop', foreign_key: 'parent_id'
  has_and_belongs_to_many :posts
  before_destroy { |crop| crop.posts.clear }

  default_scope { order("lower(name) asc") }
  scope :recent, lambda {
    where(approval_status: "approved").reorder("created_at desc")
  }
  scope :toplevel, lambda {
    where(approval_status: "approved", parent_id: nil)
  }
  scope :popular, lambda {
    where(approval_status: "approved").reorder("plantings_count desc, lower(name) asc")
  }
  scope :randomized, lambda {
    # ok on sqlite and psql, but not on mysql
    where(approval_status: "approved").reorder('random()')
  }
  scope :pending_approval, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }

  ## Wikipedia urls are only necessary when approving a crop
  validates :en_wikipedia_url,
    format: {
      with: /\Ahttps?:\/\/en\.wikipedia\.org\/wiki\/[[:alnum:]%_\.()-]+\z/,
      message: 'is not a valid English Wikipedia URL'
    },
    if: :approved?

  ## Reasons are only necessary when rejecting
  validates :reason_for_rejection, presence: true, if: :rejected?

  ## This validation addresses a race condition
  validate :approval_status_cannot_be_changed_again

  validate :must_be_rejected_if_rejected_reasons_present

  validate :must_have_meaningful_reason_for_rejection

  ####################################
  # Elastic search configuration
  if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    # In order to avoid clashing between different environments,
    # use Rails.env as a part of index name (eg. development_growstuff)
    index_name [Rails.env, "growstuff"].join('_')
    settings index: { number_of_shards: 1 },
             analysis: {
               tokenizer: {
                 gs_edgeNGram_tokenizer: {
                   type: "edgeNGram", # edgeNGram: NGram match from the start of a token
                   min_gram: 3,
                   max_gram: 10,
                   # token_chars: Elasticsearch will split on characters
                   # that don’t belong to any of these classes
                   token_chars: ["letter", "digit"]
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
        indexes :approval_status, type: 'string'
        indexes :scientific_names do
          indexes :name,
            type: 'string',
            analyzer: 'gs_edgeNGram_analyzer',
            # Disabling field-length norm (norm). If the norm option is turned on(by default),
            # higher weigh would be given for shorter fields, which in our case is irrelevant.
            norms: { enabled: false }
        end
        indexes :alternate_names do
          indexes :name, type: 'string', analyzer: 'gs_edgeNGram_analyzer'
        end
      end
    end
  end

  def as_indexed_json(options = {})
    self.as_json(
      only: [:id, :name, :approval_status],
      include: {
        scientific_names: { only: :name },
        alternate_names: { only: :name }
      })
  end

  # update the Elasticsearch index (only if we're using it in this
  # environment)
  def update_index(name_obj)
    __elasticsearch__.index_document if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"
  end

  # End Elasticsearch section

  def to_s
    name
  end

  def default_scientific_name
    scientific_names.first.name if scientific_names.size > 0
  end

  # crop.default_photo
  # currently returns the first available photo, but exists so that
  # later we can choose a default photo based on different criteria,
  # eg. popularity
  def default_photo
    return photos.first if photos.any?

    # Crop has no photos? Look for the most recent harvest with a photo.
    harvest_with_photo = Harvest.where(crop_id: id).joins(:photos).order('harvests.id DESC').limit(1).first
    harvest_with_photo.photos.first if harvest_with_photo
  end

  # crop.sunniness
  # returns hash indicating whether this crop is grown in
  # sun/semi-shade/shade
  # key: sunniness (eg. 'sun')
  # value: count of how many times it's been used by plantings
  def sunniness
    count_uses_of_property 'sunniness'
  end

  # crop.planted_from
  # returns a hash of propagation methods (seed, seedling, etc),
  # key: propagation method (eg. 'seed')
  # value: count of how many times it's been used by plantings
  def planted_from
    count_uses_of_property 'planted_from'
  end

  # crop.popular_plant_parts
  # returns a hash of most harvested plant parts (fruit, seed, etc)
  # key: plant part (eg. 'fruit')
  # value: count of how many times it's been used by harvests
  def popular_plant_parts
    popular_plant_parts = Hash.new(0)
    harvests.each do |h|
      popular_plant_parts[h.plant_part] += 1 if h.plant_part
    end
    popular_plant_parts
  end

  def interesting?
    min_plantings = 3 # needs this many plantings to be interesting
    min_photos    = 3 # needs this many photos to be interesting
    return false unless photos.size >= min_photos
    return false unless plantings_count >= min_plantings
    true
  end

  def pending?
    approval_status == "pending"
  end

  def approved?
    approval_status == "approved"
  end

  def rejected?
    approval_status == "rejected"
  end

  def approval_statuses
    ['rejected', 'pending', 'approved']
  end

  def reasons_for_rejection
    ["already in database", "not edible", "not enough information", "other"]
  end

  # Crop.interesting
  # returns a list of interesting crops, for use on the homepage etc
  def Crop.interesting
    howmany = 12 # max number to find
    interesting_crops = []
    Crop.includes(:photos).randomized.each do |c|
      break if interesting_crops.size == howmany
      next unless c.interesting?
      interesting_crops.push(c)
    end
    interesting_crops
  end

  # Crop.create_from_csv(row)
  # used by db/seeds.rb and rake growstuff:import_crops
  # CSV fields:
  # - name (required)
  # - en_wikipedia_url (required)
  # - parent (name, optional)
  # - scientific name (optional, can be picked up from parent if it has one)

  def Crop.create_from_csv(row)
    name, en_wikipedia_url, parent, scientific_names, alternate_names = row

    cropbot = Member.find_by(login_name: 'cropbot')
    raise "cropbot account not found: run rake db:seed" unless cropbot

    crop = Crop.find_or_create_by(name: name)
    crop.update_attributes(
      en_wikipedia_url: en_wikipedia_url,
      creator_id: cropbot.id
    )

    if parent
      parent = Crop.find_by(name: parent)
      if parent
        crop.update_attributes(parent_id: parent.id)
      else
        logger.warn("Warning: parent crop #{parent} not found")
      end
    end

    crop.add_scientific_names_from_csv(scientific_names)
    crop.add_alternate_names_from_csv(alternate_names)
  end

  def add_scientific_names_from_csv(scientific_names)
    names_to_add = []
    if !scientific_names.blank? # i.e. we actually passed something in, which isn't a given
      names_to_add = scientific_names.split(%r{,\s*})
    elsif parent && parent.scientific_names.size > 0 # pick up from parent
      names_to_add = parent.scientific_names.map { |s| s.name }
    else
      logger.warn("Warning: no scientific name (not even on parent crop) for #{self}")
    end

    cropbot = Member.find_by(login_name: 'cropbot')

    return unless names_to_add.size > 0
    raise "cropbot account not found: run rake db:seed" unless cropbot

    add_names_to_list(names_to_add, 'scientific')
  end

  def add_alternate_names_from_csv(alternate_names)
    # i.e. we actually passed something in, which isn't a given
    return if alternate_names.blank?

    cropbot = Member.find_by!(login_name: 'cropbot')
    names_to_add = alternate_names.split(%r{,\s*})
    add_names_to_list(names_to_add, 'alternate')
  rescue
    raise "cropbot account not found: run rake db:seed" unless cropbot
  end

  def rejection_explanation
    return rejection_notes if reason_for_rejection == "other"
    reason_for_rejection
  end

  # Crop.search(string)
  def self.search(query)
    if ENV['GROWSTUFF_ELASTICSEARCH'] == "true"
      search_str = query.nil? ? "" : query.downcase
      response = __elasticsearch__.search({
                                            # Finds documents which match any field, but uses the _score from
                                            # the best field insead of adding up _score from each field.
                                            query: {
                                              multi_match: {
                                                query: "#{search_str}",
                                                analyzer: "standard",
                                                fields: ["name",
                                                         "scientific_names.scientific_name",
                                                         "alternate_names.name"]
                                              }
                                            },
                                            filter: {
                                              term: { approval_status: "approved" }
                                            },
                                            size: 50
                                          }
      )
      response.records.to_a
    else
      # if we don't have elasticsearch, just do a basic SQL query.
      # also, make sure it's an actual array not an activerecord
      # collection, so it matches what we get from elasticsearch and we can
      # manipulate it in the same ways (eg. deleting elements without deleting
      # the whole record from the db)
      matches = Crop.approved.where("name ILIKE ?", "%#{query}%").to_a

      # we want to make sure that exact matches come first, even if not
      # using elasticsearch (eg. in development)
      exact_match = Crop.approved.find_by(name: query)
      if exact_match
        matches.delete(exact_match)
        matches.unshift(exact_match)
      end

      matches
    end
  end

  def Crop.case_insensitive_name(name)
    where(["lower(name) = :value", { value: name.downcase }])
  end

  private

  def add_names_to_list(names_to_add, list_name)
    names_to_add.each do |n|
      if name_already_exists(list_name, n)
        logger.warn("Warning: skipping duplicate #{list_name} name #{n} for #{self}")
      else
        create_crop_in_list(list_name, n)
      end
    end
  end

  def create_crop_in_list(list_name, name)
    cropbot = Member.find_by(login_name: 'cropbot')
    create_hash = {
      creator_id: "#{cropbot.id}",
      name: name
    }
    self.send("#{list_name}_names").create(create_hash)
  end

  def name_already_exists(list_name, name)
    self.send("#{list_name}_names").exists?(name: name)
  end

  def count_uses_of_property(col_name)
    data = Hash.new(0)
    plantings.each do |p|
      data[p.send("#{col_name}")] += 1 if !p.send("#{col_name}").blank?
    end
    data
  end

  # Custom validations

  def approval_status_cannot_be_changed_again
    previous = previous_changes.include?(:approval_status) ? previous_changes.approval_status : {}
    return unless previous.include?(:rejected) || previous.include?(:approved)
    errors.add(:approval_status, "has already been set to #{approval_status}")
  end

  def must_be_rejected_if_rejected_reasons_present
    return if rejected?
    return unless reason_for_rejection.present? || rejection_notes.present?
    errors.add(:approval_status, "must be rejected if a reason for rejection is present")
  end

  def must_have_meaningful_reason_for_rejection
    return unless reason_for_rejection == "other" && rejection_notes.blank?
    errors.add(:rejection_notes, "must be added if the reason for rejection is \"other\"")
  end
end
