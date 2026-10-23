# frozen_string_literal: true

# Makes the jobs for an idea a member said yes to. A template makes its steps. The
# rest make one job under Some day, so the member picks the day: a job to plant or
# harvest remembers that it is for that.
class JobIdeas
  class Add
    def initialize(member, idea, today: Time.zone.today)
      @member = member
      @idea = idea
      @today = today
    end

    # The jobs made.
    def call
      case @idea.kind
      when :template then add_template
      when :past_planting then [make(I18n.t('job_ideas.job.plant', crop: @idea.crop.name), @idea.crop, action: 'plant')]
      when :harvest then [harvest_job]
      else [make(@idea.name, @idea.crop)]
      end
    end

    private

    # The template's jobs for the planting. Then the idea is put away, or the
    # template would come back for the next planting of the crop.
    def add_template
      jobs = ApplyCropJobTemplate.new(@idea.template, @idea.planting, today: @today).call
      JobIdeaDismissal.hide!(@member, @idea.key)
      jobs
    end

    def harvest_job
      make(I18n.t('job_ideas.job.harvest', crop: @idea.crop.name), @idea.planting, action: 'harvest', garden: @idea.planting.garden)
    end

    def make(name, jobbable, **attributes)
      @member.jobs.create!(name:, jobbable:, **attributes)
    end
  end
end
