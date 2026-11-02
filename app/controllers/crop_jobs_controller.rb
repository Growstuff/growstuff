# frozen_string_literal: true

# Adds a crop's step-by-step jobs to the signed-in member's jobs, from the crop's page.
class CropJobsController < ApplicationController
  before_action :authenticate_member!

  def create
    crop = Crop.find(params[:crop_slug])
    jobs = AddCropJobs.new(current_member, crop, planting: planting(crop)).call
    key = jobs.any? ? 'crop_jobs.added' : 'crop_jobs.already_added'
    redirect_to crop_path(crop), notice: t(key, count: jobs.size, crop: crop.name)
  end

  private

  # The planting chosen on the page, which has to be one of the member's of the crop or its varieties.
  def planting(crop)
    return if params[:planting_id].blank?

    AddCropJobs.new(current_member, crop).plantings.find(params[:planting_id])
  end
end
