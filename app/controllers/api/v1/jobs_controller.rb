# frozen_string_literal: true

module Api
  module V1
    class JobsController < BaseController
      self.resource_class = JobResource
    end
  end
end
