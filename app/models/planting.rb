class Planting < ActiveRecord::Base
  extend FriendlyId
  include PhotoCapable
  include Finishable
  friendly_id :planting_slug, use: %i(slugged finders)

  # Constants
  SUNNINESS_VALUES = %w(sun semi-shade shade).freeze
  PLANTED_FROM_VALUES = [
    'seed', 'seedling', 'cutting', 'root division', 'runner',
    'bulb', 'root/tuber', 'bare root plant', 'advanced plant',
    'graft', 'layering'
  ].freeze

  ##
  ## Triggers
  before_save :calculate_lifespan

  belongs_to :garden
  belongs_to :owner, class_name: 'Member', counter_cache: true
  belongs_to :crop, counter_cache: true
  has_many :harvests, dependent: :destroy

  #
  # Ancestry of food
  belongs_to :parent_seed, class_name: 'Seed', foreign_key: 'parent_seed_id' # parent
  has_many :child_seeds, class_name: 'Seed',
                         foreign_key: 'parent_planting_id', dependent: :nullify # children

  ##
  ## Scopes
  default_scope { joins(:owner) } # Ensures the owner still exists
  scope :interesting, -> { has_photos.one_per_owner }
  scope :recent, -> { order(created_at: :desc) }
  scope :one_per_owner, lambda {
    joins("JOIN members m ON (m.id=plantings.owner_id)
           LEFT OUTER JOIN plantings p2
           ON (m.id=p2.owner_id AND plantings.id < p2.id)").where("p2 IS NULL")
  }

  ##
  ## Delegations
  delegate :name, :en_wikipedia_url, :default_scientific_name, :plantings_count,
    to: :crop, prefix: true

  ##
  ## Validations
  validates :garden, presence: true
  validates :crop, presence: true, approved: { message: "must be present and exist in our database" }
  validate :finished_must_be_after_planted
  validate :owner_must_match_garden_owner
  validates :quantity, allow_nil: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0
  }
  validates :sunniness, allow_nil: true, allow_blank: true, inclusion: {
    in: SUNNINESS_VALUES, message: "%<value>s is not a valid sunniness value"
  }
  validates :planted_from, allow_nil: true, allow_blank: true, inclusion: {
    in: PLANTED_FROM_VALUES, message: "%<value>s is not a valid planting method"
  }

  def planting_slug
    [
      owner.login_name,
      garden.present? ? garden.name : 'null',
      crop.present? ? crop.name : 'null'
    ].join('-').tr(' ', '-').downcase
  end

  # location = garden owner + garden name, i.e. "Skud's backyard"
  def location
    I18n.t("gardens.location", garden: garden.name, owner: garden.owner.login_name)
  end

  # stringify as "beet in Skud's backyard" or similar
  def to_s
    I18n.t('plantings.string', crop: crop.name, garden: garden.name, owner: owner)
  end

  def default_photo
    photos.order(created_at: :desc).first
  end

  def planted?
    planted_at.present? && planted_at <= Date.current
  end

  def finish_predicted_at
    planted_at + crop.median_lifespan.days if crop.median_lifespan.present? && planted_at.present?
  end

  def calculate_lifespan
    self.lifespan = (planted_at.present? && finished_at.present? ? finished_at - planted_at : nil)
  end

  def expected_lifespan
    if planted_at.present? && finished_at.present?
      return (finished_at - planted_at).to_i
    end
    crop.median_lifespan
  end

  def days_since_planted
    (Time.zone.today - planted_at).to_i if planted_at.present?
  end

  def percentage_grown
    return 100 if finished
    return if planted_at.blank? || expected_lifespan.blank?
    p = (days_since_planted / expected_lifespan.to_f) * 100
    return p if p <= 100
    100
  end

  def update_harvest_days
    days_to_first_harvest = nil
    days_to_last_harvest = nil
    if planted_at.present? && harvests_with_dates.size.positive?
      days_to_first_harvest = (first_harvest_date - planted_at).to_i
      days_to_last_harvest = (last_harvest_date - planted_at).to_i if finished?
    end
    update(days_to_first_harvest: days_to_first_harvest, days_to_last_harvest: days_to_last_harvest)
  end

  def first_harvest_date
    harvests_with_dates.minimum(:harvested_at)
  end

  def last_harvest_date
    harvests_with_dates.maximum(:harvested_at)
  end

  private

  def harvests_with_dates
    harvests.where.not(harvested_at: nil)
  end

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at && finished_at # only check if we have both
    errors.add(:finished_at, "must be after the planting date") unless planted_at < finished_at
  end

  def owner_must_match_garden_owner
    errors.add(:owner, "must be the same as garden") unless owner == garden.owner
  end
end
