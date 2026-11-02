# frozen_string_literal: true

# A member's garden stall: one page where they offer spare seedlings and seeds
# to friends. A member has at most one. It is open when it has an opened_at, and
# closing it keeps the row so opening it again is just a timestamp.
class Stall < ApplicationRecord
  belongs_to :member

  validates :member_id, uniqueness: true

  def open?
    opened_at.present?
  end

  def open!
    update!(opened_at: Time.current)
  end

  def close!
    update!(opened_at: nil)
  end
end
