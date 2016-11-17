# frozen_string_literal: true
class Api::V1::SeedResource < JSONAPI::Resource
  attributes :description, :quantity, :plant_before, :days_until_maturity_min, :days_until_maturity_max, :organic, :gmo, :heirloom
  has_one :owner
  has_one :crop
end
