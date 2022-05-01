# frozen_string_literal: true

module Api
  module V1
    class MemberResource < BaseResource
      immutable

      has_many :gardens, foreign_key: 'owner_id'
      has_many :plantings, foreign_key: 'owner_id'
      has_many :harvests, foreign_key: 'owner_id'
      has_many :seeds, foreign_key: 'owner_id'

      has_many :photos

      attribute :login_name
      attribute :slug

      filters :login_name, :slug
    end
  end
end
