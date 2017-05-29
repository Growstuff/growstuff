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

  def planted?(current_date = Date.current)
    planted_at.present? && current_date.to_date >= planted_at
  end

  def days_until_finished
    return 0 if finished?
    days = (finished_at - Date.current).to_i
    days.positive? ? days : 0
  end

  def days_until_mature
    days = ((planted_at + days_before_maturity) - Date.current).to_i
    days.positive? ? days : 0
  end

  def percentage_grown(current_date = Date.current)
    return nil unless days_before_maturity && planted?(current_date)

    days = (current_date.to_date - planted_at.to_date).to_i

    return 0 if current_date < planted_at
    return 100 if days > days_before_maturity
    percent = (days / days_before_maturity * 100).to_i

    if percent >= 100
      percent = 100
    end

    percent
  end

  def start_to_finish_diff
    (finished_at - planted_at).to_i if finished_at && planted_at
  end

  def self.mean_days_until_maturity(plantings)
    ## Given a set of finished plantings, calculate the average/mean time from start to finish
    differences = plantings.collect(&:start_to_finish_diff)
    differences.compact.sum / differences.compact.size unless differences.compact.empty?
  end

  def calc_and_set_days_before_maturity
    # calculate the number of days, from planted_at, until maturity
    if planted_at && finished_at
      self.days_before_maturity = start_to_finish_diff
    else
      self.days_before_maturity = Planting.mean_days_until_maturity other_finished_plantings_same_crop
    end
  end

  private

  def other_finished_plantings_same_crop
    Planting.where(crop_id: crop).where.not(id: id).where.not(finished_at: nil)
  end
end
