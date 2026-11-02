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
  has_many :seeds, through: :stall_seeds

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

  def near?(friend)
    Geocoder::Calculations.distance_between([member.latitude, member.longitude], [friend.latitude, friend.longitude],
                                            units: :km) <= NEARBY_KM
  end
end
