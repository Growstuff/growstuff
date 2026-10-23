# frozen_string_literal: true

# Published templates for the crops a member is growing, as long as there is
# something left in them to add to a planting. One idea for a template, however
# many plantings could have it: it is for the latest planting. The idea carries
# the jobs it would add, with their days, so they can be seen first.
class JobIdeas
  class Templates
    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      by_template.map do |template, found|
        planting, entries = found.max_by { |planting, _entries| [planting.planted_at, planting.id] }
        Idea.new(kind: :template, key: "template:#{template.id}", name: template.name, crop: template.crop, planting:, template:,
                 schedule: entries, job_count: entries.size, on: planting.planted_at.to_date)
      end
    end

    private

    # For each template, the plantings it still has jobs to add to, and those jobs.
    def by_template
      plantings.each_with_object(Hash.new { |hash, template| hash[template] = {} }) do |planting, found|
        CropJobTemplate.published.for_crop(planting.crop).includes(:steps, :crop).find_each do |template|
          entries = ApplyCropJobTemplate.new(template, planting, today: @today).pending
          found[template][planting] = entries if entries.any?
        end
      end
    end

    def plantings
      @member.plantings.active.where.not(planted_at: nil).includes(:crop)
    end
  end
end
