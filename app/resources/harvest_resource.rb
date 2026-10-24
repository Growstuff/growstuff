# frozen_string_literal: true

class HarvestResource < ApplicationResource
  self.model = Harvest

  attribute :harvested_at, :date
  attribute :description, :string
  attribute :unit, :string
  attribute :weight_quantity, :big_decimal
  attribute :weight_unit, :string
  attribute :si_weight, :float, writable: false

  attribute :crop_id, :integer, readable: false
  attribute :planting_id, :integer, readable: false
  filter_only :plant_part_id, :integer

  belongs_to :crop
  belongs_to :planting
  owned
  photos_of 'Harvest'

  before_save do |harvest|
    harvest.crop_id = harvest.planting.crop_id if harvest.planting_id
    harvest.harvested_at = Time.zone.now if harvest.harvested_at.blank?
    harvest.plant_part ||= PlantPart.first
  end
end
