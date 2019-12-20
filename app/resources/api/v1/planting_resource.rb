# frozen_string_literal: true

module Api
  module V1
    class PlantingResource < BaseResource
      immutable

      has_one :garden
      has_one :crop
      has_one :owner, class_name: 'Member'
      has_many :photos
      has_many :harvests

      attribute :slug
      attribute :planted_at
      attribute :finished
      attribute :finished_at
      attribute :quantity
      attribute :description
      attribute :sunniness
      attribute :planted_from

      # Predictions
      attribute :expected_lifespan
      attribute :finish_predicted_at
      attribute :first_harvest_date
      attribute :last_harvest_date

      attributes :longitude, :latitude, :location

      filter :slug
      filter :crop
      filter :planted_from
      filter :garden
      filter :owner
      filter :finished

      attribute :percentage_grown
      def percentage_grown
        @model.percentage_grown
      end

      attribute :crop_name
      attribute :crop_slug

      attribute :thumbnail
      def thumbnail
        @model.default_photo&.thumbnail_url
      end
    end
  end
end
