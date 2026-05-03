# frozen_string_literal: true

module Api
  module V1
    class GardenResource < BaseResource
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :owner, class_name: 'Member', always_include_linkage_data: true
      has_many :plantings
      has_many :photos

      attribute :name

      filter :owner
      filter :owner_id
      filter :active
      filter :garden_type
      filter :location
      filter :slug
    end
  end
end
