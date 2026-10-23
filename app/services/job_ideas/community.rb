# frozen_string_literal: true

# What other gardeners growing the crops a member grows have been doing, now and
# at this time of year before. Only those in the same hemisphere, where it is the
# same time of year; nobody if the member has not said where they are.
class JobIdeas
  class Community < OthersJobs
    include SeasonsHelper

    private

    def owner_ids
      @owner_ids ||= case hemisphere(@member.latitude)
                     when :southern then Member.confirmed.located.where('latitude < 0').pluck(:id)
                     when :northern then Member.confirmed.located.where('latitude >= 0').pluck(:id)
                     else []
                     end
    end

    def crop_ids
      @crop_ids ||= @member.plantings.current.distinct.pluck(:crop_id)
    end

    def kind
      :community
    end

    def growing(crop_id)
      growers[crop_id] || 0 if crop_id
    end

    def growers
      @growers ||= Planting.current.where(crop_id: crop_ids).where.not(owner_id: left_out_ids).group(:crop_id).distinct.count(:owner_id)
    end
  end
end
