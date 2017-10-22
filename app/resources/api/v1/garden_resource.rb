module Api
  module V1
    class GardenResource < JSONAPI::Resource
      immutable
      model_name 'Garden'
      attribute :name
      has_one :owner, class_name: 'Member'
      has_many :plantings
    end
  end
end
