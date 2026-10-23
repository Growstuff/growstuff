# frozen_string_literal: true

# Makes jobs for a planting from a crop job template: one for each step that
# falls today or later. A step the planting already has a job for is not made
# again, so applying a template twice does nothing the second time. A step
# repeating weekly, fortnightly or monthly is made once, for its first day.
class ApplyCropJobTemplate
  def initialize(template, planting, today: Time.zone.today)
    @template = template
    @planting = planting
    @today = today
  end

  # The jobs made, in the order of the template's steps.
  def call
    return [] if @planting.planted_at.blank?

    entries.filter_map { |entry| create_job(entry) }
  end

  private

  def entries
    schedule = CropJobSchedule.new(@template, planting_out_on: @planting.planted_at.to_date, today: @today)
    schedule.entries.select { |entry| entry.date && !entry.past? && applied_step_ids.exclude?(entry.step.id) }
  end

  # Steps of the template that already have a job for this planting.
  def applied_step_ids
    @applied_step_ids ||= Job.where(jobbable: @planting, crop_job_step: @template.steps).pluck(:crop_job_step_id)
  end

  def create_job(entry)
    Job.create!(name: entry.step.name, due_date: entry.date, owner: @planting.owner, garden: @planting.garden,
                jobbable: @planting, crop_job_step: entry.step)
  end
end
