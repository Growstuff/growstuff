# frozen_string_literal: true

# A member's garden stall: one page where they offer spare seedlings and seeds
# to friends. A member has at most one. It is open when it has an opened_at, and
# closing it keeps the row so opening it again is just a timestamp.
class Stall < ApplicationRecord
  # What a seed is marked as being traded to when it goes on the stall without
  # being marked as tradable already.
  WILL_TRADE = 'locally'

  # How far from the owner a friend can be and still claim: near them (as
  # far as Neighbours counts as their region), or anywhere.
  enum :claim_area, { region: 'region', anywhere: 'anywhere' }, default: :region, validate: true
  NEARBY_KM = Neighbours::RADII_KM.last

  belongs_to :member
  has_many :stall_seeds, dependent: :destroy
  # The packets on the table: not given away, though they may be claimed.
  has_many :seeds, -> { current }, through: :stall_seeds
  # Plantings given away from here, newest first, whether or not they have been accepted into a garden yet.
  has_many :stall_plantings, -> { newest_first }, dependent: :destroy, inverse_of: :stall

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

  # Puts packets on the stall, as free or as a swap. A packet that isn't marked "will trade" is, so
  # what friends see on the stall matches what they see in the seed library.
  def put_seeds_on!(packets, offer: :free)
    transaction do
      packets.each do |seed|
        seed.update!(tradable_to: WILL_TRADE) unless seed.tradable
        stall_seeds.find_or_create_by!(seed:) { |stall_seed| stall_seed.offer = offer }
      end
    end
  end

  # Puts seedlings on the stall with nobody to give them to yet. They stay the member's active plantings. A count for
  # a planting, by its id, offers only that many of the batch, as a planting of its own.
  def offer_seedlings!(plantings, quantities: {})
    transaction do
      plantings.map do |planting|
        stall_plantings.unaccepted.find_or_create_by!(planting: portion_of(planting, quantities))
      end
    end
  end

  # The packets on the table, as offered on the stall, and the ones given away since.
  def stall_seeds_on_table
    stall_seeds.where(seed_id: Seed.current.select(:id))
  end

  def stall_seeds_given_away
    stall_seeds.where(seed_id: Seed.given_away.select(:id))
  end

  # The seedlings on offer that are still the member's to give: not finished, failed or given since.
  def seedlings_on_offer
    stall_plantings.offered.where(planting_id: Planting.current.select(:id)).includes(planting: :crop)
  end

  # Gives plantings away to one person, on the day given, whether or not they were on offer: each leaves the member's
  # active plantings at once, and is kept here with who it went to. `to` says who: recipient_member, recipient_name, and
  # the recipient_kind and recipient (an address or handle) they sign in with, if known. A count for a planting, by its
  # id, gives only that many of the batch. All or none: if one can't be given, nothing is, and the error is on the
  # record that failed.
  def give_away!(plantings, to:, on: Time.zone.now, quantities: {})
    transaction do
      plantings.map do |planting|
        stall_plantings.unaccepted.find_or_initialize_by(planting: portion_of(planting, quantities)).tap do |record|
          record.update!(**to, given_away_at: on)
        end
      end
    end
  end

  # Where friends can be, as friends read it: "Wellington", or nil for anywhere.
  def area_name
    member.location_place if region?
  end

  # Whether a friend is in the area the owner has chosen:
  #   :ok             they are
  #   :outside        their profile puts them somewhere else
  #   :ask            their profile doesn't say, so they say it themselves
  #   :owner_unplaced the owner hasn't said where they are, so it can't be checked
  def area_check(friend)
    return :ok if anywhere?
    return :owner_unplaced unless member.located?
    return :ask unless friend.located?

    near?(friend) ? :ok : :outside
  end

  private

  def portion_of(planting, quantities)
    count = quantities[planting.id.to_s].to_i
    count.positive? ? planting.split_off(count) : planting
  end

  def near?(friend)
    Geocoder::Calculations.distance_between([member.latitude, member.longitude], [friend.latitude, friend.longitude],
                                            units: :km) <= NEARBY_KM
  end
end
