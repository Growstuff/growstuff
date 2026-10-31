# frozen_string_literal: true

class Planting < ApplicationRecord
  extend FriendlyId
  include PhotoCapable
  include Finishable
  include Ownable
  include PredictPlanting
  include PredictHarvest
  include Likeable
  include Jobbable

  friendly_id :planting_slug, use: %i(slugged finders)

  # Constants
  SUNNINESS_VALUES = %w(sun semi-shade shade).freeze
  # The most individual plants the layout grid will draw for one planting.
  MAX_PLANTS = 100
  # How long a finished planting stays in the daily weather update: its last days of weather trail real time.
  WEATHER_FINISHED_DAYS = 30
  PLANTED_FROM_VALUES = [
    'seed', 'seedling', 'cutting', 'root division', 'runner',
    'bulb', 'root/tuber', 'bare root plant', 'advanced plant',
    'graft', 'layering'
  ].freeze

  belongs_to :garden
  belongs_to :crop, counter_cache: true
  belongs_to :alternate_name, optional: true
  # The gardens it was in before the one it is in now, oldest first.
  has_many :histories, -> { order(:ended_on, :id) }, class_name: 'PlantingHistory', dependent: :destroy, inverse_of: :planting
  has_many :harvests, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  # One per individual plant, for placing on the garden's layout grid. Made the
  # first time the garden's layout is used (Garden#prepare_layout), not for every
  # planting, as most plantings never go on a layout.
  has_many :plants, dependent: :destroy

  # Once a planting is on a layout, keep its plants in step with its quantity.
  before_create :remember_seed_plant_before
  after_update :sync_plants, if: -> { saved_change_to_quantity? && plants.exists? }

  scope :current, -> { where.not(finished: true).where.not(failed: true) }
  # The plantings the daily weather update collects for: planted, in a garden with a place that isn't a nursery, and
  # still growing or finished recently enough that their last days, which lag, may not be in yet.
  scope :weather_tracked, lambda { |today = Time.zone.today|
    where.not(failed: true).where(planted_at: ..today)
      .where('plantings.finished IS NOT TRUE OR plantings.finished_at >= ?', today - WEATHER_FINISHED_DAYS)
      .joins(:garden).merge(Garden.where.not(latitude: nil).where.not(longitude: nil).where(nursery: false))
  }

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
  validate :alternate_name_must_belong_to_crop
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

  def subject
    to_s
  end

  def author
    owner
  end

  def planting_slug
    [
      owner.login_name,
      garden.present? ? garden.name : 'null',
      crop.present? ? crop.name : 'null'
    ].join('-').tr(' ', '-').downcase
  end

  # The name the owner wants to see: their chosen alternate name, else the crop's primary name
  def display_name
    alternate_name&.name.presence || crop.name
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    I18n.t('plantings.string', crop: display_name, garden: garden.name, owner:)
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

  # Planted in the future: the member has planned this, but it isn't in the ground yet.
  def planned?
    planted_at.present? && planted_at > Time.zone.today
  end

  # How many individual plants this planting is. A blank quantity means nobody
  # said, which we treat as a single plant so it still has something to place;
  # zero is none, as when every plant has gone to the compost.
  #
  # Capped: a planting of a thousand seedlings would be a thousand rows and a
  # thousand circles on the bed, which is neither drawable nor useful. Past the
  # cap the layout shows MAX_PLANTS of them and the planting's own quantity
  # stays whatever the member set.
  def plant_count
    return 1 if quantity.nil?

    quantity.clamp(0, MAX_PLANTS)
  end

  # Whether the bed is showing fewer plants than the planting says it has.
  def plants_capped?
    quantity.to_i > MAX_PLANTS
  end

  # Moves this planting into another garden, on the day given, and keeps a record
  # of the garden it was in. It stays one planting, with its sow date, photos and
  # harvests, so the crop's averages count it once. If it can't be moved, it has
  # errors.
  def transplant_to(garden, on: Time.zone.today)
    histories.build(garden: self.garden, started_on: histories.filter_map(&:ended_on).max || planted_at, ended_on: on)
    update(garden:)
    self
  end

  # Sown after the year its seed packet said to plant it by.
  def sown_from_expired_seeds?
    seed_plant_before.present? && planted_at.present? && planted_at > seed_plant_before
  end

  def growing?
    planted? && !finished?
  end

  # Still in the nursery, which is somewhere seedlings are raised before they go out: it has no climate of its own to show.
  def in_nursery?
    garden.nursery?
  end

  def weather_located?
    latitude.present? && longitude.present?
  end

  # The weather isn't here yet but will be: this is a planting the daily update collects weather for.
  def weather_pending?
    self.class.weather_tracked.exists?(id)
  end

  # The day this planting is due, from its crop's expected lifespan, or nil when we don't know it.
  def weather_due_on
    planted_at + expected_lifespan.to_i if planted_at.present? && expected_lifespan.present?
  end

  # The weather this planting grew through, day by day: the readings for its garden's grid cell,
  # from planting to finishing, or to today while it is still growing, even past its due date. Empty when the
  # garden has no location.
  def weather_readings
    return WeatherReading.none unless weather_located? && planted_at.present?

    weather_cell_readings.between(planted_at, weather_last_day).order(:date)
  end

  # The last day of weather to show: today for a planting still growing, and the day it finished for one that has.
  def weather_last_day(today = Time.zone.today)
    [finished_at, today].compact.min
  end

  # For a planting still growing: the weather the rest of its life will probably bring, as the readings
  # for the same days a year earlier, moved forward a year. A prediction, not an observation. `after` is the
  # newest day already observed, when the caller has it.
  def expected_weather_readings(after: weather_readings.maximum(:date))
    due = weather_due_on
    return [] if finished? || failed? || due.nil? || !weather_located?

    from = (after || (planted_at - 1)) + 1
    return [] if from > due

    weather_cell_readings.select(*WeatherReading::CHARTED).between(from.prev_year, due.prev_year).order(:date).map do |reading|
      reading.tap do
        reading.date = reading.date.next_year
        reading.readonly!
      end
    end
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

  # How many plantings are growing in each of the gardens, by garden id.
  def self.growing_counts_by_garden(garden_ids)
    current.where(garden_id: garden_ids).group(:garden_id).count
  end

  def self.homepage_records(limit)
    recent.one_per_owner.limit(limit)
  end

  private

  # Daily weather for the grid cell this planting's garden is in.
  def weather_cell_readings
    WeatherReading.at(*WeatherReading.grid_point(latitude, longitude))
  end

  # Copied from the packet when the planting is made, as the packet may be
  # edited or thrown away later.
  def remember_seed_plant_before
    self.seed_plant_before ||= parent_seed&.plant_before
  end

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

  # One insert rather than a save each: a planting of a hundred seedlings is a
  # row per plant.
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

  def alternate_name_must_belong_to_crop
    return if alternate_name.blank? || alternate_name.crop_id == crop_id

    errors.add(:alternate_name, :invalid)
  end
end
