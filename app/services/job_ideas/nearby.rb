# frozen_string_literal: true

# What gardeners near a member have been doing, now and at this time of year
# before, whatever the crop. Starts close and widens until there are enough
# gardeners to see a trend.
class JobIdeas
  class Nearby < OthersJobs
    RADII_KM = [25, 50, 100, 250, 500].freeze
    # How many gardeners to widen the search until there are.
    ENOUGH = 10

    private

    def owner_ids
      @owner_ids ||= if @member.latitude && @member.longitude
                       within_distance
                     else
                       []
                     end
    end

    def within_distance
      found = []
      RADII_KM.each do |radius|
        found = others.near([@member.latitude, @member.longitude], radius, units: :km).reorder(nil).pluck(:id)
        return found if found.size >= ENOUGH
      end
      found
    end

    def others
      Member.confirmed.located.where.not(id: @member.id)
    end

    def kind
      :nearby
    end
  end
end
