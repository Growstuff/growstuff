# frozen_string_literal: true

# A packet of seed from the member's library, offered on their stall.
class StallSeed < ApplicationRecord
  belongs_to :stall
  belongs_to :seed

  validates :seed_id, uniqueness: { scope: :stall_id }
  validate :seed_is_the_members

  private

  def seed_is_the_members
    errors.add(:seed, :invalid) unless seed&.owner_id == stall&.member_id
  end
end
