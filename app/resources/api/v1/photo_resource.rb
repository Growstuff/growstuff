module Api
  module V1
    class PhotoResource < JSONAPI::Resource
      immutable
      model_name 'Photo'
    end
  end
end
