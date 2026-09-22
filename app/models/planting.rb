# frozen_string_literal: true

class Planting < ApplicationRecord
  extend FriendlyId
  include PhotoCapable
  include Finishable
  include Ownable
  include PredictPlanting
  include PredictHarvest
  include Likeable

  friendly_id :planting_slug, use: %i(slugged finders)

  # Constants
  SUNNINESS_VALUES = %w(sun semi-shade shade).freeze
  # The most individual plants the layout grid will draw for one planting.
  MAX_PLANTS = 100
  PLANTED_FROM_VALUES = [
    'seed', 'seedling', 'cutting', 'root division', 'runner',
    'bulb', 'root/tuber', 'bare root plant', 'advanced plant',
    'graft', 'layering'
  ].freeze

  belongs_to :garden
  belongs_to :crop, counter_cache: true
  has_many :harvests, dependent: :destroy
  has_many :activities, dependent: :destroy
  # One per individual plant, for placing on the garden's layout grid.
  has_many :plants, dependent: :destroy

  after_create :sync_plants
  after_update :sync_plants, if: :saved_change_to_quantity?

  scope :current, -> { where.not(finished: true).where.not(failed: true) }

  #
  # Ancestry of food
  belongs_to :parent_seed, class_name: 'Seed', # parent,
                           optional:   true,
                           inverse_of: :child_plantings
  has_many :child_seeds, class_name:  'Seed', # children
                         foreign_key: 'parent_planting_id',
                         inverse_of:  :parent_planting,
                         dependent:   :nullify

  ##
  ## Scopes
  scope :located, lambda {
    joins(:garden)
      .where.not(gardens: { location: '' })
      .where.not(gardens: { latitude: nil })
      .where.not(gardens: { longitude: nil })
  }
  scope :active, -> { where(finished: false, failed: false).where('finished_at IS NULL OR finished_at < ?', Time.zone.now) }
  scope :failed, -> { where(failed: true) }
  scope :annual, -> { joins(:crop).where(crops: { perennial: false }) }
  scope :perennial, -> { joins(:crop).where(crops: { perennial: true }) }
  scope :interesting, -> { has_photos.one_per_owner.order(planted_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :has_harvests, -> { where('plantings.harvests_count > 0') }
  scope :one_per_owner, lambda {
    joins("JOIN members m ON (m.id=plantings.owner_id)
           LEFT OUTER JOIN plantings p2
           ON (m.id=p2.owner_id AND plantings.id < p2.id)").where("p2 IS NULL")
  }

  ##
  ## Delegations
  delegate :name, :slug, :en_wikipedia_url, :default_scientific_name, :plantings_count, :perennial,
           to: :crop, prefix: true
  delegate :login_name, :slug, :location, to: :owner, prefix: true
  delegate :slug, to: :planting, prefix: true
  delegate :slug, :name, to: :garden, prefix: true

  delegate :annual?, :perennial?, :svg_icon, to: :crop
  delegate :location, :longitude, :latitude, to: :garden

  ##
  ## Validations
  validates :garden, presence: true
  validates :crop, presence: true, approved: { message: :crop_must_be_approved }
  validate :finished_must_be_after_planted
  validate :owner_must_match_garden_owner
  validate :cannot_be_finished_and_failed
  validates :quantity, allow_nil: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0
  }
  validates :sunniness, allow_blank: true, inclusion: {
    in: SUNNINESS_VALUES, message: :not_a_valid_sunniness
  }
  validates :planted_from, allow_blank: true, inclusion: {
    in: PLANTED_FROM_VALUES, message: :not_a_valid_planting_method
  }
  validates :overall_rating, allow_blank: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5
  }

  def planting_slug
    [
      owner.login_name,
      garden.present? ? garden.name : 'null',
      crop.present? ? crop.name : 'null'
    ].join('-').tr(' ', '-').downcase
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    I18n.t('plantings.string', crop: crop.name, garden: garden.name, owner:)
  end

  def finished?
    (finished || (finished_at.present? && finished_at <= Time.zone.today)) && !failed?
  end

  def failed?
    failed
  end

  def planted?
    planted_at.present? && planted_at <= Time.zone.today
  end

  # How many individual plants this planting is. A blank quantity means nobody
  # said, which we treat as a single plant so it still has something to place.
  #
  # Capped: a planting of a thousand seedlings would be a thousand rows and a
  # thousand circles on the bed, which is neither drawable nor useful. Past the
  # cap the layout shows MAX_PLANTS of them and the planting's own quantity
  # stays whatever the member set.
  def plant_count
    quantity.to_i.clamp(1, MAX_PLANTS)
  end

  # Whether the bed is showing fewer plants than the planting says it has.
  def plants_capped?
    quantity.to_i > MAX_PLANTS
  end

  def growing?
    planted? && !finished?
  end

  def nearby_same_crop
    return @nearby_same_crop if defined?(@nearby_same_crop)

    @nearby_same_crop = if location.blank? || latitude.blank? || longitude.blank?
                          Planting.none
                        else
                          # latitude, longitude = Geocoder.coordinates(location, params: { limit: 1 })
                          Planting.joins(:garden)
                            .where(crop:)
                            .located
                            .where('gardens.latitude < ? AND gardens.latitude > ?',
                                   latitude + 10, latitude - 10)
                        end
  end

  def self.homepage_records(limit)
    recent.one_per_owner.limit(limit)
  end

  private

  def cannot_be_finished_and_failed
    errors.add(:failed, :failed_and_finished) if finished && failed
  end

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at && finished_at # only check if we have both

    errors.add(:finished_at, :finished_after_planted) unless planted_at < finished_at
  end

  def owner_must_match_garden_owner
    return if garden.blank? # reported by the garden presence validation
    return if owner == garden.owner || garden.garden_collaborators.where(member_id: owner).any?

    errors.add(:owner, :same_owner_required)
  end

  # Keeps one Plant per plant this planting has, so the layout grid has that
  # many circles to place. Growing the number adds unplaced plants; shrinking it
  # takes the unplaced ones away first, so what is already arranged on the bed
  # is left alone for as long as possible.
  def sync_plants
    wanted = plant_count
    have = plants.count
    return if have == wanted
    return add_plants(wanted - have) if have < wanted

    remove_plants(have - wanted)
  end

  # One insert rather than a save each: a planting of 200 seedlings is one row
  # per plant, and the factories alone would make that a lot of round trips.
  def add_plants(count)
    now = Time.current
    Plant.insert_all(Array.new(count) { { planting_id: id, created_at: now, updated_at: now } }) # rubocop:disable Rails/SkipsModelValidations
  end

  # Unplaced plants go first, so what is already arranged on the bed survives
  # as long as possible; only then does it start lifting placed ones.
  def remove_plants(count)
    surplus = plants.unplaced.order(id: :desc).limit(count).ids
    surplus += plants.placed.order(id: :desc).limit(count - surplus.size).ids if surplus.size < count
    Plant.where(id: surplus).delete_all
  end
end
