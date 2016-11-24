class Api::V1::PlantingResource < JSONAPI::Resource
  attributes :quantity, :description, :planted_at, :sunniness, :planted_from, :finished, :finished_at, :days_before_maturity
  has_one :garden
  has_one :crop
end
