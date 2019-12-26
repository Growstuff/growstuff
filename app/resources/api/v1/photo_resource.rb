# frozen_string_literal: true

module Api
  module V1
    class PhotoResource < BaseResource
      immutable

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
