# frozen_string_literal: true

# Published templates for the crops a member is growing, as long as there is
# something left in them to add to that planting.
class JobIdeas
  class Templates
    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      plantings.flat_map do |planting|
        CropJobTemplate.published.for_crop(planting.crop).includes(:steps).filter_map { |template| idea_for(template, planting) }
      end
    end

    private

    def plantings
      @member.plantings.active.where.not(planted_at: nil).includes(:crop)
    end

    def idea_for(template, planting)
      pending = ApplyCropJobTemplate.new(template, planting, today: @today).pending
      return if pending.empty?

      Idea.new(kind: :template, key: "template:#{template.id}:#{planting.id}", name: template.name, crop: planting.crop,
               planting:, template:, job_count: pending.size)
    end
  end
end
