# frozen_string_literal: true

# Adds a crop's published job templates to a member's jobs. With a planting of the
# crop (or a variety of it) the jobs fall on the days its template says, as when
# they are offered as ideas. Without one there is no day to count from, so each
# step becomes a job under Some day, to be given a day when the member plants.
# Adding again makes no job twice.
class AddCropJobs
  def initialize(member, crop, today: Time.zone.today)
    @member = member
    @crop = crop
    @today = today
  end

  # The jobs made.
  def call
    templates.flat_map { |template| planting ? from_planting(template) : from_crop(template) }
  end

  # Whether a call would make any jobs: false once the member has them all, or when there are none to add.
  def pending?
    templates.any? { |template| planting ? planting_entries(template).any? : steps_without_jobs(template).any? }
  end

  private

  def templates
    CropJobTemplate.published.for_crop(@crop).includes(:steps).order(:name)
  end

  # The member's latest planting of the crop that has a day to count from.
  def planting
    return @planting if defined?(@planting)

    @planting = @member.plantings.active.where.not(planted_at: nil)
      .where(crop_id: [@crop.id, *@crop.varieties.select(:id)]).order(planted_at: :desc, id: :desc).first
  end

  def from_planting(template)
    ApplyCropJobTemplate.new(template, planting, today: @today).call
  end

  def planting_entries(template)
    ApplyCropJobTemplate.new(template, planting, today: @today).pending
  end

  def from_crop(template)
    steps_without_jobs(template).map do |step|
      @member.jobs.create!(name: step.name, jobbable: @crop, crop_job_step: step)
    end
  end

  def steps_without_jobs(template)
    done = Job.where(owner: @member, jobbable: @crop, crop_job_step: template.steps).pluck(:crop_job_step_id)
    template.steps.reject { |step| done.include?(step.id) }
  end
end
