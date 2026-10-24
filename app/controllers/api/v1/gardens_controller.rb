# frozen_string_literal: true

module Api
  module V1
    class GardensController < BaseController
      self.resource_class = GardenResource
    end
  end
end
