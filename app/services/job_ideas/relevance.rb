# frozen_string_literal: true

class JobIdeas
  # Keep suggestions available even without the crop, but put jobs the member
  # can act on first. Names are a fallback for jobs without a linked crop.
  class Relevance
    def initialize(member)
      @member = member
    end

    def rank(ideas)
      ideas.each_with_index.sort_by { |idea, index| [-score(idea), index] }.map(&:first)
    end

    private

    def score(idea)
      crop_id = idea.crop&.id || crop_in(idea.name)
      return 0 unless crop_id

      if idea.kind == :past_planting || idea.name.match?(/\A\s*(?:plant|sow)\b/i)
        seed_crop_ids.include?(crop_id) ? 1 : -1
      else
        planting_crop_ids.include?(crop_id) ? 0 : -1
      end
    end

    def seed_crop_ids
      @seed_crop_ids ||= @member.seeds.current.pluck(:crop_id).to_set
    end

    def planting_crop_ids
      @planting_crop_ids ||= @member.plantings.active.pluck(:crop_id).to_set
    end

    # Prefer the longest name so "lemon grass" is not mistaken for "lemon".
    # Escape names, and match whole words, including the usual plural form.
    def crop_in(name)
      crop_patterns.find { |_, pattern| name.match?(pattern) }&.first
    end

    def crop_patterns
      @crop_patterns ||= Crop.pluck(:id, :name).sort_by { |_, name| -name.length }.map do |id, name|
        names = [name, name.pluralize].uniq.map { |form| Regexp.escape(form) }.join('|')
        [id, /\b(?:#{names})\b/i]
      end
    end
  end
end
