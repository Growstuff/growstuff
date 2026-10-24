# frozen_string_literal: true

class PhotoResource < ApplicationResource
  self.model = Photo
  read_only

  attribute :thumbnail_url, :string
  attribute :fullsize_url, :string
  attribute :license_name, :string
  attribute :link_url, :string
  attribute :title, :string

  filter :crop_id, :integer do
    eq { |scope, ids| scope.where(id: PhotoAssociation.where(crop_id: ids).select(:photo_id)) }
  end

  owned
  %w(Planting Garden Harvest).each { |type| photographed type }
end
