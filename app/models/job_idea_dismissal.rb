# frozen_string_literal: true

# A suggested job a member said was not for them. It stays hidden for a month.
class JobIdeaDismissal < ApplicationRecord
  HIDDEN_FOR = 1.month

  belongs_to :member

  validates :key, presence: true, uniqueness: { scope: :member_id }

  scope :hiding, -> { where(updated_at: HIDDEN_FOR.ago..) }

  # Hides the idea again from now, if it was dismissed before.
  def self.dismiss!(member, key)
    dismissal = find_or_initialize_by(member:, key:)
    dismissal.updated_at = Time.zone.now
    dismissal.save!
    dismissal
  end
end
