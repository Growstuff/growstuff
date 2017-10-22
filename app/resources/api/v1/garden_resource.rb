module Api
  module V1
    class GardenResource < JSONAPI::Resource
      immutable

      has_one :owner, class_name: 'Member'
      has_many :plantings
      has_many :photos

      attribute :name
    end
  end
end
