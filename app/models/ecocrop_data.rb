# frozen_string_literal: true

class EcocropData < ApplicationRecord
  validates :ecoportcode, presence: true, uniqueness: true
  validates :scientificname, presence: true

  # The figures a heat estimate needs: the lowest temperature the crop grows at, its optimal range,
  # and the shortest and longest growing cycle in days.
  HEAT_FIELDS = %i(tmin topmn topmx gmin gmax).freeze

  def self.by_scientific_name(name)
    return nil if name.blank?

    cleaned = name.to_s.strip
    where('lower(scientificname) = lower(?)', cleaned).first
  end

  # Whether there is enough here to estimate the heat a crop needs.
  def heat_data?
    HEAT_FIELDS.all? { |field| self[field].present? } && optimal_temp > tmin
  end

  # The middle of the optimal temperature range, in °C.
  def optimal_temp
    (topmn + topmx) / 2.0
  end

  # The heat to a first harvest, in growing degree days: the shortest growing cycle, grown at the optimal
  # temperature, above the lowest temperature the crop grows at.
  def first_harvest_degree_days
    (optimal_temp - tmin) * gmin
  end
end
