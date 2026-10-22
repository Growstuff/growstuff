# frozen_string_literal: true

module Api
  module V1
    class JobResource < BaseResource
      before_create do
        @model.owner = context[:current_user]
      end

      has_one :owner, class_name: 'Member', always_include_linkage_data: true
      has_one :garden, always_include_linkage_data: true

      attribute :name
      attribute :description
      attribute :finished
      attribute :due_date
      attribute :jobbable_type
      attribute :jobbable_id

      filter :owner
      filter :owner_id
      filter :garden
      filter :garden_id
      filter :jobbable_type
      filter :jobbable_id
    end
  end
end
