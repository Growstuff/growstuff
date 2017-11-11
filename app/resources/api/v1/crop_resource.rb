module Api
  module V1
    class CropResource < BaseResource
      immutable

      filter :approval_status, default: 'approved'

      has_many :plantings
      has_many :photos
      has_many :harvests
      has_one :parent

      attribute :name
      attribute :en_wikipedia_url

      attribute :perennial
      attribute :median_lifespan
      attribute :median_days_to_first_harvest
      attribute :median_days_to_last_harvest
    end
  end
end
