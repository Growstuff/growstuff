# frozen_string_literal: true

# Plantings of a member's that are ready to harvest: the first harvest is expected
# by now, or they have been harvested from, but not in the last week. As Planting
# says it, annual crops only. A planting with nothing to say when it is ready is
# not suggested.
class JobIdeas
  class Harvest
    RECENTLY = 7.days

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      plantings.filter_map { |planting| idea_for(planting) }
    end

    private

    def plantings
      @member.plantings.active.annual.where.not(planted_at: nil).preload(:crop, :harvests)
    end

    def idea_for(planting)
      return if to_harvest.include?(planting.id)

      last = last_harvest(planting)
      return if last && last > @today - RECENTLY

      expected = expected_on(planting)
      return unless last || (expected && expected < @today)

      Idea.new(kind: :harvest, key: "harvest:#{planting.id}", name: planting.crop.name, crop: planting.crop, planting:,
               on: last || expected, period: last ? :harvested : :predicted)
    end

    # The plantings they already have an open job to harvest.
    def to_harvest
      @to_harvest ||= @member.jobs.active.action_harvest.where(jobbable_type: 'Planting').pluck(:jobbable_id)
    end

    def last_harvest(planting)
      planting.harvests.filter_map(&:harvested_at).max&.to_date
    end

    def expected_on(planting)
      days = planting.crop.median_days_to_first_harvest
      planting.planted_at.to_date + days.days if days
    end
  end
end
