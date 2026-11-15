# frozen_string_literal: true

# What a member knows about a planting they bought or were given as a seedling.
class PlantingSeedling < ApplicationRecord
  SOURCES = %w(shop nursery market gift unknown).freeze

  belongs_to :planting

  validates :source, allow_blank: true, inclusion: { in: SOURCES }
end
