# frozen_string_literal: true

# Annual crops a member planted at this time of year in earlier years, and has not
# planted since. A crop planted in several years is one idea, dated the latest
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
        next if planted_since.include?(crop_id)

        latest = plantings.max_by(&:planted_at)
        Idea.new(kind: :past_planting, key: "past_planting:#{crop_id}", name: latest.crop.name, crop: latest.crop,
                 planting: latest, on: latest.planted_at, years: plantings.map { |planting| planting.planted_at.year }.uniq.size)
      end
    end

    private

    def planted
      plantings = @member.plantings.annual.where.not(failed: true).includes(:crop)
      past_windows.map { |window| plantings.where(planted_at: window) }.reduce(:or)
    end

    # The crops they have planted since the last fortnight, so are already growing.
    def planted_since
      @planted_since ||= @member.plantings.where(planted_at: (@today - 1.year + WINDOW + 1.day)..).pluck(:crop_id)
    end
  end
end
