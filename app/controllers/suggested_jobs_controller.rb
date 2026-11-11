# frozen_string_literal: true

# "Add to planned jobs" on a crop suggested for a season: makes a job to plant the crop in that season, linked to it, under
# Some day, so the member picks the day (see SuggestedPlantJob). It is not made twice while the member has it and it isn't done.
# Goes back to the suggestions with the season it was added from open.
class SuggestedJobsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def create
    crop = Crop.approved.find(params.require(:crop_id))
    job = SuggestedPlantJob.new(current_member, SeasonalClimate.for(current_member)).add(crop, params[:season])
    notice = job ? t('.added', name: job.name) : t('.already_planned', crop: crop.name)
    redirect_to suggestions_path(season: params[:season].presence), notice:
  end
end
