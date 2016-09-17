class Api::V1::GardenResource < JSONAPI::Resource
  attributes :name, :slug, :description, :active, :area, :area_unit
  has_one :owner
end
