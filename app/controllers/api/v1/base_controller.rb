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
        return head :unauthorized unless current_user
        return unless @oauth_scopes && !@oauth_scopes.exists?(:write)

        response.set_header('WWW-Authenticate', 'Bearer error="insufficient_scope", scope="write"')
        head :forbidden
      end

      # A member's own API token, or an OAuth token from an app they signed in to.
      def authenticate_member_from_token!
        @current_user = member_from_api_token || member_from_oauth_token
      end

      def member_from_api_token
        authenticate_with_http_token do |token, _options|
          Authentication.find_by(token:, provider: 'api')&.member
        end
      end

      # The member an OAuth token is for, if it is still good. What the token may do
      # is its scope: `read` to read, and `write` to change anything.
      def member_from_oauth_token
        token = Doorkeeper.authenticate(request)
        return unless token&.accessible?

        member = Member.kept.find_by(id: token.resource_owner_id)
        return unless member&.active_for_authentication?

        @oauth_scopes = token.scopes
        member
      end
    end
  end
end
