# frozen_string_literal: true

module Api
  module V1
    class HarvestResource < BaseResource
      before_create do
        @model.owner = context[:current_user]
        @model.crop_id = @model.planting.crop_id if @model.planting_id
        @model.harvested_at = Time.zone.now if @model.harvested_at.blank?
      end

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

      filter :owner
      filter :owner_id
      filter :crop
      filter :crop_id
      filter :planting
      filter :planting_id
      filter :plant_part
      filter :harvested_at
    end
  end
end
