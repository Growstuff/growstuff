# frozen_string_literal: true

class Planting < ApplicationRecord
  extend FriendlyId
  include PhotoCapable
  include Finishable
  include Ownable
  include PredictPlanting
  include PredictHarvest
  include SearchPlantings

  friendly_id :planting_slug, use: %i(slugged finders)

  # Constants
  SUNNINESS_VALUES = %w(sun semi-shade shade).freeze
  PLANTED_FROM_VALUES = [
    'seed', 'seedling', 'cutting', 'root division', 'runner',
    'bulb', 'root/tuber', 'bare root plant', 'advanced plant',
    'graft', 'layering'
  ].freeze

  belongs_to :garden
  belongs_to :crop, counter_cache: true
  has_many :harvests, dependent: :destroy

  #
  # Ancestry of food
  belongs_to :parent_seed, class_name:  'Seed', # parent
                           foreign_key: 'parent_seed_id',
                           optional:    true,
                           inverse_of:  :child_plantings
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
  scope :active, -> { where('finished <> true').where('finished_at IS NULL OR finished_at < ?', Time.zone.now) }
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

  delegate :annual?, :perennial?, :svg_icon, to: :crop
  delegate :location, :longitude, :latitude, to: :garden

  ##
  ## Validations
  validates :garden, presence: true
  validates :crop, presence: true, approved: { message: "must be present and exist in our database" }
  validate :finished_must_be_after_planted
  validate :owner_must_match_garden_owner
  validates :quantity, allow_nil: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0
  }
  validates :sunniness, allow_blank: true, inclusion: {
    in: SUNNINESS_VALUES, message: "%<value>s is not a valid sunniness value"
  }
  validates :planted_from, allow_blank: true, inclusion: {
    in: PLANTED_FROM_VALUES, message: "%<value>s is not a valid planting method"
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
    I18n.t('plantings.string', crop: crop.name, garden: garden.name, owner: owner)
  end

  def finished?
    finished || (finished_at.present? && finished_at <= Time.zone.today)
  end

  def planted?
    planted_at.present? && planted_at <= Time.zone.today
  end

  def growing?
    planted? && !finished?
  end

  def nearby_same_crop
    return Planting.none if location.blank? || latitude.blank? || longitude.blank?

    # latitude, longitude = Geocoder.coordinates(location, params: { limit: 1 })
    Planting.joins(:garden)
      .where(crop: crop)
      .located
      .where('gardens.latitude < ? AND gardens.latitude > ?',
             latitude + 10, latitude - 10)
  end

  private

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at && finished_at # only check if we have both

    errors.add(:finished_at, "must be after the planting date") unless planted_at < finished_at
  end

  def owner_must_match_garden_owner
    errors.add(:owner, "must be the same as garden") unless owner == garden.owner
  end
end
