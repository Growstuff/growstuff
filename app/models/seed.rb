class Seed < ActiveRecord::Base
  extend FriendlyId
  include PhotoCapable
  friendly_id :seed_slug, use: %i(slugged finders)

  TRADABLE_TO_VALUES = %w(nowhere locally nationally internationally).freeze
  ORGANIC_VALUES = ['certified organic', 'non-certified organic', 'conventional/non-organic', 'unknown'].freeze
  GMO_VALUES = ['certified GMO-free', 'non-certified GMO-free', 'GMO', 'unknown'].freeze
  HEIRLOOM_VALUES = %w(heirloom hybrid unknown).freeze

  #
  # Relationships
  belongs_to :crop
  belongs_to :owner, class_name: 'Member', foreign_key: 'owner_id', counter_cache: true

  #
  # Validations
  validates :crop, approved: true
  validates :crop, presence: { message: "must be present and exist in our database" }
  validates :quantity, allow_nil: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_min, allow_nil: true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_max, allow_nil: true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tradable_to, allow_nil: false, allow_blank: false,
                          inclusion: { in: TRADABLE_TO_VALUES, message: "You may only trade seed nowhere, "\
                                                "locally, nationally, or internationally" }
  validates :organic, allow_nil: false, allow_blank: false,
                      inclusion: { in: ORGANIC_VALUES, message: "You must say whether the seeds "\
                                             "are organic or not, or that you don't know" }
  validates :gmo, allow_nil: false, allow_blank: false,
                  inclusion: { in: GMO_VALUES, message: "You must say whether the seeds are "\
                                                        "genetically modified or not, or that you don't know" }
  validates :heirloom, allow_nil: false, allow_blank: false,
                       inclusion: { in: HEIRLOOM_VALUES, message: "You must say whether the seeds"\
                                                                  "are heirloom, hybrid, or unknown" }

  #
  # Delegations
  delegate :name, to: :crop

  #
  # Scopes
  default_scope { joins(:owner) } # Ensure owner exists
  scope :tradable, -> { where.not(tradable_to: 'nowhere') }
  scope :interesting, -> { tradable.has_location }
  scope :has_location, -> { joins(:owner).where.not("members.location": nil) }

  def default_photo
    photos.order(created_at: :desc).first
  end

  def tradable?
    tradable_to != 'nowhere'
  end

  def seed_slug
    "#{owner.login_name}-#{crop}".downcase.tr(' ', '-')
  end

  def to_s
    I18n.t('seeds.string', crop: crop.name, owner: owner)
  end
end
