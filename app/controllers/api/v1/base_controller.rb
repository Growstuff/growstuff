# frozen_string_literal: true

module Api
  module V1
    class BaseController < JSONAPI::ResourceController
      abstract
      protect_from_forgery with: :null_session
      before_action :authenticate_member_from_token!

      def context
        { current_user: current_member, current_ability: current_ability }
      end

      private

      def authenticate_member_from_token!
        authenticate_with_http_token do |token, _options|
          auth = Authentication.find_by(token: token, provider: 'api')
          if auth.present?
            sign_in(:member, auth.member, store: false)
          end
        end
      end
    end
  end
end
