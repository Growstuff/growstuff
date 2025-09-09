# frozen_string_literal: true

module Api
  module V1
    class BaseController < JSONAPI::ResourceController
      abstract
      protect_from_forgery with: :null_session
      before_action :authenticate_member_from_token!
      rescue_from CanCan::AccessDenied do
        # TODO: Is it worth audit logging?
        head :forbidden
      end

      def context
        {
          current_user: current_user,
          current_ability: current_ability,
          controller: self,
          action: params[:action]
        }
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
          else
            raise UnauthorisedError.new(code: 401, title: "Unauthorized")
          end
        end
      end
    end
  end
end

class UnauthorisedError < JSONAPI::Error
end
