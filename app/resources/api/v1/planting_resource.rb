module Api
  module V1
    class PlantingResource < JSONAPI::Resource
      immutable
      model_name 'Planting'
      has_one :garden
      has_one :crop
      has_one :owner
      has_many :photos

      attribute :planted_at
      attribute :finished_at
      attribute :quantity
      attribute :description
      attribute :sunniness
      attribute :planted_from
      attribute :days_before_maturity
    end
  end
end
