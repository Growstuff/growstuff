# frozen_string_literal: true

module Api
  module V1
    class ActivityResource < BaseResource
      has_one :owner, class_name: 'Member'
      has_one :garden
      has_one :planting

      attribute :name
      attribute :description
      attribute :category
      attribute :finished
      attribute :due_date

      filter :owner
      filter :owner_id
      filter :garden
      filter :garden_id
      filter :planting
      filter :planting_id
      filter :category
    end
  end
end
