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

  # Records matching the text, best first: those with a common name that is exactly the text, then those with one that
  # starts with it, then the rest, each in order of scientific name.
  def self.best_matches(text, limit: 20)
    term = text.to_s.squish.downcase
    return [] if term.blank?

    search(term).order(:scientificname).limit(200).sort_by.with_index do |record, index|
      names = record.common_names.map(&:downcase)
      [match_rank(names, term), index]
    end.first(limit)
  end

  def self.match_rank(names, term)
    return 0 if names.include?(term)

    names.any? { |name| name.start_with?(term) } ? 1 : 2
  end
  private_class_method :match_rank

  # Crops not yet linked to any record whose name is one of an unmatched record's common names, ignoring case,
  # as { record id => crops }. A crop that already has a record is left alone, since linking would move it.
  def self.suggested_crops(records)
    candidates = records.select { |record| record.crops.empty? }
    names = candidates.flat_map { |record| Array(record.comname).map { |name| name.downcase.squish } }.uniq
    return {} if names.empty?

    crops = Crop.approved.where(ecocrop_data_id: nil).where('lower(name) IN (?)', names).group_by { |crop| crop.name.downcase.squish }
    found = candidates.to_h do |record|
      [record.id, Array(record.comname).filter_map { |name| crops[name.downcase.squish] }.flatten.uniq]
    end
    found.reject { |_id, matching| matching.empty? }
  end

  # The common names, tidied and without repeats ignoring case.
  def common_names
    Array(comname).map(&:squish).compact_blank.uniq(&:downcase)
  end

  # The common names this crop doesn't have yet, as its name or an alternate name, ignoring case.
  def new_common_names_for(crop)
    taken = [crop.name, *crop.alternate_names.map(&:name)].map { |name| name.downcase.squish }
    common_names.reject { |name| taken.include?(name.downcase) }
  end

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
