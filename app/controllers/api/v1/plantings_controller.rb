# frozen_string_literal: true

module Api
  module V1
    class PlantingsController < BaseController
      self.resource_class = PlantingResource
    end
  end
end
