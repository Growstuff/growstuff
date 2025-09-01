# frozen_string_literal: true

class Problem < ApplicationRecord
  extend FriendlyId
  include PhotoCapable

  # include SearchCrops # Note: This might need to be adapted to SearchProblems

  friendly_id :name, use: %i(slugged finders)

  ##
  ## Relationships
  belongs_to :creator, class_name: 'Member', optional: true, inverse_of: :created_problems
  belongs_to :requester, class_name: 'Member', optional: true, inverse_of: :requested_problems
  has_many :planting_problems, dependent: :delete_all
  has_many :plantings, through: :planting_problems
  has_many :problem_posts, dependent: :delete_all
  has_many :posts, through: :problem_posts, dependent: :delete_all

  ##
  ## Scopes
  scope :recent, -> { approved.order(created_at: :desc) }
  scope :popular, -> { approved.order(Arel.sql("plantings_count desc, lower(name) asc")) }
  scope :pending_approval, -> { where(approval_status: "pending") }
  scope :approved, -> { where(approval_status: "approved") }
  scope :rejected, -> { where(approval_status: "rejected") }
  scope :interesting, -> { approved.has_photos }
  scope :has_photos, -> { includes(:photos).where.not(photos: { id: nil }) }

  ##
  ## Validations
  validates :reason_for_rejection, presence: true, if: :rejected?
  validate :must_be_rejected_if_rejected_reasons_present
  validate :must_have_meaningful_reason_for_rejection
  validates :name, uniqueness: { scope: :approval_status }, if: :pending?

  def to_s
    name
  end

  def to_param
    slug
  end

  def pending?
    approval_status == "pending"
  end

  def approved?
    approval_status == "approved"
  end

  def rejected?
    approval_status == "rejected"
  end

  def approval_statuses
    %w(rejected pending approved)
  end

  def reasons_for_rejection
    ["already in database", "not a pest or disease", "not enough information", "other"]
  end

  def rejection_explanation
    return rejection_notes if reason_for_rejection == "other"

    reason_for_rejection
  end

  def self.case_insensitive_name(name)
    where(["lower(problems.name) = :value", { value: name.downcase }])
  end

  private

  def must_be_rejected_if_rejected_reasons_present
    return if rejected?
    return unless reason_for_rejection.present? || rejection_notes.present?

    errors.add(:approval_status, "must be rejected if a reason for rejection is present")
  end

  def must_have_meaningful_reason_for_rejection
    return unless reason_for_rejection == "other" && rejection_notes.blank?

    errors.add(:rejection_notes, "must be added if the reason for rejection is \"other\"")
  end
end
