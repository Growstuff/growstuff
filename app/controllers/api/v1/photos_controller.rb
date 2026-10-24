# frozen_string_literal: true

module Api
  module V1
    class PhotosController < BaseController
      self.resource_class = PhotoResource
    end
  end
end
