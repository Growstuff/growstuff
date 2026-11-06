# frozen_string_literal: true

module Api
  # Checks that a request is shaped as the API expects before anything works with it: the query of every request,
  # and the body of a write. Whatever does not fit is a 400, not an error somewhere further in.
  #
  # Needs `resource_class` and `render_error` from the controller it is in.
  module RequestShape
    extend ActiveSupport::Concern

    # What goes in the query, by what shape it has: `page[number]=2` is an object, `sort=name` is text.
    QUERY_OBJECTS = %i(page filter fields extra_fields stats).freeze
    QUERY_TEXT = %i(sort include).freeze
    # The least each page number or size can be.
    PAGE_MINIMUMS = { number: 1, size: 1, limit: 1, offset: 0 }.freeze

    included do
      before_action :check_query_shape
    end

    private

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
  end
end
