# frozen_string_literal: true

# A friend claiming a packet on a garden stall. It is theirs straight away, and
# only one friend can have a packet at a time.
class Claim < ApplicationRecord
  belongs_to :stall_seed
  belongs_to :member

  validates :note, length: { maximum: 500 }
  validates :stall_seed_id, uniqueness: true
  validate :stall_is_open
  validate :member_is_not_the_stall_owner

  private

  def stall_is_open
    errors.add(:base, :stall_closed) unless stall_seed&.stall&.open?
  end

  def member_is_not_the_stall_owner
    errors.add(:member, :cannot_be_stall_owner) if member.present? && member == stall_seed&.stall&.member
  end
end
