module Api
  module V1
    class HarvestResource < BaseResource
      immutable

      has_one :crop
      has_one :planting
      has_one :owner, class_name: 'Member'
      has_many :photos

      attributes :harvested_at
      attributes :description
      attributes :unit, :weight_quantity
      attributes :weight_unit
      attributes :si_weight
      attributes :crop_name, :owner_login_name
      attributes :thumbnail
      def thumbnail
        @model.default_photo&.thumbnail_url
      end
      filter :interesting, apply: lambda { |records, value, _options|
        value ? records.interesting : records
      }
    end
  end
end
