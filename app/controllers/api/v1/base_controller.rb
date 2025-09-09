# frozen_string_literal: true

module Api
  module V1
    class BaseController < JSONAPI::ResourceController
      abstract
      protect_from_forgery with: :null_session
      before_action :authenticate_member_from_token!

      def context
        { current_user: current_user, current_ability: current_ability }
      end

      private

      def current_user
        @current_user
      end

      def authenticate_member_from_token!
        authenticate_with_http_token do |token, _options|
          auth = Authentication.find_by(token: token, provider: 'api')
          if auth.present?
            @current_user = auth.member
          end
        end
      end
    end
  end
end
