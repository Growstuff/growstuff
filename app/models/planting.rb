class Planting < ActiveRecord::Base
  extend FriendlyId
  include PhotoCapable
  friendly_id :planting_slug, use: [:slugged, :finders]

  # Constants
  SUNNINESS_VALUES = %w[sun semi-shade shade]
  PLANTED_FROM_VALUES = [
    'seed',
    'seedling',
    'cutting',
    'root division',
    'runner',
    'bulb',
    'root/tuber',
    'bare root plant',
    'advanced plant',
    'graft',
    'layering'
  ]

  ##
  ## Triggers
  before_save :calculate_lifespan

  belongs_to :garden
  belongs_to :owner, class_name: 'Member', counter_cache: true
  belongs_to :crop, counter_cache: true
  has_many :harvests, dependent: :destroy

  ##
  ## Scopes
  default_scope { joins(:owner).order(created_at: :desc) }
  scope :finished, -> { where(finished: true) }
  scope :current, -> { where(finished: false) }
  scope :interesting, -> { has_photos.one_per_owner }
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
  validates :quantity, allow_nil: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 0
  }
  validates :sunniness, allow_nil: true, allow_blank: true, inclusion: {
    in: SUNNINESS_VALUES, message: "%{value} is not a valid sunniness value"
  }
  validates :planted_from, allow_nil: true, allow_blank: true, inclusion: {
    in: PLANTED_FROM_VALUES, message: "%{value} is not a valid planting method"
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
    photos.first
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
      return finished_at - planted_at
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

  private

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at && finished_at # only check if we have both
    errors.add(:finished_at, "must be after the planting date") unless planted_at < finished_at
  end
end
