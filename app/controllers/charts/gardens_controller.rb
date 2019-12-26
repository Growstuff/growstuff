# frozen_string_literal: true

module Charts
  class GardensController < ApplicationController
    respond_to :json
    def timeline
      @data = []
      @garden = Garden.find(params[:garden_slug])
      @garden.plantings.where.not(planted_at: nil)
        .order(finished_at: :desc).each do |p|
        # use finished_at if we have it, otherwise use predictions
        finish = p.finished_at.presence || p.finish_predicted_at || Time.zone.today.to_date
        @data << [p.crop.name, p.planted_at, finish] if finish.present?
      end
      render json: @data
    end
  end
end
