# frozen_string_literal: true

# What other gardeners growing the crops a member grows have been doing, now and
# at this time of year before.
class JobIdeas
  class Community < OthersJobs
    private

    def owner_ids
      Member.confirmed.pluck(:id)
    end

    def crop_ids
      @crop_ids ||= @member.plantings.current.distinct.pluck(:crop_id)
    end

    def kind
      :community
    end

    def growing(crop)
      return unless crop

      growers[crop.id] || 0
    end

    def growers
      @growers ||= Planting.current.where(crop_id: crop_ids).where.not(owner_id: left_out_ids).group(:crop_id).distinct.count(:owner_id)
    end
  end
end
