# frozen_string_literal: true

module Api
  module V1
    class MemberResource < BaseResource
      immutable

      has_many :gardens
      has_many :plantings
      has_many :harvests
      has_many :seeds

      has_many :photos

      attribute :login_name
      attribute :slug

      filters :login_name, :slug
    end
  end
end
