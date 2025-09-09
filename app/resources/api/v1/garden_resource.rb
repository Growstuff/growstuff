# frozen_string_literal: true

module Api
  module V1
    class GardenResource < BaseResource
      has_one :owner, class_name: 'Member'
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
