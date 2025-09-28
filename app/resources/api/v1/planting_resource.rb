# frozen_string_literal: true

module Api
  module V1
    class PlantingResource < BaseResource
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :garden, always_include_linkage_data: true
      has_one :crop
      has_one :owner, class_name: 'Member'
      has_many :photos
      has_many :harvests

      attribute :slug
      attribute :planted_at
      attribute :failed
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
      filter :owner_id
      filter :finished
      filter :active, apply: ->(records, _value, _options) { records.active }
      filter :failed, apply: ->(records, _value, _options) { records.failed }
      filter :sunniness
      filter :perennial, apply: ->(records, _value, _options) { records.perennial }

      attribute :percentage_grown
      delegate :percentage_grown, to: :@model

      attribute :crop_name
      attribute :crop_slug

      attribute :thumbnail
      def thumbnail
        @model.default_photo&.thumbnail_url
      end
    end
  end
end
