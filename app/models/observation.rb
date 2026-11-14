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

  before_validation { self.observed_at ||= Time.zone.now }

  validates :observed_at, comparison: { less_than_or_equal_to: -> { Time.zone.now }, message: :not_in_future }

  scope :newest_first, -> { order(observed_at: :desc, id: :desc) }

  def problem?
    PROBLEM_KINDS.include?(kind)
  end
end
