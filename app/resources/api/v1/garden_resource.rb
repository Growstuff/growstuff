# frozen_string_literal: true
class Api::V1::GardenResource < JSONAPI::Resource
  attributes :name, :slug, :description, :active, :area, :area_unit, :location, :longitude, :latitude
  has_one :owner
  has_many :plantings
end
