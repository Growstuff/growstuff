# frozen_string_literal: true

module Api
  module V1
    class PhotoResource < BaseResource
      immutable # TODO: Re-evaluate this.
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :owner, class_name: 'Member'
      has_many :plantings
      has_many :gardens
      has_many :harvests

      attribute :thumbnail_url
      attribute :fullsize_url
      attribute :license_name
      attribute :link_url
      attribute :title
    end
  end
end
