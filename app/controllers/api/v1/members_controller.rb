# frozen_string_literal: true

module Api
  module V1
    class MembersController < BaseController
      self.resource_class = MemberResource
    end
  end
end
