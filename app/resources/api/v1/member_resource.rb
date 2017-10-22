module Api
  module V1
    class MemberResource < JSONAPI::Resource
      immutable

      has_many :gardens

      attribute :login_name
    end
  end
end
