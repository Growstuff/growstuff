# frozen_string_literal: true

# How much frost a plant takes. The words are the ones seed packets use, and suppliers use them loosely, so the
# temperatures here are a draft, loosely after the RHS hardiness ratings, to agree with growers.
module Hardiness
  # From most to least sensitive.
  LEVELS = %w(tender half_hardy hardy).freeze
  UNKNOWN = 'unknown'
  VALUES = [*LEVELS, UNKNOWN].freeze

  # A plant whose lowest tolerated temperature is above this is tender: a frost damages it.
  TENDER_ABOVE_C = -1.0
  # One that tolerates colder than this is hardy. Between the two, a light frost is fine.
  HARDY_BELOW_C = -5.0

  # The level for the lowest temperature a plant tolerates, in degrees C.
  def self.from_lowest_c(degrees)
    return UNKNOWN if degrees.nil?
    return 'tender' if degrees > TENDER_ABOVE_C
    return 'hardy' if degrees < HARDY_BELOW_C

    'half_hardy'
  end

  # The level most often given, from a hash of level => count. A tie goes to the more tender one, as a
  # gardener would rather be warned. UNKNOWN when none is given.
  def self.most_common(counts)
    given = counts.slice(*LEVELS).select { |_level, count| count.positive? }
    return UNKNOWN if given.empty?

    given.max_by { |level, count| [count, -LEVELS.index(level)] }.first
  end
end
