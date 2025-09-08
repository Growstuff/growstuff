# frozen_string_literal: true

module Api
  module V1
    class ActivityResource < BaseResource
      immutable

      has_one :owner, class_name: 'Member'
      has_one :garden
      has_one :planting

      attribute :name
      attribute :description
      attribute :category
      attribute :finished
      attribute :due_date

      filters :owner, :garden, :planting, :category
    end
  end
end
