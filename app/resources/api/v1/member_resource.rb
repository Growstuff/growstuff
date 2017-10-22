module Api
  module V1
    class MemberResource < JSONAPI::Resource
      immutable
      model_name 'Member'
      attribute :login_name
      has_many :gardens
    end
  end
end
