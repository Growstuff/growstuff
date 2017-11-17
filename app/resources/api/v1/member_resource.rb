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
    end
  end
end
