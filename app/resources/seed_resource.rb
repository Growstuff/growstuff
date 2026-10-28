# frozen_string_literal: true

class SeedResource < ApplicationResource
  self.model = Seed

  attribute :description, :string
  attribute :quantity, :integer
  attribute :plant_before, :date
  attribute :tradable_to, :string
  attribute :days_until_maturity_min, :integer
  attribute :days_until_maturity_max, :integer
  attribute :organic, :string
  attribute :gmo, :string
  attribute :heirloom, :string

  attribute :crop_id, :integer, readable: false

  belongs_to :crop
  owned
end
