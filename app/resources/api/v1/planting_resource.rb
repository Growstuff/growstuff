module Api
  module V1
    class PlantingResource < BaseResource
      immutable

      has_one :garden
      has_one :crop
      has_one :owner, class_name: 'Member'
      has_many :photos
      has_many :harvests

      attribute :planted_at
      attribute :finished_at
      attribute :finished
      attribute :quantity
      attribute :description
      attribute :sunniness
      attribute :planted_from

      # Predictions
      attribute :expected_lifespan
      attribute :finish_predicted_at
      attribute :percentage_grown
      attribute :first_harvest_date
      attribute :last_harvest_date
    end
  end
end
