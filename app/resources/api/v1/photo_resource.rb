# frozen_string_literal: true

module Api
  module V1
    class PhotoResource < BaseResource
      immutable # TODO: Re-evaluate this.
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :owner, class_name: 'Member', always_include_linkage_data: true
      has_many :plantings
      has_many :gardens
      has_many :harvests
      has_many :seeds

      attribute :thumbnail_url
      attribute :fullsize_url
      attribute :license_name
      attribute :link_url
      attribute :title

      # By what part of the item the photo is of, such as the front or back of a
      # seed packet: `filter[label]=back`.
      filter :label, apply: lambda { |records, values, _options|
        records.joins(:photo_associations).where(photo_associations: { label: values })
      }
    end
  end
end
