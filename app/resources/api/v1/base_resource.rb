module Api
  module V1
    class BaseResource < JSONAPI::Resource
      immutable
      abstract
    end
  end
end
