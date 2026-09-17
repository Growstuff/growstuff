# frozen_string_literal: true

class Seed < ApplicationRecord
  extend FriendlyId
  include PhotoCapable
  include Finishable
  include Ownable

  friendly_id :seed_slug, use: %i(slugged finders)

  TRADABLE_TO_VALUES = %w(nowhere locally nationally internationally).freeze
  ORGANIC_VALUES = ['certified organic', 'non-certified organic', 'conventional/non-organic', 'unknown'].freeze
  GMO_VALUES = ['certified GMO-free', 'non-certified GMO-free', 'GMO', 'unknown'].freeze
  HEIRLOOM_VALUES = %w(heirloom hybrid unknown).freeze
  SOURCE_VALUES = ['seed catalogue', 'retail outlet', 'seed bank or similar institution',
                   'traded from another person', 'my own seed saving', 'other/unknown'].freeze

  #
  # Relationships
  belongs_to :crop
  belongs_to :parent_planting, class_name: 'Planting',
                               optional: true, inverse_of: :child_seeds # parent
  has_many :child_plantings, class_name: 'Planting',
                             foreign_key: 'parent_seed_id', dependent: :nullify,
                             inverse_of: :parent_seed # children

  #
  # Validations
  validates :crop, approved: true
  validates :crop, presence: { message: :crop_not_found }
  validates :quantity, allow_nil:    true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_min, allow_nil:    true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :days_until_maturity_max, allow_nil:    true,
                                      numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tradable_to, allow_blank: false,
                          inclusion:   { in: TRADABLE_TO_VALUES, message: :tradable_to_inclusion }
  validates :organic, allow_blank: false,
                      inclusion:   { in: ORGANIC_VALUES, message: :organic_inclusion }
  validates :gmo, allow_blank: false,
                  inclusion:   { in: GMO_VALUES, message: :gmo_inclusion }
  validates :heirloom, allow_blank: false,
                       inclusion:   { in: HEIRLOOM_VALUES, message: :heirloom_inclusion }
  validates :source, allow_blank: true,
                     inclusion:   { in: SOURCE_VALUES, message: :source_inclusion }

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
  scope :has_location, -> { joins(:owner).where.not('members.location': nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where('finished <> true').where('finished_at IS NULL OR finished_at < ?', Time.zone.now) }
  scope :expired, -> { active.where('plant_before < ?', Time.zone.today) }

  def tradable
    tradable_to != 'nowhere'
  end

  def seed_slug
    "#{owner.login_name}-#{crop}".downcase.tr(' ', '-')
  end

  def to_s
    I18n.t('seeds.string', crop: crop.name, owner:)
  end

  def self.homepage_records(limit)
    current.tradable
           .where("plant_before IS NULL OR plant_before < ?", Time.zone.today)
           .order(created_at: :desc)
           .limit(limit)
  end
end
