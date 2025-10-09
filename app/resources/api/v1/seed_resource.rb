# frozen_string_literal: true

module Api
  module V1
    class SeedResource < BaseResource
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :owner, class_name: 'Member', always_include_linkage_data: true
      has_one :crop, always_include_linkage_data: true

      attribute :description
      attribute :quantity
      attribute :plant_before
      attribute :tradable_to
      attribute :days_until_maturity_min
      attribute :days_until_maturity_max
      attribute :organic
      attribute :gmo
      attribute :heirloom

      filter :owner
      filter :owner_id
      filter :crop
      filter :crop_id
      filter :tradable_to
      filter :organic
      filter :gmo
      filter :heirloom
    end
  end
end
