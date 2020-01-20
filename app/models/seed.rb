# frozen_string_literal: true

class Seed < ApplicationRecord
  extend FriendlyId
  include PhotoCapable
  include Finishable
  include Ownable
  include SearchSeeds
  friendly_id :seed_slug, use: %i(slugged finders)

  TRADABLE_TO_VALUES = %w(nowhere locally nationally internationally).freeze
  ORGANIC_VALUES = ['certified organic', 'non-certified organic', 'conventional/non-organic', 'unknown'].freeze
  GMO_VALUES = ['certified GMO-free', 'non-certified GMO-free', 'GMO', 'unknown'].freeze
  HEIRLOOM_VALUES = %w(heirloom hybrid unknown).freeze

  #
  # Relationships
  belongs_to :crop
  belongs_to :parent_planting, class_name: 'Planting', foreign_key: 'parent_planting_id',
                               optional: true, inverse_of: :child_seeds # parent
  has_many :child_plantings, class_name: 'Planting',
                             foreign_key: 'parent_seed_id', dependent: :nullify,
                             inverse_of: :parent_seed # children

  #
  # Validations
  validates :crop, approved: true
  validates :crop, presence: { message: "must be present and exist in our database" }
  validates :quantity, allow_nil:    true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_min, allow_nil:    true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_max, allow_nil:    true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tradable_to, allow_blank: false,
                          inclusion:   { in: TRADABLE_TO_VALUES, message: "You may only trade seed nowhere, "\
                                                "locally, nationally, or internationally" }
  validates :organic, allow_blank: false,
                      inclusion:   { in: ORGANIC_VALUES, message: "You must say whether the seeds "\
                                             "are organic or not, or that you don't know" }
  validates :gmo, allow_blank: false,
                  inclusion:   { in: GMO_VALUES, message: "You must say whether the seeds are "\
                                                        "genetically modified or not, or that you don't know" }
  validates :heirloom, allow_blank: false,
                       inclusion:   { in: HEIRLOOM_VALUES, message: "You must say whether the seeds"\
                                                                  "are heirloom, hybrid, or unknown" }

  #
  # Delegations
  delegate :name, to: :crop, prefix: true
  delegate :location, :latitude, :longitude, to: :owner
  delegate :login_name, :slug, :location, to: :owner, prefix: true

  #
  # Scopes
  default_scope { joins(:owner).merge(Member.kept) } # Ensure owner exists
  scope :tradable, -> { where.not(tradable_to: 'nowhere') }
  scope :interesting, -> { tradable.has_location }
  scope :has_location, -> { joins(:owner).where.not("members.location": nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where('finished <> true').where('finished_at IS NULL OR finished_at < ?', Time.zone.now) }

  def tradable
    tradable_to != 'nowhere'
  end

  def seed_slug
    "#{owner.login_name}-#{crop}".downcase.tr(' ', '-')
  end

  def to_s
    I18n.t('seeds.string', crop: crop.name, owner: owner)
  end
end
