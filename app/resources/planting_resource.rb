# frozen_string_literal: true

class PlantingResource < ApplicationResource
  self.model = Planting

  filter :photo_id, :integer do
    eq { |scope, ids| scope.joins(:photo_associations).where(photo_associations: { photo_id: ids }) }
  end

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
  attribute :expected_lifespan, :integer, writable: false
  attribute :finish_predicted_at, :date, writable: false
  attribute :first_harvest_date, :date, writable: false
  attribute :last_harvest_date, :date, writable: false

  attribute :longitude, :float, writable: false
  attribute :latitude, :float, writable: false
  attribute :location, :string, writable: false
  attribute :percentage_grown, :float, writable: false
  attribute :crop_name, :string, writable: false
  attribute :crop_slug, :string, writable: false
  attribute :thumbnail, :string, writable: false do
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
