# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      include DashedKeys

      before_action :authenticate_member_from_token!
      before_action :enforce_member_for_write_operations!, only: %i(create update destroy)
      before_action :check_resource_type, :reject_nested_writes, only: %i(create update)
      rescue_from CanCan::AccessDenied do
        head :forbidden
      end

      # What Graphiti raises for requests it cannot make sense of, which are the client's to fix.
      BAD_REQUEST_ERRORS = [
        Graphiti::Errors::UnsupportedPageSize, Graphiti::Errors::UnsupportedPagination,
        Graphiti::Errors::UnsupportedSort, Graphiti::Errors::UnsupportedOperator,
        Graphiti::Errors::InvalidFilterValue, Graphiti::Errors::InvalidInclude,
        Graphiti::Errors::UnknownAttribute, Graphiti::Errors::InvalidAttributeAccess,
        Graphiti::Errors::InvalidRequest, Graphiti::Errors::StatNotFound
      ].freeze
      rescue_from(*BAD_REQUEST_ERRORS) { |error| render_error(:bad_request, error.message) }
      rescue_from(Graphiti::Errors::RecordNotFound, ActiveRecord::RecordNotFound) { |error| render_error(:not_found, error.message) }

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
        # The record as it is; the resource then checks what the changes would make of it.
        authorize! :update, resource.data
        render_write resource, resource.update_attributes
      end

      def destroy
        resource = resource_class.find(params)
        resource.destroy ? head(:no_content) : render(jsonapi_errors: resource)
      end

      # Public, as Graphiti gives resources this controller as their context, so that they can see who is writing what.
      attr_reader :current_user

      def resource_class
        @resource_class ||= "#{controller_name.singularize.camelize}Resource".constantize
      end

      private

      # Graphiti lets a request create, change or delete related records alongside the one it is about. Only the one
      # the request is about has been authorised, so related records can be linked to, by id, and nothing more.
      def reject_nested_writes
        links = (params.dig(:data, :relationships)&.values || []).flat_map { |relationship| [relationship[:data]].flatten.compact }
        return unless params[:included].present? || links.any? { |link| link[:method].present? || link[:'temp-id'].present? }

        render_error(:bad_request, 'Related records can be linked to by id, but not created, changed or deleted in the same request.',
                     title: 'Invalid request')
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
          @current_user = Authentication.find_by(token: token, provider: 'api')&.member
        end
      end
    end
  end
end
