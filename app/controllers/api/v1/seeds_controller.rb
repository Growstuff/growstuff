# frozen_string_literal: true

module Api
  module V1
    class SeedsController < BaseController
      self.resource_class = SeedResource
    end
  end
end
