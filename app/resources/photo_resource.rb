# frozen_string_literal: true

class PhotoResource < ApplicationResource
  self.model = Photo
  primary_endpoint '/photos', %i(index show update)

  attribute :thumbnail_url, :string, writable: false
  attribute :fullsize_url, :string, writable: false
  attribute :license_name, :string, writable: false
  attribute :link_url, :string, writable: false
  attribute :title, :string, writable: false

  # What reading a label photo found, written by the OCR script, which an admin runs. Writing it is not a member
  # editing their own photo, so it is not theirs to do.
  attribute :ocr_text, :string
  attribute :ocr_engine, :string
  attribute :ocr_at, :datetime
  before_save do |record|
    context.authorize!(:manage, record) if written?(record) && record.changed.intersect?(%w(ocr_text ocr_engine ocr_at))
  end
  # Whether it is of the front or back of a seed packet, if it is.
  computed_attribute :label, :string do
    @object.photo_associations.of_packets.pick(:label)
  end

  filter :crop_id, :integer do
    eq { |scope, ids| scope.where(id: PhotoAssociation.where(crop_id: ids).select(:photo_id)) }
  end

  # Photos of a label that have no text yet: what the OCR script reads.
  filter :needs_ocr, :boolean do
    eq { |scope, value| value ? scope.awaiting_ocr : scope }
  end

  owned
  %w(Planting Garden Harvest Seed).each { |type| photographed type }
end
