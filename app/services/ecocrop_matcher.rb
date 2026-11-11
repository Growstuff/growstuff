# frozen_string_literal: true

# Finds the EcoCrop record for each crop from its scientific names, trying the surest match first:
#   exact    the whole name, ignoring case and subsp./var. spelling
#   species  the genus and species, whatever follows (author, variety, cultivar)
#   synonym  the genus and species of one of EcoCrop's synonyms
# A crop with no scientific name can only be matched by its common name, which is a suggestion for a person to confirm.
class EcocropMatcher
  LINKABLE_METHODS = %i(exact species synonym).freeze

  Match = Struct.new(:crop, :how, :candidates, keyword_init: true) do
    # Only a single, sure candidate is linked without anyone looking at it.
    def linkable?
      LINKABLE_METHODS.include?(how) && candidates.one?
    end

    def record
      candidates.first if linkable?
    end
  end

  NOT_A_SPECIES = %w(sp spp genus group species).freeze

  # "Rubus x loganobaccus L.H. Bailey" => "rubus loganobaccus"; nil when there is no species, as in "Citrus" or "Sorghum spp.".
  def self.binomial(name)
    words = name.to_s.downcase.tr('×', ' ').split
    words.delete_at(1) if words[1] == 'x'
    genus, species = words
    return unless genus&.match?(/\A[a-z]+\z/) && species&.match?(/\A[a-z-]+\z/)
    return if NOT_A_SPECIES.include?(species)

    "#{genus} #{species}"
  end

  # The whole name in one spelling, so "subspecies" and "ssp." both read "subsp.".
  def self.normalise(name)
    name.to_s.downcase.squish.gsub(/\b(subspecies|ssp\.?)(?=\s)/, 'subsp.').gsub(/\bvariety\b/, 'var.')
  end

  def initialize(crops: Crop.where(ecocrop_data_id: nil))
    @crops = crops
  end

  def call
    @crops.includes(:scientific_names).order(:id).map { |crop| match(crop) }
  end

  private

  def match(crop)
    names = crop.scientific_names.map(&:name)
    return by_common_name(crop) if names.empty?

    tiers(names).each do |how, ids|
      ids = ids.uniq
      return Match.new(crop:, how:, candidates: records.values_at(*ids)) if ids.one?
      return Match.new(crop:, how: :ambiguous, candidates: records.values_at(*ids)) if ids.any?
    end
    Match.new(crop:, how: :none, candidates: [])
  end

  def tiers(names)
    binomials = names.filter_map { |name| self.class.binomial(name) }.uniq
    {
      exact:   names.flat_map { |name| exact_index[self.class.normalise(name)] },
      species: species_ids(binomials),
      synonym: binomials.flat_map { |binomial| synonym_index[binomial] }
    }
  end

  # Of several records for one species, the plain species wins over its varieties.
  def species_ids(binomials)
    ids = binomials.flat_map { |binomial| species_index[binomial] }.uniq
    return ids if ids.one?

    plain = ids.select { |id| binomials.include?(records[id].scientificname.downcase.squish) }
    plain.one? ? plain : ids
  end

  def by_common_name(crop)
    ids = common_name_index[crop.name.downcase.squish].uniq
    Match.new(crop:, how: ids.any? ? :common_name : :none, candidates: records.values_at(*ids))
  end

  def records
    @records ||= EcocropData.all.index_by(&:id)
  end

  def exact_index
    @exact_index ||= index { |record| [self.class.normalise(record.scientificname)] }
  end

  def species_index
    @species_index ||= index { |record| [self.class.binomial(record.scientificname)] }
  end

  def synonym_index
    @synonym_index ||= index { |record| Array(record.syno).map { |name| self.class.binomial(name) } }
  end

  def common_name_index
    @common_name_index ||= index { |record| record.common_names.map(&:downcase) }
  end

  def index
    records.each_value.with_object(Hash.new { |hash, key| hash[key] = [] }) do |record, result|
      yield(record).compact.each { |key| result[key] << record.id }
    end
  end
end
