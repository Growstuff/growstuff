# frozen_string_literal: true

# A suggested job a member hid, until a time. "Not for me" hides it for a year,
# so it can come back with the season. Snoozing hides it for less.
class JobIdeaDismissal < ApplicationRecord
  DISMISSED_FOR = 1.year
  SNOOZES = { 'week' => 1.week, 'month' => 1.month }.freeze

  belongs_to :member

  validates :key, presence: true, uniqueness: { scope: :member_id }
  validates :hidden_until, presence: true

  scope :hiding, -> { where(hidden_until: Time.zone.now..) }

  # Hides the idea from now for as long as given, replacing any earlier hiding.
  def self.hide!(member, key, for_how_long = DISMISSED_FOR)
    dismissal = find_or_initialize_by(member:, key:)
    dismissal.update!(hidden_until: for_how_long.from_now)
    dismissal
  end

  def self.dismiss!(member, key)
    hide!(member, key)
  end

  # For one of SNOOZES, named.
  def self.snooze!(member, key, length)
    hide!(member, key, SNOOZES.fetch(length))
  end
end
