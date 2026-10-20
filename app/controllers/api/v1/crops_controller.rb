# frozen_string_literal: true

module Api
  module V1
    class CropsController < BaseController
      def search
        term = params[:term]
        page = params.dig(:page, :number) || 1
        per_page = params.dig(:page, :size) || Crop.per_page

        search_results = CropSearchService.search(
          term,
          page:     page,
          per_page: per_page,
          load:     true
        )

        resources = search_results.map do |crop|
          Api::V1::CropResource.new(crop, context)
        end

        serializer = JSONAPI::ResourceSerializer.new(Api::V1::CropResource)

        data = resources.map do |resource|
          serializer.object_hash(resource, {})
        end

        render json: {
          data: data,
          meta: {
            record_count: search_results.total_count,
            page_count:   search_results.total_pages
          }
        }
      end
    end
  end
end
