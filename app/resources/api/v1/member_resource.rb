module Api
  module V1
    class MemberResource < BaseResource
      has_many :gardens

      attribute :login_name
    end
  end
end
