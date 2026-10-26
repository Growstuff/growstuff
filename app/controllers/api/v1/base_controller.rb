# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      # First, so that nothing below meets a query that is not shaped as it expects.
      before_action :check_query_shape
      include DashedKeys

      before_action :authenticate_member_from_token!
      before_action :enforce_member_for_write_operations!, only: %i(create update destroy)
      before_action :check_request_body, only: %i(create update)
      rescue_from CanCan::AccessDenied do
        head :forbidden
      end

      # What Graphiti raises for requests it cannot make sense of, which are the client's to fix.
      BAD_REQUEST_ERRORS = [
        Graphiti::Errors::UnsupportedPageSize, Graphiti::Errors::UnsupportedPagination,
        Graphiti::Errors::UnsupportedSort, Graphiti::Errors::UnsupportedOperator,
        Graphiti::Errors::InvalidFilterValue, Graphiti::Errors::InvalidInclude,
        Graphiti::Errors::UnknownAttribute, Graphiti::Errors::InvalidAttributeAccess,
        Graphiti::Errors::InvalidRequest, Graphiti::Errors::StatNotFound,
        Graphiti::Errors::TypecastFailed
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

      # What goes in the query, by what shape it has: `page[number]=2` is an object, `sort=name` is text.
      QUERY_OBJECTS = %i(page filter fields extra_fields stats).freeze
      QUERY_TEXT = %i(sort include).freeze
      # The least each page number or size can be.
      PAGE_MINIMUMS = { number: 1, size: 1, limit: 1, offset: 0 }.freeze
      private_constant :QUERY_OBJECTS, :QUERY_TEXT, :PAGE_MINIMUMS

      def check_query_shape
        problem = query_problem
        render_error(:bad_request, problem, title: 'Invalid query') if problem
      end

      def query_problem
        QUERY_OBJECTS.each do |name|
          return "#{name} must be given as #{name}[name]=value." unless params[name].nil? || params[name].respond_to?(:key?)
        end
        QUERY_TEXT.each { |name| return "#{name} must be text." unless params[name].nil? || params[name].is_a?(String) }
        page_problem(params[:page]) if params[:page]
      end

      def page_problem(page)
        PAGE_MINIMUMS.each do |name, minimum|
          value = page[name]
          next if value.nil? || (value.is_a?(String) && value.match?(/\A\d+\z/) && value.to_i >= minimum)

          return "page[#{name}] must be a whole number, #{minimum} or more."
        end
        nil
      end

      def check_request_body
        problem = request_body_problem
        render_error(:bad_request, problem, title: 'Invalid request') if problem
      end

      def request_body_problem
        data = params[:data]
        return 'The request needs a data object.' unless data.respond_to?(:key?)
        return "#{data[:type]} is not a valid resource." unless data[:type] == resource_class.type.to_s
        return 'Attributes must be an object.' unless data[:attributes].nil? || data[:attributes].respond_to?(:key?)

        'Related records can only be linked to by id, one at a time.' unless params[:included].blank? && links_only?(data[:relationships])
      end

      # Graphiti lets a request create, change or delete related records alongside the one it is about, and set the
      # foreign keys of a list of them. Only the record the request is about is authorised, so a relationship may
      # only point this record at one other, by id.
      def links_only?(relationships)
        relationships.nil? ||
          (relationships.respond_to?(:each_pair) && relationships.each_pair.all? { |name, link| to_one_link?(name, link) })
      end

      def to_one_link?(name, relationship)
        return false unless relationship.respond_to?(:key?) && resource_class.sideloads[name.to_sym]&.type == :belongs_to

        link = relationship[:data]
        link.nil? || (link.respond_to?(:keys) && (link.keys - %w(type id)).empty?)
      end

      def render_write(resource, saved, status: :ok)
        saved ? render(jsonapi: resource, status: status) : render(jsonapi_errors: resource)
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
