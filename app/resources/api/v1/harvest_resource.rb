# frozen_string_literal: true

module Api
  module V1
    class HarvestResource < BaseResource
      immutable

      has_one :crop
      has_one :planting
      has_one :owner, class_name: 'Member'
      has_many :photos

      attribute :harvested_at
      attribute :description
      attribute :unit
      attribute :weight_quantity
      attribute :weight_unit
      attribute :si_weight
    end
  end
end
