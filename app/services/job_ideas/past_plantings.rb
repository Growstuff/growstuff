# frozen_string_literal: true

# Annual crops a member planted at this time of year in earlier years, and has not
# planted since last year's time. A crop planted in several years is one idea, dated the latest
# time.
class JobIdeas
  class PastPlantings
    include PastYears

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      planted.group_by(&:crop_id).filter_map do |crop_id, plantings|
        next if planted_since.include?(crop_id) || to_plant.include?(crop_id)

        latest = plantings.max_by(&:planted_at)
        years = plantings.map { |planting| planting.planted_at.year }.uniq.size
        Idea.new(kind: :past_planting, key: "past_planting:#{crop_id}", name: latest.crop.name, crop: latest.crop,
                 on: latest.planted_at, years:)
      end
    end

    private

    def planted
      plantings = @member.plantings.annual.where.not(failed: true).includes(:crop)
      past_windows.map { |window| plantings.where(planted_at: window) }.reduce(:or)
    end

    # The crops they already have an open job to plant.
    def to_plant
      @to_plant ||= @member.jobs.active.action_plant.where(jobbable_type: 'Crop').pluck(:jobbable_id)
    end

    # The crops they have planted since this time last year, so are already growing.
    def planted_since
      @planted_since ||= @member.plantings.where(planted_at: (@today - 1.year + AFTER + 1.day)..).pluck(:crop_id)
    end
  end
end
