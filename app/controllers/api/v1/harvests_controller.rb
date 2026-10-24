# frozen_string_literal: true

module Api
  module V1
    class HarvestsController < BaseController
      self.resource_class = HarvestResource
    end
  end
end
