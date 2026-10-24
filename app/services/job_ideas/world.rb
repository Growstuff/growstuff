# frozen_string_literal: true

# What gardeners anywhere at a similar latitude to a member did at this time of
# year, in this year and in earlier ones. The same latitude, in the same
# hemisphere, is the same season, wherever in the world they are.
class JobIdeas
  class World < OthersJobs
    # Degrees of latitude either side of the member.
    BAND = 5

    private

    def owner_ids
      @owner_ids ||= if @member.latitude && @member.longitude
                       Member.confirmed.located.where.not(id: @member.id)
                         .where(latitude: (@member.latitude - BAND)..(@member.latitude + BAND))
                         .where(@member.latitude.positive? ? 'latitude > 0' : 'latitude <= 0').reorder(nil).pluck(:id)
                     else
                       []
                     end
    end

    # This year as well as the years before.
    def past_windows
      [(@today - BEFORE)..@today] + super
    end

    def kind
      :world
    end
  end
end
