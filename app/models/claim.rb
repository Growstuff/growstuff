# frozen_string_literal: true

# A friend claiming a packet on a garden stall. It is theirs straight away, and
# only one friend can have a packet at a time.
class Claim < ApplicationRecord
  belongs_to :stall_seed
  belongs_to :member

  # Ticked by a friend whose profile doesn't say where they are: "I'm in
  # Wellington". Taken on trust.
  attr_accessor :here

  validates :note, length: { maximum: 500 }
  validates :stall_seed_id, uniqueness: true
  validate :stall_is_open
  validate :member_is_not_the_stall_owner
  validate :member_is_in_the_area

  private

  def member_is_in_the_area
    return if member.blank? || stall_seed.blank? || member == stall_seed.stall.member

    case stall_seed.stall.area_check(member)
    when :outside then errors.add(:base, :outside_area, place: stall_seed.stall.area_name)
    when :owner_unplaced then errors.add(:base, :owner_unplaced)
    when :ask then errors.add(:base, :not_confirmed_in_area, place: stall_seed.stall.area_name) unless here.to_s == '1'
    end
  end

  def stall_is_open
    errors.add(:base, :stall_closed) unless stall_seed&.stall&.open?
  end

  def member_is_not_the_stall_owner
    errors.add(:member, :cannot_be_stall_owner) if member.present? && member == stall_seed&.stall&.member
  end
end
