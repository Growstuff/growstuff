# frozen_string_literal: true

# "Add to planned jobs" on a crop suggested for a season: makes a job to plant the crop in that season, linked to it, due when
# the season starts (see SuggestedPlantJob). It is not made twice while the member has it and it isn't done. The page sends it
# without leaving and is answered with the job's name; without JavaScript it goes back to the suggestions with the season open.
class SuggestedJobsController < ApplicationController
  skip_authorize_resource
  before_action :authenticate_member!

  def create
    crop = Crop.approved.find(params.require(:crop_id))
    job = SuggestedPlantJob.new(current_member, SeasonalClimate.for(current_member)).add(crop, params[:season])
    respond_to do |format|
      format.json { render json: { added: job.present?, name: job&.name }, status: job ? :created : :ok }
      format.html do
        notice = job ? t('.added', name: job.name) : t('.already_planned', crop: crop.name)
        redirect_to suggestions_path(season: params[:season].presence), notice:
      end
    end
  end
end
