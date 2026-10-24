# frozen_string_literal: true

class PhotoResource < ApplicationResource
  self.model = Photo
  primary_endpoint '/photos', %i(index show)

  attribute :thumbnail_url, :string, writable: false
  attribute :fullsize_url, :string, writable: false
  attribute :license_name, :string, writable: false
  attribute :link_url, :string, writable: false
  attribute :title, :string, writable: false
  filter_only :owner_id, :integer

  filter :crop_id, :integer do
    eq { |scope, ids| scope.joins(:photo_associations).where(photo_associations: { crop_id: ids }) }
  end

  belongs_to :owner, resource: MemberResource
  %w(Planting Garden Harvest).each { |type| photographed type }
end
