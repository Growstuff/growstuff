# frozen_string_literal: true

class GardenResource < ApplicationResource
  self.model = Garden

  filter :photo_id, :integer do
    eq { |scope, ids| scope.joins(:photo_associations).where(photo_associations: { photo_id: ids }) }
  end

  attribute :name, :string
  filter_only :slug, :string
  filter_only :active, :boolean
  filter_only :location, :string
  filter_only :owner_id, :integer
  filter_only :garden_type_id, :integer

  belongs_to :owner, resource: MemberResource
  has_many :plantings
  photos_of 'Garden'
end
