# frozen_string_literal: true

module Api
  module V1
    class SeedResource < BaseResource
      immutable

      has_one :owner, class_name: 'Member'
      has_one :crop

      attribute :description
      attribute :quantity
      attribute :plant_before
      attribute :tradable_to
      attribute :days_until_maturity_min
      attribute :days_until_maturity_max
      attribute :organic
      attribute :gmo
      attribute :heirloom
    end
  end
end
