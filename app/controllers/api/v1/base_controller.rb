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
      rescue_from(*BAD_REQUEST_ERRORS) { |error| render_error(:bad_request, error.message) }
      rescue_from(Graphiti::Errors::RecordNotFound) { |error| render_error(:not_found, error.message) }

      def index
        render jsonapi: resource_class.all(params)
      end

      def show
        render jsonapi: resource_class.find(params)
      end

      def create
        resource = resource_class.build(params)
        render_write resource, resource.save, status: :created
      end

      def update
        resource = resource_class.find(params)
        render_write resource, resource.update_attributes
      end

      def destroy
        resource = resource_class.find(params)
        resource.destroy ? head(:no_content) : render(jsonapi_errors: resource)
      end

      # Public so that resources, which Graphiti gives this controller as their context, can see who is writing.
      attr_reader :current_user

      private

      def resource_class
        @resource_class ||= "#{controller_name.singularize.camelize}Resource".constantize
      end

      def render_write(resource, saved, status: :ok)
        saved ? render(jsonapi: resource, status: status) : render(jsonapi_errors: resource)
      end

      def check_resource_type
        type = params.dig(:data, :type)
        render_error(:bad_request, "#{type} is not a valid resource.", title: 'Invalid resource') unless type == resource_class.type.to_s
      end

      def render_error(status, detail, title: nil)
        code = Rack::Utils.status_code(status)
        title ||= Rack::Utils::HTTP_STATUS_CODES[code]
        render json: { errors: [{ status: code.to_s, title: title, detail: detail }] }, status: status, content_type: Mime[:jsonapi]
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
