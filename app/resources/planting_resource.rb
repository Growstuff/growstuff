# frozen_string_literal: true

class PlantingResource < ApplicationResource
  self.model = Planting

  attribute :slug, :string, writable: false
  attribute :planted_at, :date
  attribute :failed, :boolean
  attribute :finished, :boolean
  attribute :finished_at, :date
  attribute :quantity, :integer
  attribute :description, :string
  attribute :sunniness, :string
  attribute :planted_from, :string

  # Predictions
  computed_attribute :expected_lifespan, :integer
  computed_attribute :finish_predicted_at, :date
  computed_attribute :first_harvest_date, :date
  computed_attribute :last_harvest_date, :date

  computed_attribute :longitude, :float
  computed_attribute :latitude, :float
  computed_attribute :location, :string
  computed_attribute :percentage_grown, :float
  computed_attribute :crop_name, :string
  computed_attribute :crop_slug, :string
  computed_attribute :thumbnail, :string do
    @object.default_photo&.thumbnail_url
  end

  attribute :crop_id, :integer, readable: false
  attribute :garden_id, :integer, readable: false
  filter_only :owner_id, :integer

  filter :active, :boolean do
    eq { |scope, value| value ? scope.active : scope }
  end
  filter :perennial, :boolean do
    eq { |scope, value| value ? scope.perennial : scope }
  end

  belongs_to :garden
  belongs_to :crop
  belongs_to :owner, resource: MemberResource
  has_many :harvests
  photos_of 'Planting'
end
