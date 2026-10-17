# frozen_string_literal: true

# A garden a planting used to be in, and the days it was there. The planting
# itself says which garden it is in now.
class PlantingHistory < ApplicationRecord
  belongs_to :planting
  belongs_to :garden

  validates :ended_on, presence: true
end
