# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      include DashedKeys

      before_action :authenticate_member_from_token!
      before_action :enforce_member_for_write_operations!, only: %i(create update destroy)
      before_action :check_resource_type, only: %i(create update)
      rescue_from CanCan::AccessDenied do
        head :forbidden
      end

      # What Graphiti raises for requests it cannot make sense of, which are the client's to fix.
      BAD_REQUEST_ERRORS = [
        Graphiti::Errors::UnsupportedPageSize, Graphiti::Errors::UnsupportedPagination,
        Graphiti::Errors::UnsupportedSort, Graphiti::Errors::UnsupportedOperator,
        Graphiti::Errors::InvalidFilterValue, Graphiti::Errors::InvalidInclude,
        Graphiti::Errors::UnknownAttribute, Graphiti::Errors::StatNotFound
      ].freeze
      rescue_from(*BAD_REQUEST_ERRORS) { |error| render_error(error, :bad_request) }
      rescue_from(Graphiti::Errors::RecordNotFound) { |error| render_error(error, :not_found) }

      class_attribute :resource_class

      def index
        render jsonapi: resource_class.all(params)
      end

      def show
        render jsonapi: resource_class.find(params)
      end

      def create
        resource = resource_class.build(params)
        if resource.save
          render jsonapi: resource, status: :created
        else
          render jsonapi_errors: resource
        end
      end

      def update
        resource = resource_class.find(params)
        if resource.update_attributes
          render jsonapi: resource
        else
          render jsonapi_errors: resource
        end
      end

      def destroy
        resource = resource_class.find(params)
        authorize! :destroy, resource.data
        if resource.destroy
          head :no_content
        else
          render jsonapi_errors: resource
        end
      end

      attr_reader :current_user

      private

      def check_resource_type
        return if params.dig(:data, :type) == resource_class.type.to_s

        type = params.dig(:data, :type)
        render json: { errors: [{ status: '400', title: 'Invalid resource', detail: "#{type} is not a valid resource." }] },
               status: :bad_request, content_type: Mime[:jsonapi]
      end

      def render_error(error, status)
        code = Rack::Utils.status_code(status)
        render json: { errors: [{ status: code.to_s, title: Rack::Utils::HTTP_STATUS_CODES[code], detail: error.message }] },
               status: status, content_type: Mime[:jsonapi]
      end

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
