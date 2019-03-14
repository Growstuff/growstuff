# frozen_string_literal: true

module Charts
  class CropsController < ApplicationController
    respond_to :json

    def sunniness
      pie_chart_query 'sunniness'
    end

    def planted_from
      pie_chart_query 'planted_from'
    end

    def harvested_for
      @crop = Crop.find_by!(slug: params[:crop_slug])
      render json: Harvest.joins(:plant_part)
        .where(crop: @crop)
        .group("plant_parts.name").count(:id)
    end

    private

    def pie_chart_query(field)
      @crop = Crop.find_by!(slug: params[:crop_slug])
      render json: Planting.where(crop: @crop)
        .where.not(field.to_sym => nil)
        .where.not(field.to_sym => '')
        .group(field.to_sym).count(:id)
    end
  end
end
