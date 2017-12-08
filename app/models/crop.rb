class Crop < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  ##
  ## Triggers
  before_destroy { |crop| crop.posts.clear }

  ##
  ## Relationships
  has_many :scientific_names, after_add: :update_index, after_remove: :update_index, dependent: :destroy
  accepts_nested_attributes_for :scientific_names, allow_destroy: true, reject_if: :all_blank
  has_many :alternate_names, after_add: :update_index, after_remove: :update_index, dependent: :destroy
  has_many :plantings
  has_many :photos, through: :plantings
  has_many :seeds
  has_many :harvests
  has_many :plant_parts, -> { uniq.reorder("plant_parts.name") }, through: :harvests
  belongs_to :creator, class_name: 'Member'
  belongs_to :requester, class_name: 'Member'
  belongs_to :parent, class_name: 'Crop'
  has_many :varieties, class_name: 'Crop', foreign_key: 'parent_id'
  has_and_belongs_to_many :posts # rubocop:disable Rails/HasAndBelongsToMany

  ##
  ## Scopes
  scope :recent, -> { approved.order(created_at: :desc) }
  scope :toplevel, -> { approved.where(parent_id: nil) }
  scope :popular, -> { approved.reorder("plantings_count desc, lower(name) asc") }
  # ok on sqlite and psql, but not on mysql
  scope :randomized, -> { approved.reorder('random()') }
  scope :pending_approval, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }
  scope :interesting, -> { approved.has_photos.randomized }
  scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

  ##
  ## Validations
  # Reasons are only necessary when rejecting
  validates :reason_for_rejection, presence: true, if: :rejected?
  ## This validation addresses a race condition
  validate :approval_status_cannot_be_changed_again
  validate :must_be_rejected_if_rejected_reasons_present
  validate :must_have_meaningful_reason_for_rejection
  ## Wikipedia urls are only necessary when approving a crop
  validates :en_wikipedia_url,
    format: {
      with: %r{\Ahttps?:\/\/en\.wikipedia\.org\/wiki\/[[:alnum:]%_\.()-]+\z},
      message: 'is not a valid English Wikipedia URL'
    },
    if: :approved?

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
                   # that don't belong to any of these classes
                   token_chars: %w(letter digit)
                 }
               },
               analyzer: {
                 gs_edgeNGram_analyzer: {
                   tokenizer: "gs_edgeNGram_tokenizer",
                   filter: ["lowercase"]
                 }
               }
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

  def harvest_photos
    Photo.joins(:harvests).where("harvests.crop_id": id)
  end

  # update the Elasticsearch index (only if we're using it in this
  # environment)
  def update_index(_name_obj)
    __elasticsearch__.index_document if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"
  end
  # End Elasticsearch section

  def to_s
    name
  end

  def default_scientific_name
    scientific_names.first.name unless scientific_names.empty?
  end

  # currently returns the first available photo, but exists so that
  # later we can choose a default photo based on different criteria,
  # eg. popularity
  def default_photo
    # most recent photo
    return photos.order(created_at: :desc).first if photos.any?

    # Crop has no photos? Look for the most recent harvest with a photo.
    harvest_with_photo = Harvest.where(crop_id: id).joins(:photos).order('harvests.id DESC').limit(1).first
    harvest_with_photo.photos.first if harvest_with_photo
  end

  # returns hash indicating whether this crop is grown in
  # sun/semi-shade/shade
  # key: sunniness (eg. 'sun')
  # value: count of how many times it's been used by plantings
  def sunniness
    count_uses_of_property 'sunniness'
  end

  # returns a hash of propagation methods (seed, seedling, etc),
  # key: propagation method (eg. 'seed')
  # value: count of how many times it's been used by plantings
  def planted_from
    count_uses_of_property 'planted_from'
  end

  # returns a hash of most harvested plant parts (fruit, seed, etc)
  # key: plant part (eg. 'fruit')
  # value: count of how many times it's been used by harvests
  def popular_plant_parts
    PlantPart.joins(:harvests)
      .where("crop_id = ?", id)
      .order("count_harvests_id DESC")
      .group("plant_parts.id", "plant_parts.name")
      .count("harvests.id")
  end

  def annual?
    !perennial
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
    %w(rejected pending approved)
  end

  def reasons_for_rejection
    ["already in database", "not edible", "not enough information", "other"]
  end

  def rejection_explanation
    return rejection_notes if reason_for_rejection == "other"
    reason_for_rejection
  end

  def update_medians
    plantings.each(&:update_harvest_days)
    update_lifespan_medians
    update_harvest_medians
  end

  def update_lifespan_medians
    # Median lifespan of plantings
    update(median_lifespan: Planting.where(crop: self).median(:lifespan))
  end

  def update_harvest_medians
    update(median_days_to_first_harvest: Planting.where(crop: self).median(:days_to_first_harvest))
    update(median_days_to_last_harvest: Planting.where(crop: self).median(:days_to_last_harvest))
  end

  def self.search(query)
    CropSearchService.search(query)
  end

  def self.case_insensitive_name(name)
    where(["lower(crops.name) = :value", { value: name.downcase }])
  end

  private

  def count_uses_of_property(col_name)
    plantings.unscoped
      .where(crop_id: id)
      .where.not(col_name => nil)
      .group(col_name)
      .count
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
