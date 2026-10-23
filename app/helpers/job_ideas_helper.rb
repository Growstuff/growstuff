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
    when :template then t('job_ideas.reason.template', count: idea.schedule.size, steps: job_idea_steps(idea), crop: idea.crop.name, day:)
    when :past_job, :past_planting then t("job_ideas.reason.#{idea.kind}", count: idea.years, day:)
    when :harvest then t("job_ideas.reason.harvest_#{idea.period}", day:)
    else community_reason(idea, day)
    end
  end

  # The sections of the ideas, in order: the kinds of idea each holds.
  JOB_IDEA_SECTIONS = {
    templates: %i(template), this_time: %i(past_job past_planting), harvest: %i(harvest),
    community: %i(community), nearby: %i(nearby), world: %i(world)
  }.freeze

  # The shown ideas under their sections, those with none left out.
  def job_idea_sections(ideas)
    JOB_IDEA_SECTIONS.filter_map do |section, kinds|
      found = ideas.select { |idea| kinds.include?(idea.kind) }
      [section, found] if found.any?
    end
  end

  # What a section says after its heading. Nearby is named for where the member is.
  def job_idea_section_note(section, member)
    place = member.location.to_s.split(',').first.to_s.strip
    return t('job_ideas.section.nearby_note', place:) if section == :nearby && place.present?

    t("job_ideas.section.#{section}_note")
  end

  # The path to the page with a source switched on or off, keeping the others.
  def job_idea_switch_path(name, skipped)
    job_ideas_path(skip: skipped.include?(name) ? skipped - [name] : skipped + [name])
  end

  private

  def job_idea_steps(idea)
    idea.template.steps.first(5).map { |step| step.name.downcase }.join(', ')
  end

  def community_reason(idea, day)
    key = idea.of ? "#{idea.kind}_of" : idea.kind
    t("job_ideas.reason.#{key}.#{idea.period}", count: idea.gardeners, of: idea.of, crop: idea.crop&.name, day:)
  end
end
