# frozen_string_literal: true

# What a grower has noticed about a planting. The dialogs on the planting page and the garden cards post here, and
# the planting page's timeline deletes from here.
module Plantings
  class ObservationsController < ApplicationController
    before_action :authenticate_member!
    before_action :load_planting

    def create
      observation = @planting.observations.build(observation_params.merge(author: current_member))
      observation.observed_at ||= Time.zone.now

      if observation.save
        render json: { observation: { id: observation.id }, garden: garden_card }, status: :created
      else
        render json: { errors: observation.errors.to_hash }, status: :unprocessable_content
      end
    end

    def destroy
      @planting.observations.find(params[:id]).destroy
      redirect_to planting_path(@planting, anchor: 'observations'), notice: t('.deleted')
    end

    private

    def load_planting
      @planting = Planting.find_by!(slug: params[:planting_slug])
      authorize! :update, @planting
    end

    def observation_params
      params.expect(observation: %i(kind observed_at description))
    end

    # The garden's refreshed card, so the list shows the change without a reload.
    def garden_card
      GardenCardSerializer.collection([@planting.garden], ability: current_ability, show_owner: false).first
    end
  end
end
