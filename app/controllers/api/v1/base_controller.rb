# frozen_string_literal: true

module Api
  module V1
    class BaseController < JSONAPI::ResourceController
      abstract
      protect_from_forgery with: :null_session
      before_action :authenticate_member_from_token!
      before_action :enforce_member_for_write_operations!, only: %i(create update destroy)
      rescue_from CanCan::AccessDenied do
        head :forbidden
      end

      def context
        {
          current_user:    current_user,
          current_ability: current_ability,
          controller:      self,
          action:          params[:action]
        }
      end

      private

      attr_reader :current_user

      def enforce_member_for_write_operations!
        head :unauthorized unless current_user
      end

      def authenticate_member_from_token!
        authenticate_with_http_token do |token, _options|
          auth = Authentication.find_by(token: token, provider: 'api')
          if auth.present?
            @current_user = auth.member

            return true
          end
        end
      end
    end
  end
end
