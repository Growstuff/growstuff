# frozen_string_literal: true

# Annual crops a member planted in the next two weeks of a year ago, and has not
# planted since. A crop planted more than once is one idea, for the first time.
class JobIdeas
  class PlantedLastYear
    WINDOW = 14.days

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      planted.uniq(&:crop_id).filter_map do |planting|
        next if planted_since.include?(planting.crop_id)

        Idea.new(kind: :planted_last_year, key: "planted_last_year:#{planting.crop_id}", name: planting.crop.name,
                 crop: planting.crop, planting:, on: planting.planted_at)
      end
    end

    private

    def planted
      from = @today - 1.year
      @member.plantings.annual.where.not(failed: true).where(planted_at: from..(from + WINDOW)).includes(:crop).order(:planted_at)
    end

    # The crops they have planted since that fortnight, so are already growing.
    def planted_since
      @planted_since ||= @member.plantings.where(planted_at: (@today - 1.year + WINDOW + 1.day)..).pluck(:crop_id)
    end
  end
end
