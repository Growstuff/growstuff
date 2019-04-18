class Crop < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i(slugged finders)

  ##
  ## Triggers
  before_destroy { |crop| crop.posts.clear }

  ##
  ## Relationships
  has_many :scientific_names, dependent: :destroy
  accepts_nested_attributes_for :scientific_names, allow_destroy: true, reject_if: :all_blank
  has_many :alternate_names, dependent: :destroy
  has_many :plantings, dependent: :destroy
  has_many :seeds, dependent: :destroy
  has_many :harvests, dependent: :destroy
  has_many :photographings, dependent: :destroy
  has_many :photos, through: :photographings
  has_many :plant_parts, -> { distinct.order("plant_parts.name") }, through: :harvests
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_crops
  belongs_to :requester, class_name: 'Member', optional: true, inverse_of: :requested_crops
  belongs_to :parent, class_name: 'Crop', optional: true, inverse_of: :varieties
  has_many :varieties, class_name: 'Crop', foreign_key: 'parent_id', dependent: :nullify, inverse_of: :parent
  has_and_belongs_to_many :posts # rubocop:disable Rails/HasAndBelongsToMany

  ##
  ## Scopes
  scope :recent, -> { approved.order(created_at: :desc) }
  scope :toplevel, -> { approved.where(parent_id: nil) }
  scope :popular, -> { approved.order("plantings_count desc, lower(name) asc") }
  scope :pending_approval, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }
  scope :interesting, -> { approved.has_photos }
  scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

  # Special scope to control if it's in the search index
  scope :search_import, -> { approved }

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
      with:    %r{\Ahttps?:\/\/en\.wikipedia\.org\/wiki\/[[:alnum:]%_\.()-]+\z},
      message: 'is not a valid English Wikipedia URL'
    },
    if:     :approved?

  ####################################
  # Elastic search configuration
  if ENV["GROWSTUFF_ELASTICSEARCH"] == "true"
    searchkick word_start: %i(name alternate_names scientific_names), case_sensitive: false
  end

  def planting_photos
    Photo.joins(:plantings).where("plantings.crop_id": id)
  end

  def harvest_photos
    Photo.joins(:harvests).where("harvests.crop_id": id)
  end

  def seed_photos
    Photo.joins(:seeds).where("seeds.crop_id": id)
  end

  def to_s
    name
  end

  def to_param
    slug
  end

  def default_scientific_name
    scientific_names.first.name unless scientific_names.empty?
  end

  # currently returns the first available photo, but exists so that
  # later we can choose a default photo based on different criteria,
  # eg. popularity
  def default_photo
    first_photo(:plantings) || first_photo(:harvests) || first_photo(:seeds)
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
    photos.size >= 3 || plantings_count >= 3
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
    plantings.each(&:update_harvest_days!)
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

  def self.case_insensitive_name(name)
    where(["lower(crops.name) = :value", { value: name.downcase }])
  end

  def should_index?
    approved?
  end

  def search_data
    {
      name:             name,
      alternate_names:  alternate_names.pluck(:name),
      scientific_names: scientific_names.pluck(:name),
      plantings_count:  plantings_count, # boost the crops that are planted the most
      planters_ids:     plantings.pluck(:owner_id) # boost this product for these members
    }
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

  def first_photo(type)
    Photo.joins(type).where("#{type}": { crop_id: id }).order("photos.created_at DESC").first
  end
end
