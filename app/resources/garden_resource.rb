# frozen_string_literal: true

class GardenResource < ApplicationResource
  self.model = Garden

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
