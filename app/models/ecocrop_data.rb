# frozen_string_literal: true

class EcocropData < ApplicationRecord
  has_many :crops, inverse_of: :ecocrop_record, dependent: :nullify

  validates :ecoportcode, presence: true, uniqueness: true
  validates :scientificname, presence: true

  # The figures a heat estimate needs: the lowest temperature the crop grows at, its optimal range,
  # and the shortest and longest growing cycle in days.
  HEAT_FIELDS = %i(tmin topmn topmx gmin gmax).freeze

  scope :matched, -> { where(id: Crop.where.not(ecocrop_data_id: nil).select(:ecocrop_data_id)) }
  scope :unmatched, -> { where.not(id: Crop.where.not(ecocrop_data_id: nil).select(:ecocrop_data_id)) }

  # Records whose scientific name or any common name contains the text.
  scope :search, lambda { |text|
    pattern = "%#{sanitize_sql_like(text.to_s.strip)}%"
    where('scientificname ILIKE :pattern OR array_to_string(comname, \' \') ILIKE :pattern', pattern:)
  }

  def self.by_scientific_name(name)
    return nil if name.blank?

    cleaned = name.to_s.strip
    where('lower(scientificname) = lower(?)', cleaned).first
  end

  # Whether there is enough here to estimate the heat a crop needs. EcoCrop records some crops'
  # growing cycles as 0 days, which is a gap in the data and not a crop that is ready at once.
  def heat_data?
    HEAT_FIELDS.all? { |field| self[field].present? } && gmin.positive? && gmax.positive? && optimal_temp > tmin
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
