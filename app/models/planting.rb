class Planting < ActiveRecord::Base
  extend FriendlyId
  include PhotoCapable
  friendly_id :planting_slug, use: [:slugged, :finders]

  belongs_to :garden
  belongs_to :owner, class_name: 'Member', counter_cache: true
  belongs_to :crop, counter_cache: true
  has_many :harvests, dependent: :destroy

  default_scope { order(created_at: :desc) }
  scope :finished, -> { where(finished: true) }
  scope :current, -> { where(finished: false) }

  scope :interesting, -> { has_photos.one_per_owner }
  scope :one_per_owner, lambda {
    joins("JOIN members m ON (m.id=plantings.owner_id)
          LEFT OUTER JOIN plantings p2
          ON (m.id=p2.owner_id AND plantings.id < p2.id)").where("p2 IS NULL")
  }

  delegate :name,
    :en_wikipedia_url,
    :default_scientific_name,
    :plantings_count,
    to: :crop,
    prefix: true

  validates :garden, presence: true
  validates :crop, presence: true
  validates :crop, approved: { message: "must be present and exist in our database" }

  validates :quantity,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
    allow_nil: true

  SUNNINESS_VALUES = %w(sun semi-shade shade)
  validates :sunniness, inclusion: { in: SUNNINESS_VALUES,
                                     message: "%{value} is not a valid sunniness value" },
                        allow_nil: true,
                        allow_blank: true

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
  validates :planted_from, inclusion: { in: PLANTED_FROM_VALUES,
                                        message: "%{value} is not a valid planting method" },
                           allow_nil: true,
                           allow_blank: true

  validate :finished_must_be_after_planted

  delegate :days_until_finished, to: :predict
  delegate :days_until_mature, to: :predict
  delegate :percentage_grown, to: :predict
  delegate :start_to_finish_diff, to: :predict

  # check that any finished_at date occurs after planted_at
  def finished_must_be_after_planted
    return unless planted_at && finished_at # only check if we have both
    errors.add(:finished_at, "must be after the planting date") unless planted_at < finished_at
  end

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

  def calc_and_set_days_before_maturity
    self.days_before_maturity = predict.predict_days_before_maturity
  end

  private

  def predict
    PlantingPredictions.new(self)
  end
end
