# frozen_string_literal: true

# A friend claiming a packet of seed or an offered seedling on a garden stall: it is reserved for them, and only one friend
# can have each at a time.
#
# Handing it over then takes both people. The claimer says they collected it, and the giver says they handed it over, in
# either order. When both have, the original stays with the giver, marked as given away, and a new record is made for the
# claimer that knows where it came from.
class Claim < ApplicationRecord
  belongs_to :stall_seed, optional: true
  belongs_to :stall_planting, optional: true
  belongs_to :member
  # Where the claimer will put a seedling, said when they collect it.
  belongs_to :receiving_garden, class_name: 'Garden', optional: true

  # Ticked by a friend whose profile doesn't say where they are: "I'm in
  # Wellington". Taken on trust.
  attr_accessor :here

  validates :note, length: { maximum: 500 }
  validates :stall_seed_id, uniqueness: true, allow_nil: true
  validates :stall_planting_id, uniqueness: true, allow_nil: true
  validate :for_a_packet_or_a_seedling
  validate :seedling_is_still_on_offer, on: :create
  validate :stall_is_open, on: :create
  validate :member_is_not_the_stall_owner, on: :create
  validate :member_is_in_the_area, on: :create

  # What was claimed: the packet, or the seedling.
  def item
    stall_seed || stall_planting
  end

  def stall
    item&.stall
  end

  def given?
    given_at.present?
  end

  def received?
    received_at.present?
  end

  def completed?
    completed_at.present?
  end

  # They can only give it back before the giver has handed it over.
  def undoable?
    !given? && !completed?
  end

  # The claimer says they collected it; for a seedling, which of their gardens it goes into. If the giver has already said
  # they handed it over, that completes it. Returns whether it was saved; if not, the errors say why.
  def receive(garden = nil)
    return fail_with(:already_completed) if completed?
    return fail_with(:not_your_garden) if stall_planting.present? && garden&.owner_id != member_id

    transaction do
      update!(received_at: Time.current, receiving_garden: garden)
      hand_over(garden) if given?
    end
    true
  end

  # The giver says they handed it over: it leaves their active records now. If the claimer has already said they collected
  # it, that completes it. Returns whether it was saved; if not, the errors say why.
  def give
    return fail_with(:already_completed) if completed?

    transaction do
      update!(given_at: Time.current)
      take_off_owner
      hand_over(receiving_garden) if received?
    end
    true
  end

  # Both have said so: the claimer has their own record now.
  def finish!
    update!(received_at: received_at || Time.current, completed_at: Time.current)
  end

  private

  def fail_with(key) # rubocop:disable Naming/PredicateMethod
    errors.add(:base, key)
    false
  end

  # The packet or seedling is the giver's no longer.
  def take_off_owner
    if stall_planting
      stall.give_away!([stall_planting.planting], to: { recipient_member: member })
    else
      stall_seed.seed.update_columns(given_away_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # A new packet, or planting, for the claimer.
  def hand_over(garden)
    if stall_planting
      stall_planting.reload.accept(member, garden)
    else
      stall_seed.seed.pass_on_to(member)
      finish!
    end
  end

  def for_a_packet_or_a_seedling
    errors.add(:base, :one_item_required) unless stall_seed.present? ^ stall_planting.present?
  end

  # A seedling that has been given to someone is no longer there to ask for.
  def seedling_is_still_on_offer
    errors.add(:base, :no_longer_offered) if stall_planting.present? && !stall_planting.offered?
  end

  def member_is_in_the_area
    return if member.blank? || stall.blank? || member == stall.member

    case stall.area_check(member)
    when :outside then errors.add(:base, :outside_area, place: stall.area_name)
    when :owner_unplaced then errors.add(:base, :owner_unplaced)
    when :ask then errors.add(:base, :not_confirmed_in_area, place: stall.area_name) unless here.to_s == '1'
    end
  end

  def stall_is_open
    errors.add(:base, :stall_closed) unless stall&.open?
  end

  def member_is_not_the_stall_owner
    errors.add(:member, :cannot_be_stall_owner) if member.present? && member == stall&.member
  end
end
