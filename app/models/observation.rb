# frozen_string_literal: true

# Something a grower noticed about a planting, and when: it flowered, it wilted, a disease turned up.
class Observation < ApplicationRecord
  KINDS = %w(germination disease_observed flowering fruiting wilting).freeze
  # The kinds that are trouble, to be picked out on the timeline.
  PROBLEM_KINDS = %w(disease_observed wilting).freeze

  belongs_to :planting
  belongs_to :author, class_name: 'Member'

  # No kind is "other".
  enum :kind, KINDS.index_with(&:itself), validate: { allow_nil: true }

  validates :observed_at, presence: true
  validate :observed_at_not_in_future

  scope :newest_first, -> { order(observed_at: :desc, id: :desc) }

  def problem?
    PROBLEM_KINDS.include?(kind)
  end

  private

  def observed_at_not_in_future
    errors.add(:observed_at, :not_in_future) if observed_at && observed_at > Time.zone.now
  end
end
