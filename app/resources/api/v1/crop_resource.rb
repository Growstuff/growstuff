module Api
  module V1
    class CropResource < JSONAPI::Resource
      immutable
      model_name 'Crop'
      attribute :name
      attribute :en_wikipedia_url
      has_many :plantings
      has_many :photos
      has_one :parent
    end
  end
end
