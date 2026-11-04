# frozen_string_literal: true

# Adds a crop's published job templates to a member's jobs, either to a planting
# they already have or for a planting they mean to do. For a planting the jobs
# fall on the days its template says, as when they are offered as ideas. For one
# they mean to do, the member says which day they will plant, and the jobs are
# counted from that day: a job that would already be past is due today. Adding
# again makes no job twice.
class AddCropJobs
  # The day to suggest planting on: this Saturday, or the next one once it has gone.
  def self.default_planting_on(today = Time.zone.today)
    today.saturday? ? today : today.next_occurring(:saturday)
  end

  def initialize(member, crop, planting: nil, planting_on: nil, today: Time.zone.today)
    @member = member
    @crop = crop
    @planting = planting
    @today = today
    @planting_on = planting_on || self.class.default_planting_on(today)
  end

  # The member's plantings that have a day to count from, of the crop or of a
  # variety of it, the latest first.
  def plantings
    @member.plantings.active.where.not(planted_at: nil).where(crop_id: [@crop.id, *@crop.varieties.select(:id)])
      .includes(:crop, :garden).order(planted_at: :desc, id: :desc)
  end

  # Those of them that are still missing some of the jobs.
  def open_plantings
    plantings.select { |planting| self.class.new(@member, @crop, planting:, today: @today).pending? }
  end

  # The jobs made: for the planting given, or else for a planting to come.
  def call
    templates.flat_map { |template| @planting ? from_planting(template) : from_crop(template) }
  end

  # Whether a call would make any jobs. For no planting in particular, whether
  # there are any for a planting to come, or for one of the member's.
  def pending?
    return templates.any? { |template| planting_entries(template).any? } if @planting

    to_come? || open_plantings.any?
  end

  # Whether there are jobs still to add for a planting to come.
  def to_come?
    templates.any? { |template| steps_without_jobs(template).any? }
  end

  def templates
    @crop.published_job_templates.includes(:steps).order(:name)
  end

  private

  def from_planting(template)
    ApplyCropJobTemplate.new(template, @planting, today: @today).call
  end

  def planting_entries(template)
    ApplyCropJobTemplate.new(template, @planting, today: @today).pending
  end

  def from_crop(template)
    due = due_dates(template)
    steps_without_jobs(template).map do |step|
      @member.jobs.create!(name: step.name, due_date: due[step.id], jobbable: @crop, crop_job_step: step)
    end
  end

  # When each step is due, counting from the day of planting. A step with no day of
  # its own is left without one.
  def due_dates(template)
    entries = CropJobSchedule.new(template, planting_out_on: @planting_on, today: @today).entries
    entries.to_h { |entry| [entry.step.id, entry.date && [entry.date, @today].max] }
  end

  def steps_without_jobs(template)
    done = Job.where(owner: @member, jobbable: @crop, crop_job_step: template.steps).pluck(:crop_job_step_id)
    template.steps.reject { |step| done.include?(step.id) }
  end
end
