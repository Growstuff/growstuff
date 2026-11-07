# frozen_string_literal: true

# How much frost a plant takes. The words are the ones seed packets use, and suppliers use them loosely.
module Hardiness
  # From most to least sensitive.
  LEVELS = %w(tender half_hardy hardy).freeze
  UNKNOWN = 'unknown'
  VALUES = [*LEVELS, UNKNOWN].freeze

  # The level most often given, from a hash of level => count. A tie goes to the more tender one, as a
  # gardener would rather be warned. UNKNOWN when none is given.
  def self.most_common(counts)
    given = counts.slice(*LEVELS).select { |_level, count| count.positive? }
    return UNKNOWN if given.empty?

    given.max_by { |level, count| [count, -LEVELS.index(level)] }.first
  end
end
