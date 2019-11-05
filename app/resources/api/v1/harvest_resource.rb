module Api
  module V1
    class HarvestResource < BaseResource
      immutable

      has_one :crop
      has_one :planting
      has_one :owner, class_name: 'Member'
      has_many :photos

      attribute :harvested_at
      attributes :description, :slug
      attributes :unit, :weight_quantity
      attribute :weight_unit
      attribute :si_weight
      attributes :crop_name, :owner_login_name
      attribute :thumbnail
      def thumbnail
        @model.default_photo&.thumbnail_url
      end
      filter :interesting, apply: lambda { |records, value, _options|
        value ? records.interesting : records
      }
    end
  end
end
