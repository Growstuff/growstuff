# frozen_string_literal: true

module JobIdeasHelper
  # What an idea would add, as the member would read it.
  def job_idea_title(idea)
    case idea.kind
    when :past_planting then t('job_ideas.job.plant', crop: idea.crop.name)
    when :harvest then t('job_ideas.job.harvest', crop: idea.crop.name)
    else idea.name
    end
  end

  # Why an idea was suggested.
  def job_idea_reason(idea)
    day = idea.on && l(idea.on, format: '%-d %b')
    case idea.kind
    when :template then t('job_ideas.reason.template', count: idea.job_count, crop: idea.crop.name)
    when :past_job, :past_planting then t("job_ideas.reason.#{idea.kind}", count: idea.years, day:)
    when :harvest then t("job_ideas.reason.harvest_#{idea.period}", day:)
    else community_reason(idea, day)
    end
  end

  private

  def community_reason(idea, day)
    key = idea.of ? "#{idea.kind}_of" : idea.kind
    t("job_ideas.reason.#{key}.#{idea.period}", count: idea.gardeners, of: idea.of, crop: idea.crop&.name, day:)
  end
end
