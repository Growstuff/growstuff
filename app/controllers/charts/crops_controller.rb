# frozen_string_literal: true

module Charts
  class CropsController < ApplicationController
    respond_to :json
    before_action :set_crop

    def sunniness
      pie_chart_query 'sunniness'
    end

    def planted_from
      pie_chart_query 'planted_from'
    end

    def harvested_for
      data = Rails.cache.fetch("#{@crop.cache_key_with_version}/harvested_for", expires_in: 1.day) do
        Harvest.joins(:plant_part)
          .where(crop: @crop)
          .group("plant_parts.name").count(:id)
      end
      render json: data
    end

    private

    def set_crop
      @crop = Crop.find_by!(slug: params[:crop_slug])
    end

    def pie_chart_query(field)
      data = Rails.cache.fetch("#{@crop.cache_key_with_version}/#{field}", expires_in: 1.day) do
        Planting.where(crop: @crop)
          .where.not(field.to_sym => nil)
          .where.not(field.to_sym => '')
          .group(field.to_sym).count(:id)
      end
      render json: data
    end
  end
end
