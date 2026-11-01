# frozen_string_literal: true

# A member's garden stall: one page where they offer spare seedlings and seeds
# to friends. A member has at most one. It is open when it has an opened_at, and
# closing it keeps the row so opening it again is just a timestamp.
class Stall < ApplicationRecord
  # What a seed is marked as being traded to when it goes on the stall without
  # being marked as tradable already.
  WILL_TRADE = 'locally'

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

  # Puts packets on the stall. A packet that isn't marked "will trade" is, so
  # what friends see on the stall matches what they see in the seed library.
  def put_seeds_on!(packets)
    transaction do
      packets.each do |seed|
        seed.update!(tradable_to: WILL_TRADE) unless seed.tradable
        stall_seeds.find_or_create_by!(seed:)
      end
    end
  end
end
