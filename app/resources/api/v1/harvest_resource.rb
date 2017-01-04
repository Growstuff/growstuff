# frozen_string_literal: true
class Api::V1::HarvestResource < JSONAPI::Resource
  attributes :harvested_at, :quantity, :weight_quantity, :weight_unit, :si_weight
  has_one :crop
  has_one :owner
  # has_one :plant_part
end
