# frozen_string_literal: true

class PlantingProblem < ApplicationRecord
  include PhotoCapable

  belongs_to :planting
  belongs_to :problem
end
