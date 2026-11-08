# frozen_string_literal: true

# Adds a crop's step-by-step jobs to the signed-in member's jobs, from the crop's
# page. For a planting the member has, the page's menu adds them straight away. For
# one they mean to do, the page's dialog asks which day they will plant, and warns
# there if that is out of season.
class CropJobsController < ApplicationController
  before_action :authenticate_member!

  def create
    crop = Crop.find(params[:crop_slug])
    adder = AddCropJobs.new(current_member, crop)
    planting = adder.plantings.find(params[:planting_id]) if params[:planting_id].present?
    jobs = AddCropJobs.new(current_member, crop, planting:, planting_on: parse_date(params[:planting_on])).call
    key = jobs.any? ? 'crop_jobs.added' : 'crop_jobs.already_added'
    redirect_to crop_path(crop), notice: t(key, count: jobs.size, crop: crop.name)
  end

  private

  # The day the member plans to plant on, if they said and it is a date.
  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
