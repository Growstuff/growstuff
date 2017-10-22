module Api
  module V1
    class BaseController < JSONAPI::ResourceController
      abstract
    end
  end
end
