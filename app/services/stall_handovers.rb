# frozen_string_literal: true

# What is waiting on a member to confirm, in the stall handovers that take both people: things they were given, which they
# say they received, and things they gave, which the person who claimed them says they collected.
class StallHandovers
  def initialize(member)
    @member = member
  end

  # Seedlings given to them, to accept into a garden.
  def seedlings_to_receive
    StallPlanting.waiting_for(@member).includes(planting: :crop, stall: :member).newest_first
  end

  # Packets of seed the giver says they handed over, for them to say they received.
  def seeds_to_receive
    Claim.where(member: @member, completed_at: nil).where.not(given_at: nil).where.not(stall_seed_id: nil)
      .includes(stall_seed: [{ seed: :crop }, { stall: :member }])
  end

  # Claims on their own stall that the claimer says they collected, for them to confirm they handed over.
  def to_give
    return Claim.none unless @member.stall

    Claim.where(completed_at: nil, given_at: nil).where.not(received_at: nil)
      .where(stall_seed_id: @member.stall.stall_seeds.select(:id)).or(
        Claim.where(completed_at: nil, given_at: nil).where.not(received_at: nil)
          .where(stall_planting_id: @member.stall.stall_plantings.select(:id))
      )
  end

  def to_receive_count
    seedlings_to_receive.count + seeds_to_receive.count
  end
end
