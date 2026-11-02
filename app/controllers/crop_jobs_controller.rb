# frozen_string_literal: true

# Adds a crop's step-by-step jobs to the signed-in member's jobs, from the crop's
# page. For a planting the member has, the page's menu adds them straight away. For
# one they mean to do, the page's dialog asks which day they will plant, and warns
# there if that is out of season. Without script, #create asks again here.
class CropJobsController < ApplicationController
  before_action :authenticate_member!
  before_action :set_crop

  def create
    planting = chosen_planting
    planting_on = parse_date(params[:planting_on])
    @out_of_season = planting ? [] : out_of_season(planting_on || AddCropJobs.default_planting_on)
    return render_warning(planting_on) if @out_of_season.any? && params[:confirm].blank?

    jobs = AddCropJobs.new(current_member, @crop, planting:, planting_on:).call
    key = jobs.any? ? 'crop_jobs.added' : 'crop_jobs.already_added'
    redirect_to crop_path(@crop), notice: t(key, count: jobs.size, crop: @crop.name)
  end

  private

  def set_crop
    @crop = Crop.find(params[:crop_slug])
  end

  # The day the member plans to plant on, if they said and it is a date.
  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  # The planting chosen on the page, which has to be one of the member's of the crop or its varieties.
  def chosen_planting
    return if params[:planting_id].blank?

    AddCropJobs.new(current_member, @crop).plantings.find(params[:planting_id])
  end

  # The templates that are for the other half of the year, where the member is.
  def out_of_season(date)
    AddCropJobs.new(current_member, @crop).templates.reject { |template| template.in_season?(date, current_member.latitude) }
  end

  # Says the day is out of season, and offers to go ahead anyway.
  def render_warning(planting_on)
    @adder = AddCropJobs.new(current_member, @crop)
    @planting_on = planting_on || AddCropJobs.default_planting_on
    render :season_warning
  end
end
