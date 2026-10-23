# frozen_string_literal: true

class Job < ApplicationRecord
  extend FriendlyId
  include Ownable
  include Finishable
  include PhotoCapable

  belongs_to :garden, optional: true
  belongs_to :jobbable, polymorphic: true, optional: true
  # The template step this job was made from, if it was.
  belongs_to :crop_job_step, optional: true

  JOBBABLE_TYPES = %w(Crop Planting Seed).freeze

  scope :active, -> { where(finished: [false, nil]) }
  scope :finished_this_week, -> { where(finished: true, finished_at: Time.zone.now.beginning_of_week..) }

  friendly_id :job_slug, use: %i(slugged finders)

  validates :name, presence: true
  validates :slug, uniqueness: true
  # The add form sends these empty when the job is not linked to anything.
  normalizes :jobbable_type, with: ->(type) { type.presence }
  validates :jobbable_type, inclusion: { in: JOBBABLE_TYPES }, allow_nil: true
  validate :jobbable_is_the_owners, if: -> { jobbable_id_changed? || jobbable_type_changed? }

  before_save :stamp_finished_at, if: :finished_changed?

  delegate :login_name, :slug, to: :owner, prefix: true
  delegate :name, to: :garden, prefix: true, allow_nil: true

  def job_slug
    "#{owner.login_name}-#{name}-#{id}".downcase.tr(' ', '-')
  end

  def to_s
    name
  end

  # The planting a job is about, if it is about one. The form, Copy and the API
  # speak of plantings; the link itself is the jobbable.
  def planting
    jobbable if jobbable_type == 'Planting'
  end

  def planting=(planting)
    self.jobbable = planting
  end

  def planting_id
    jobbable_id if jobbable_type == 'Planting'
  end

  # Nothing chosen on the form leaves the job about whatever it was about.
  def planting_id=(id)
    self.jobbable = Planting.find_by(id:) if id.present?
  end

  # The photo taken before or after the job was done, if there is one. Of those
  # with the moment, the first added. Uses the loaded photos, so a list of jobs
  # can load them all at once.
  def photo_at(moment)
    photo_associations.select { |association| association.moment == moment }.min_by(&:id)&.photo
  end

  def planting_name
    planting&.crop_name
  end

  private

  def stamp_finished_at
    self.finished_at = (Time.zone.now if finished)
  end

  # Plantings and seeds are a member's own. A job can't be about someone else's.
  def jobbable_is_the_owners
    return unless JOBBABLE_TYPES.include?(jobbable_type) && jobbable.respond_to?(:owner_id)

    errors.add(:jobbable, :invalid) if jobbable.owner_id != owner_id
  end
end
