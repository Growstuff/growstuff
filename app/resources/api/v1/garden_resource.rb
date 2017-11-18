module Api
  module V1
    class GardenResource < BaseResource
      immutable

      has_one :owner, class_name: 'Member'
      has_many :plantings
      has_many :photos

      attribute :name
    end
  end
end
