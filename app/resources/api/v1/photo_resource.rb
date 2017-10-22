module Api
  module V1
    class PhotoResource < JSONAPI::Resource
      immutable

      has_one :owner, class_name: 'Member'

      attribute :thumbnail_url
      attribute :fullsize_url
      attribute :link_url
      attribute :license_name
      attribute :link_url
      attribute :title
    end
  end
end
