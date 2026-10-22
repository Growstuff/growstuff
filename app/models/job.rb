# frozen_string_literal: true

class Job < ApplicationRecord
  extend FriendlyId
  include Ownable
  include Finishable
  include Likeable

  belongs_to :garden, optional: true
  belongs_to :jobbable, polymorphic: true, optional: true

  JOBBABLE_TYPES = %w(Crop Planting Seed).freeze

  friendly_id :job_slug, use: %i(slugged finders)

  validates :name, presence: true
  validates :owner, presence: true

  validates :slug, uniqueness: true
  validates :jobbable_type, inclusion: { in: JOBBABLE_TYPES }, allow_nil: true
  validate :jobbable_is_the_owners, if: -> { jobbable_id_changed? || jobbable_type_changed? }

  delegate :location, :latitude, :longitude, to: :owner
  delegate :login_name, :slug, :location, to: :owner, prefix: true

  def job_slug
    "#{owner.login_name}-#{name}-#{id}".downcase.tr(' ', '-')
  end

  def to_s
    name
  end

  def garden_name
    garden&.name
  end

  def garden_slug
    garden&.slug
  end

  def planting_name
    planting&.crop&.name
  end

  def planting_slug
    planting&.crop&.slug
  end

  scope :active, -> { where(finished: [false, nil]) }

  # The planting, seeds or crop the job is about, each nil when it is about
  # something else. Setting one replaces what the job was about.
  %w(Crop Planting Seed).each do |type|
    name = type.underscore

    define_method(name) { jobbable if jobbable_type == type }
    define_method("#{name}=") { |record| self.jobbable = record }
    define_method("#{name}_id") { jobbable_id if jobbable_type == type }
    define_method("#{name}_id=") do |id|
      self.jobbable = id.present? ? type.constantize.find_by(id:) : nil
    end
  end

  # The crop the job is about, or the crop of the planting or seeds it is about.
  def about_crop
    jobbable.is_a?(Crop) ? jobbable : jobbable&.crop
  end

  private

  # Plantings and seeds are a member's own. A job can't be about someone else's.
  def jobbable_is_the_owners
    return unless JOBBABLE_TYPES.include?(jobbable_type) && jobbable.respond_to?(:owner_id)

    errors.add(:jobbable, :invalid) if jobbable.owner_id != owner_id
  end
end
