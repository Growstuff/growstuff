# frozen_string_literal: true

# A garden a planting used to be in, and the days it was there. The planting
# itself says which garden it is in now.
class PlantingHistory < ApplicationRecord
  belongs_to :planting
  belongs_to :garden

  validates :ended_on, presence: true

  # The garden the planting moved into: where the next history says it was, or
  # where it is now.
  def moved_to
    later = planting.histories.find { |other| ([other.ended_on, other.id] <=> [ended_on, id || 0]).positive? }
    (later || planting).garden
  end
end
