# frozen_string_literal: true

# What gardeners near a member have been doing, now and at this time of year
# before, whatever the crop.
class JobIdeas
  class Nearby < OthersJobs
    RADIUS_KM = 25

    private

    def owner_ids
      @owner_ids ||= if @member.latitude && @member.longitude
                       Member.confirmed.located.near([@member.latitude, @member.longitude], RADIUS_KM, units: :km).reorder(nil).pluck(:id)
                     else
                       []
                     end
    end

    def kind
      :nearby
    end
  end
end
