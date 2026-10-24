# frozen_string_literal: true

module Api
  module V1
    class CropsController < BaseController
      self.resource_class = CropResource

      def search
        proxy = CropResource.all(params.merge(stats: { total: :count }), Crop.search_by_name(params[:term]))
        total = proxy.stats[:total][:count]
        size = proxy.query.pagination[:size] || CropResource.default_page_size

        render jsonapi: proxy, meta: { record_count: total, page_count: (total / size.to_f).ceil }
      end
    end
  end
end
