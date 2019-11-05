module Api
  module V1
    class BaseResource < JSONAPI::Resource
      immutable
      abstract
      attribute :slug
    end
  end
end
