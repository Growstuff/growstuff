# frozen_string_literal: true

class PhotoResource < ApplicationResource
  self.model = Photo
  read_only

  attribute :thumbnail_url, :string
  attribute :fullsize_url, :string
  attribute :license_name, :string
  attribute :link_url, :string
  attribute :title, :string
  # Whether it is of the front or back of a seed packet, if it is.
  computed_attribute :label, :string do
    @object.photo_associations.of_packets.pick(:label)
  end

  filter :crop_id, :integer do
    eq { |scope, ids| scope.where(id: PhotoAssociation.where(crop_id: ids).select(:photo_id)) }
  end

  # Photos of a seed packet whose seed has no text from it yet: what the OCR script reads.
  filter :needs_ocr, :boolean do
    eq { |scope, value| value ? scope.where(id: PhotoAssociation.awaiting_text.select(:photo_id)) : scope }
  end

  owned
  %w(Planting Garden Harvest Seed).each { |type| photographed type }
end
